import logging
from typing import Dict, Any, List, Optional
from app.services.dendreo_client import DendreoClient, DendreoAPIError
from app.services.data_processor import DataProcessor
from app.models.database import get_db
from datetime import datetime
from sqlalchemy.orm import Session
from app.models.models import Participant, Course, Module, ParticipantCourse, ParticipantHubspotData, Creneau, CreneauParticipant, ModuleCategory, AdminSyncConfig, SyncMetadata
from sqlalchemy import func
import os
import asyncio

logger = logging.getLogger(__name__)

class DendreoSync:
    def __init__(self, db: Session, client: DendreoClient):
        self.db = db
        self.client = client
        self.batch_size = 50
        # Get ADF limit from environment variable, default to None (no limit)
        adf_limit_str = os.getenv('DENDREO_ADF_LIMIT', '').strip()
        if adf_limit_str and adf_limit_str.isdigit():
            adf_limit_value = int(adf_limit_str)
            # Treat 0 as no limit
            self.adf_limit = adf_limit_value if adf_limit_value > 0 else None
        else:
            self.adf_limit = None
        
        # Get cleanup settings from environment variables
        self.enable_cleanup = os.getenv('DENDREO_ENABLE_CLEANUP', 'true').lower() == 'true'
        if not self.enable_cleanup:
            logger.warning("🧹 Cleanup is DISABLED (DENDREO_ENABLE_CLEANUP=false)")
        self.stats = {
            "participants_created": 0,
            "participants_updated": 0,
            "participants_removed": 0,
            "courses_created": 0,
            "courses_updated": 0,
            "courses_removed": 0,
            "modules_created": 0,
            "modules_updated": 0,
            "modules_removed": 0,
            "participant_courses_created": 0,
            "participant_courses_updated": 0,
            "participant_courses_removed": 0,
            "hubspot_data_created": 0,
            "hubspot_data_updated": 0,
            "creneaux_created": 0,
            "creneaux_updated": 0,
            "creneau_participants_created": 0,
            "creneau_participants_updated": 0,
            "categories_synced": 0,
            "hubspot_updates_total": 0,
            "hubspot_updates_successful": 0,
            "hubspot_updates_failed": 0,
            "hubspot_status": "unknown",
            "hubspot_error": None,
            "adfs_skipped_api_limit": 0,
            "adfs_status_updated": 0,
            "adfs_left_tracker": [],
            "dendreo_api_limit": None,
            "hubspot_api_limit": None
        }

    def _apply_period_budget(self, admin_config, per_sync_limit, daily_field, weekly_field, monthly_field, count_column_name, label):
        """Compute effective per-sync limit by capping with remaining period budgets.
        Usage is summed across SyncMetadata and ActionHistory (user-triggered actions)."""
        from app.services.api_budget import get_period_usage

        provider = 'dendreo' if count_column_name == 'api_calls_count' else 'hubspot'
        periods = [(daily_field, 'daily'), (weekly_field, 'weekly'), (monthly_field, 'monthly')]

        effective = per_sync_limit
        for field, period_label in periods:
            limit_val = getattr(admin_config, field, None)
            if not limit_val or limit_val <= 0:
                continue
            usage = get_period_usage(self.db, provider, period_label)
            remaining = max(0, limit_val - usage)
            logger.info(f"🔒 {label} {period_label} budget: {usage}/{limit_val} used, {remaining} remaining")
            if effective is None:
                effective = remaining
            else:
                effective = min(effective, remaining)

        return effective

    async def sync_all(self, only_adf_ids: List[str] = None) -> Dict[str, Any]:
        """Synchronize all data from Dendreo using chunked LAP-based approach

        Args:
            only_adf_ids: If provided, only process these specific ADF IDs (used for resume)
        """
        try:
            logger.info("🚀 Starting CHUNKED sync from Dendreo API (LAP-based approach)")

            # Reset rate limiting statistics
            self.client.reset_rate_limit_stats()

            start_time = datetime.now()

            # Read API limits from admin config
            admin_config = self.db.query(AdminSyncConfig).first()
            dendreo_api_limit = None
            hubspot_api_limit = None
            if admin_config:
                dendreo_api_limit = admin_config.dendreo_api_limit if admin_config.dendreo_api_limit and admin_config.dendreo_api_limit > 0 else None
                hubspot_api_limit = admin_config.hubspot_api_limit if admin_config.hubspot_api_limit and admin_config.hubspot_api_limit > 0 else None

                # Compute remaining period budgets and cap per-sync limits
                dendreo_api_limit = self._apply_period_budget(
                    admin_config, dendreo_api_limit,
                    'dendreo_daily_limit', 'dendreo_weekly_limit', 'dendreo_monthly_limit',
                    'api_calls_count', 'Dendreo'
                )
                hubspot_api_limit = self._apply_period_budget(
                    admin_config, hubspot_api_limit,
                    'hubspot_daily_limit', 'hubspot_weekly_limit', 'hubspot_monthly_limit',
                    'hubspot_api_calls_count', 'HubSpot'
                )

            if dendreo_api_limit is not None:
                logger.info(f"🔒 Dendreo API limit: {dendreo_api_limit} calls (effective)")
                self.stats["dendreo_api_limit"] = dendreo_api_limit
            if hubspot_api_limit is not None:
                logger.info(f"🔒 HubSpot API limit: {hubspot_api_limit} calls (effective)")
                self.stats["hubspot_api_limit"] = hubspot_api_limit

            # Fetch ADFs (lightweight - no 70MB monster!)
            adf_data = await self.client.get_actions_de_formation()
            logger.info(f"✅ Fetched {len(adf_data) if adf_data else 0} ADF records from API")
            if not isinstance(adf_data, list):
                logger.error(f"Invalid ADFs data type received: {type(adf_data)}")
                return {
                    "status": "error",
                    "message": "Invalid ADFs data received from API"
                }

            # Fetch and sync module categories (1 API call)
            await self._sync_module_categories()
            self.db.commit()

            # Filter to specific ADF IDs if resuming
            if only_adf_ids:
                adf_data = [a for a in adf_data if str(a.get('id_action_de_formation')) in only_adf_ids]
                logger.info(f"🔄 Resume mode: filtered to {len(adf_data)} ADFs out of {len(only_adf_ids)} requested IDs")

            # Apply ADF limit if set
            if self.adf_limit:
                logger.info(f"⚠️  Limiting total ADFs to {self.adf_limit} (DENDREO_ADF_LIMIT)")
                adf_data = adf_data[:self.adf_limit]
                logger.info(f"After limit: {len(adf_data)} ADF records")

            # Process ADFs in batches to create courses
            logger.info("📚 Processing ADFs to create courses...")
            active_courses = {}
            adf_batches = [adf_data[i:i + self.batch_size] for i in range(0, len(adf_data), self.batch_size)]

            for batch_num, adf_batch in enumerate(adf_batches, 1):
                logger.info(f"Processing ADF batch {batch_num}/{len(adf_batches)}")
                batch_courses = await self._process_adfs(adf_batch)
                active_courses.update(batch_courses)
                self.db.commit()

            # Track all current participant-course combinations
            all_current_participant_courses = set()

            # NEW CHUNKED APPROACH: Process LAPs per ADF, then LMPs per LAP
            logger.info("🔄 Processing LAPs and LMPs using chunked approach...")

            # DEBUG: Log sample ADFs to see their id_etape_process values
            logger.info(f"📋 Sample of first 5 ADFs:")
            for i, sample_adf in enumerate(adf_data[:5], 1):
                logger.info(f"   ADF {i}: id={sample_adf.get('id_action_de_formation')}, id_etape_process={sample_adf.get('id_etape_process')} (type: {type(sample_adf.get('id_etape_process'))})")

            api_limit_reached = False
            for adf_idx, adf in enumerate(adf_data, 1):
                id_adf = adf.get('id_action_de_formation')
                if not id_adf:
                    continue

                # Check Dendreo API limit before processing each ADF
                if dendreo_api_limit is not None and self.client.total_requests >= dendreo_api_limit:
                    # Collect skipped active ADF IDs for resume capability
                    skipped_adf_ids = []
                    for remaining_adf in adf_data[adf_idx - 1:]:
                        r_id = remaining_adf.get('id_action_de_formation')
                        r_status = remaining_adf.get('id_etape_process')
                        if r_id and str(r_status) in ['5', '6', '7']:
                            skipped_adf_ids.append(str(r_id))

                    logger.warning(
                        f"🔒 Dendreo API limit reached ({self.client.total_requests}/{dendreo_api_limit} calls). "
                        f"Skipping {len(skipped_adf_ids)} remaining active ADFs."
                    )
                    self.stats["adfs_skipped_api_limit"] = len(skipped_adf_ids)
                    self.stats["skipped_adf_ids"] = skipped_adf_ids
                    api_limit_reached = True
                    break

                # Only process active ADFs (status 5, 6, or 7)
                id_etape_process = adf.get('id_etape_process')
                # Convert to string to handle both string and integer types
                if not id_etape_process or str(id_etape_process) not in ['5', '6', '7']:
                    # Update status of existing courses whose etape changed to inactive
                    if id_adf:
                        stale_courses = self.db.query(Course).filter(
                            Course.id_action_formation == str(id_adf),
                            Course.status.in_(['5', '6', '7'])
                        ).all()
                        if stale_courses:
                            for c in stale_courses:
                                c.status = str(id_etape_process) if id_etape_process else None
                            self.db.commit()
                            self.stats["adfs_status_updated"] += 1
                            self.stats["adfs_left_tracker"].append({
                                "id_adf": str(id_adf),
                                "intitule": adf.get('intitule', ''),
                                "old_status": "5/6/7",
                                "new_status": str(id_etape_process) if id_etape_process else "None"
                            })
                            logger.info(f"📝 Updated {len(stale_courses)} course(s) for ADF {id_adf}: etape → {id_etape_process}")
                    if adf_idx <= 10:  # Log first 10 skips to avoid spam
                        logger.info(f"⏭️  Skipping inactive ADF {id_adf} with status {id_etape_process} (type: {type(id_etape_process)})")
                    continue

                logger.info(f"📦 [{adf_idx}/{len(adf_data)}] Processing ADF {id_adf}...")

                try:
                    # Fetch LAPs for this ADF (small request)
                    laps_data = await self.client.get_laps(id_adf)
                    if not laps_data:
                        logger.debug(f"No LAPs found for ADF {id_adf}")
                        continue

                    logger.info(f"   Found {len(laps_data)} LAPs for ADF {id_adf}")

                    # Process each LAP (fetches LMPs per LAP - small requests!)
                    for lap_idx, lap_record in enumerate(laps_data, 1):
                        id_lap = lap_record.get('id_lap')
                        if not id_lap:
                            continue

                        logger.debug(f"   Processing LAP {lap_idx}/{len(laps_data)}: {id_lap}")

                        # Get participant
                        participant_data = lap_record.get('participant')
                        if not participant_data:
                            logger.warning(f"LAP {id_lap} missing participant data")
                            continue

                        # Extract id_entreprise from LAP record
                        id_entreprise = lap_record.get('id_entreprise')
                        if id_entreprise:
                            participant_data['id_entreprise'] = id_entreprise

                        # Extract date_add from participant data (when participant was added to ADF)
                        date_add_str = participant_data.get('date_add')
                        date_add = None
                        if date_add_str:
                            try:
                                date_add = datetime.strptime(date_add_str, '%Y-%m-%d %H:%M:%S')
                            except ValueError as e:
                                logger.warning(f"Invalid date_add format for LAP {id_lap}: {e}")

                        participant = await self._get_or_create_participant(participant_data)
                        if not participant:
                            continue

                        # Fetch LMPs for this specific LAP (small request!)
                        try:
                            lmps_data = await self.client.get_lmps_for_lap(id_lap)
                            if not lmps_data:
                                logger.debug(f"No LMPs found for LAP {id_lap}")
                                continue

                            logger.debug(f"      Found {len(lmps_data)} LMPs for LAP {id_lap}")

                            # Create courses on-the-fly for id_lam values not yet in active_courses
                            # (handles ADFs whose modules list is empty in the ADF payload)
                            for lmp in lmps_data:
                                lmp_id_lam = lmp.get('id_lam')
                                if lmp_id_lam and lmp_id_lam not in active_courses:
                                    existing = self.db.query(Course).filter(
                                        Course.id_action_formation == id_adf,
                                        Course.id_lam == lmp_id_lam
                                    ).first()
                                    if existing:
                                        active_courses[lmp_id_lam] = existing
                                    else:
                                        # Try to find date_debut/date_fin from ADF modules list
                                        adf_module_dates = {}
                                        for adf_mod in adf.get('modules', []):
                                            if adf_mod.get('id_lam') == lmp_id_lam:
                                                adf_module_dates = adf_mod
                                                break
                                        fb_date_debut = None
                                        fb_date_fin = None
                                        if adf_module_dates.get('date_debut', '').strip():
                                            try:
                                                fb_date_debut = datetime.strptime(adf_module_dates['date_debut'].strip(), '%Y-%m-%d %H:%M:%S')
                                            except ValueError:
                                                pass
                                        if adf_module_dates.get('date_fin', '').strip():
                                            try:
                                                fb_date_fin = datetime.strptime(adf_module_dates['date_fin'].strip(), '%Y-%m-%d %H:%M:%S')
                                            except ValueError:
                                                pass
                                        new_course = Course(
                                            id_action_formation=id_adf,
                                            id_lam=lmp_id_lam,
                                            intitule=adf.get('intitule', ''),
                                            status=adf.get('id_etape_process', '5'),
                                            categorie_module_id=adf.get('categorie_module_id') or None,
                                            total_modules=0,
                                            date_debut=fb_date_debut,
                                            date_fin=fb_date_fin,
                                        )
                                        self.db.add(new_course)
                                        self.db.flush()
                                        active_courses[lmp_id_lam] = new_course
                                        self.stats["courses_created"] += 1
                                        logger.info(f"Created course from LMP data: ADF {id_adf} LAM {lmp_id_lam}")

                            # Process LMPs for this LAP
                            lap_participant_courses = await self._process_lmps(lmps_data, active_courses)
                            all_current_participant_courses.update(lap_participant_courses)

                            # Update id_lap and date_add on ParticipantCourse records
                            course_ids = [c.id for c in self.db.query(Course).filter(Course.id_action_formation == id_adf).all()]
                            if course_ids:
                                participant_courses = self.db.query(ParticipantCourse).filter(
                                    ParticipantCourse.participant_id == participant.id,
                                    ParticipantCourse.course_id.in_(course_ids)
                                ).all()

                                for pc in participant_courses:
                                    pc.id_lap = id_lap
                                    if date_add:
                                        pc.date_add = date_add
                                    pc.updated_at = datetime.utcnow()

                            # Process HubSpot data from this LAP
                            c_url_transaction_hubspot = lap_record.get('c_url_transaction_hubspot')
                            c_id_transaction_hubspot = lap_record.get('c_id_transaction_hubspot')

                            if c_url_transaction_hubspot or c_id_transaction_hubspot:
                                hubspot_data = self.db.query(ParticipantHubspotData).filter(
                                    ParticipantHubspotData.participant_id == participant.id,
                                    ParticipantHubspotData.id_action_formation == id_adf
                                ).first()

                                if hubspot_data:
                                    if hubspot_data.is_manual_link:
                                        hubspot_data.id_lap = id_lap
                                        hubspot_data.updated_at = datetime.utcnow()
                                    else:
                                        hubspot_data.id_lap = id_lap
                                        hubspot_data.c_url_transaction_hubspot = c_url_transaction_hubspot
                                        hubspot_data.c_id_transaction_hubspot = c_id_transaction_hubspot
                                        hubspot_data.updated_at = datetime.utcnow()
                                        self.stats["hubspot_data_updated"] += 1
                                else:
                                    try:
                                        hubspot_data = ParticipantHubspotData(
                                            participant_id=participant.id,
                                            id_action_formation=id_adf,
                                            id_lap=id_lap,
                                            c_url_transaction_hubspot=c_url_transaction_hubspot,
                                            c_id_transaction_hubspot=c_id_transaction_hubspot
                                        )
                                        self.db.add(hubspot_data)
                                        self.db.flush()
                                        self.stats["hubspot_data_created"] += 1
                                    except Exception as e:
                                        if "unique constraint" in str(e).lower() or "duplicate key" in str(e).lower():
                                            self.db.rollback()
                                            hubspot_data = self.db.query(ParticipantHubspotData).filter(
                                                ParticipantHubspotData.participant_id == participant.id,
                                                ParticipantHubspotData.id_action_formation == id_adf
                                            ).first()
                                            if hubspot_data and not hubspot_data.is_manual_link:
                                                hubspot_data.id_lap = id_lap
                                                hubspot_data.c_url_transaction_hubspot = c_url_transaction_hubspot
                                                hubspot_data.c_id_transaction_hubspot = c_id_transaction_hubspot
                                                hubspot_data.updated_at = datetime.utcnow()
                                                self.stats["hubspot_data_updated"] += 1

                        except Exception as e:
                            logger.warning(f"Error processing LAP {id_lap}: {e}")
                            continue

                    # Fetch and process creneaux (liveroom sessions) for this ADF
                    try:
                        creneaux_data = await self.client.get_creneaux(id_adf)
                        if creneaux_data:
                            logger.info(f"   Found {len(creneaux_data)} creneaux for ADF {id_adf}")
                            await self._process_creneaux(creneaux_data, id_adf)
                        else:
                            logger.debug(f"   No creneaux found for ADF {id_adf}")
                    except Exception as e:
                        logger.warning(f"Error processing creneaux for ADF {id_adf}: {e}")

                    # Commit after each ADF to avoid large transactions
                    self.db.commit()
                    logger.info(f"✅ Completed ADF {id_adf} ({adf_idx}/{len(adf_data)})")

                except Exception as e:
                    logger.error(f"Error processing ADF {id_adf}: {e}")
                    self.db.rollback()
                    continue

            # Cleanup removed participants (only if enabled)
            if self.enable_cleanup:
                logger.info("🧹 Cleaning up removed participants...")
                await self._cleanup_removed_participants(active_courses, all_current_participant_courses)
                self.db.commit()

                # Cleanup orphaned participants
                logger.info("🧹 Cleaning up orphaned participants...")
                await self._cleanup_orphaned_participants()
                self.db.commit()

                # Cleanup orphaned courses
                logger.info("🧹 Cleaning up orphaned courses...")
                await self._cleanup_orphaned_courses(active_courses)
                self.db.commit()
            else:
                logger.info("🧹 Skipping cleanup (DENDREO_ENABLE_CLEANUP=false)")

            # Auto-link new participants to their HubSpot deal (captures EDOF dates).
            # Only the unambiguous case is linked (exactly one eligible deal in the EDOF
            # pipeline); the deal is tied to the participant and replicated across all
            # their active courses. Multi-eligible-deal participants are left for staff.
            # Bounded by the HubSpot API budget.
            logger.info("🔗 Auto-linking new participants to HubSpot deals...")
            try:
                from app.services.edof_auto_link import auto_link_deals

                autolink_result = await auto_link_deals(
                    self.db,
                    commit=True,
                    sleep_s=0.15,
                    max_hubspot_calls=hubspot_api_limit,
                    update_counter=True,
                    log=logger.info,
                )
                self.stats["autolink_linked"] = autolink_result.get("linked", 0)
                self.stats["autolink_candidates"] = autolink_result.get("candidates", 0)
                self.stats["autolink_multi_deal"] = autolink_result.get("multi_deal", 0)
                self.stats["autolink_hubspot_calls"] = autolink_result.get("hubspot_calls", 0)
                logger.info(
                    f"🔗 Auto-link: {autolink_result.get('linked', 0)} linked, "
                    f"{autolink_result.get('multi_deal', 0)} multi-deal skipped, "
                    f"{autolink_result.get('hubspot_calls', 0)} HubSpot calls"
                    + (" (budget reached)" if autolink_result.get("budget_stopped") else "")
                )
            except Exception as e:
                logger.error(f"❌ Auto-link phase failed: {str(e)}")
                self.stats["autolink_error"] = str(e)

            # Pull back HubSpot-side edits on the linked deals (billing status,
            # amounts, EDOF dates). Runs after auto-link so links created in this
            # same run are refreshed too. ~1 call per 100 distinct deals.
            logger.info("💶 Refreshing deal fields from HubSpot...")
            try:
                from app.services.deal_refresh import refresh_deal_fields

                remaining_hubspot = None
                if hubspot_api_limit:
                    remaining_hubspot = max(
                        0, hubspot_api_limit - self.stats.get("autolink_hubspot_calls", 0)
                    )

                refresh_result = await refresh_deal_fields(
                    self.db,
                    commit=True,
                    max_hubspot_calls=remaining_hubspot,
                    update_counter=True,
                    log=logger.info,
                )
                self.stats["deal_refresh_updated"] = refresh_result.get("updated", 0)
                self.stats["deal_refresh_rows"] = refresh_result.get("rows_scanned", 0)
                self.stats["deal_refresh_hubspot_calls"] = refresh_result.get("hubspot_calls", 0)
                logger.info(
                    f"💶 Deal refresh: {refresh_result.get('updated', 0)} row(s) updated of "
                    f"{refresh_result.get('rows_scanned', 0)}, "
                    f"{refresh_result.get('hubspot_calls', 0)} HubSpot calls"
                    + (" (budget reached)" if refresh_result.get("budget_stopped") else "")
                )
            except Exception as e:
                logger.error(f"❌ Deal refresh phase failed: {str(e)}")
                self.stats["deal_refresh_error"] = str(e)

            end_time = datetime.now()
            duration = (end_time - start_time).total_seconds()

            # Get and log rate limiting statistics
            rate_limit_stats = self.client.get_rate_limit_stats()
            logger.info(f"🚦 Rate Limiting Stats: {rate_limit_stats}")

            if api_limit_reached:
                logger.warning(f"⚠️  CHUNKED sync completed with API limit reached in {duration:.2f}s. {self.stats['adfs_skipped_api_limit']} ADFs skipped. Final stats: {self.stats}")
            else:
                logger.info(f"✅ CHUNKED sync completed successfully in {duration:.2f}s. Final stats: {self.stats}")
            logger.info(f"📊 Processed {len(adf_data)} ADFs using chunked LAP-based approach (no 70MB timeouts!)")

            # Add rate limiting info to return stats
            return {
                "status": "success",
                "message": f"Chunked sync completed in {duration:.2f} seconds" + (f" (API limit reached, {self.stats['adfs_skipped_api_limit']} ADFs skipped)" if api_limit_reached else ""),
                "stats": self.stats,
                "rate_limiting": rate_limit_stats
            }

        except Exception as e:
            logger.error(f"Error during sync: {str(e)}")
            self.db.rollback()
            raise

    async def sync_single_adf(self, id_action_formation: str) -> Dict[str, Any]:
        """Sync a single ADF by its id_action_formation. Skips cleanup and HubSpot updates."""
        try:
            logger.info(f"🎯 Starting single-ADF sync for {id_action_formation}")
            self.client.reset_rate_limit_stats()
            start_time = datetime.now()

            # Fetch all ADFs to find the target (API has no single-ADF filter)
            adf_data = await self.client.get_actions_de_formation()
            if not isinstance(adf_data, list):
                return {"status": "error", "message": "Invalid ADFs data received from API"}

            target_adf = None
            for adf in adf_data:
                if str(adf.get('id_action_de_formation')) == str(id_action_formation):
                    target_adf = adf
                    break

            if not target_adf:
                return {"status": "error", "message": f"ADF {id_action_formation} not found in Dendreo API"}

            id_adf = str(id_action_formation)
            current_etape = str(target_adf.get('id_etape_process', ''))

            # Check etape FIRST before making further API calls
            is_active = current_etape in ['5', '6', '7']

            # Always update Course.status for this ADF regardless of etape
            if current_etape:
                existing_courses = self.db.query(Course).filter(
                    Course.id_action_formation == id_adf
                ).all()
                for c in existing_courses:
                    if c.status != current_etape:
                        c.status = current_etape

            if not is_active:
                self.db.commit()
                duration = (datetime.now() - start_time).total_seconds()
                rate_limit_stats = self.client.get_rate_limit_stats()
                logger.info(f"⚠️ ADF {id_adf} has etape {current_etape} (not active). Status updated, skipping further sync.")
                return {
                    "status": "warning",
                    "message": f"ADF {id_adf} has etape {current_etape} (not active: only 5, 6, 7 are synced). Course status updated but no participant data was synced.",
                    "etape": current_etape,
                    "stats": self.stats,
                    "rate_limiting": rate_limit_stats
                }

            # Process the ADF to create/update courses
            active_courses = await self._process_adfs([target_adf])
            self.db.commit()

            # Fetch and process LAPs → LMPs (same logic as sync_all per-ADF block)
            laps_data = await self.client.get_laps(id_adf)
            if laps_data:
                logger.info(f"   Found {len(laps_data)} LAPs for ADF {id_adf}")

                for lap_idx, lap_record in enumerate(laps_data, 1):
                    id_lap = lap_record.get('id_lap')
                    if not id_lap:
                        continue

                    participant_data = lap_record.get('participant')
                    if not participant_data:
                        continue

                    id_entreprise = lap_record.get('id_entreprise')
                    if id_entreprise:
                        participant_data['id_entreprise'] = id_entreprise

                    date_add_str = participant_data.get('date_add')
                    date_add = None
                    if date_add_str:
                        try:
                            date_add = datetime.strptime(date_add_str, '%Y-%m-%d %H:%M:%S')
                        except ValueError:
                            pass

                    participant = await self._get_or_create_participant(participant_data)
                    if not participant:
                        continue

                    try:
                        lmps_data = await self.client.get_lmps_for_lap(id_lap)
                        if lmps_data:
                            # Create courses on-the-fly for id_lam values not yet in active_courses
                            # (handles ADFs whose modules list is empty in the ADF payload)
                            for lmp in lmps_data:
                                lmp_id_lam = lmp.get('id_lam')
                                if lmp_id_lam and lmp_id_lam not in active_courses:
                                    existing = self.db.query(Course).filter(
                                        Course.id_action_formation == id_adf,
                                        Course.id_lam == lmp_id_lam
                                    ).first()
                                    if existing:
                                        active_courses[lmp_id_lam] = existing
                                    else:
                                        # Try to find date_debut/date_fin from ADF modules list
                                        adf_module_dates = {}
                                        for adf_mod in target_adf.get('modules', []):
                                            if adf_mod.get('id_lam') == lmp_id_lam:
                                                adf_module_dates = adf_mod
                                                break
                                        fb_date_debut = None
                                        fb_date_fin = None
                                        if adf_module_dates.get('date_debut', '').strip():
                                            try:
                                                fb_date_debut = datetime.strptime(adf_module_dates['date_debut'].strip(), '%Y-%m-%d %H:%M:%S')
                                            except ValueError:
                                                pass
                                        if adf_module_dates.get('date_fin', '').strip():
                                            try:
                                                fb_date_fin = datetime.strptime(adf_module_dates['date_fin'].strip(), '%Y-%m-%d %H:%M:%S')
                                            except ValueError:
                                                pass
                                        new_course = Course(
                                            id_action_formation=id_adf,
                                            id_lam=lmp_id_lam,
                                            intitule=target_adf.get('intitule', ''),
                                            status=target_adf.get('id_etape_process', '5'),
                                            categorie_module_id=target_adf.get('categorie_module_id') or None,
                                            total_modules=0,
                                            date_debut=fb_date_debut,
                                            date_fin=fb_date_fin,
                                        )
                                        self.db.add(new_course)
                                        self.db.flush()
                                        active_courses[lmp_id_lam] = new_course
                                        self.stats["courses_created"] += 1
                                        logger.info(f"Created course from LMP data: ADF {id_adf} LAM {lmp_id_lam}")

                            await self._process_lmps(lmps_data, active_courses)

                            course_ids = [c.id for c in self.db.query(Course).filter(Course.id_action_formation == id_adf).all()]
                            if course_ids:
                                participant_courses = self.db.query(ParticipantCourse).filter(
                                    ParticipantCourse.participant_id == participant.id,
                                    ParticipantCourse.course_id.in_(course_ids)
                                ).all()
                                for pc in participant_courses:
                                    pc.id_lap = id_lap
                                    if date_add:
                                        pc.date_add = date_add
                                    pc.updated_at = datetime.utcnow()

                            # Process HubSpot data from this LAP
                            c_url_transaction_hubspot = lap_record.get('c_url_transaction_hubspot')
                            c_id_transaction_hubspot = lap_record.get('c_id_transaction_hubspot')

                            if c_url_transaction_hubspot or c_id_transaction_hubspot:
                                hubspot_data = self.db.query(ParticipantHubspotData).filter(
                                    ParticipantHubspotData.participant_id == participant.id,
                                    ParticipantHubspotData.id_action_formation == id_adf
                                ).first()

                                if hubspot_data:
                                    if hubspot_data.is_manual_link:
                                        hubspot_data.id_lap = id_lap
                                        hubspot_data.updated_at = datetime.utcnow()
                                    else:
                                        hubspot_data.id_lap = id_lap
                                        hubspot_data.c_url_transaction_hubspot = c_url_transaction_hubspot
                                        hubspot_data.c_id_transaction_hubspot = c_id_transaction_hubspot
                                        hubspot_data.updated_at = datetime.utcnow()
                                        self.stats["hubspot_data_updated"] += 1
                                else:
                                    try:
                                        hubspot_data = ParticipantHubspotData(
                                            participant_id=participant.id,
                                            id_action_formation=id_adf,
                                            id_lap=id_lap,
                                            c_url_transaction_hubspot=c_url_transaction_hubspot,
                                            c_id_transaction_hubspot=c_id_transaction_hubspot
                                        )
                                        self.db.add(hubspot_data)
                                        self.db.flush()
                                        self.stats["hubspot_data_created"] += 1
                                    except Exception as e:
                                        if "unique constraint" in str(e).lower() or "duplicate key" in str(e).lower():
                                            self.db.rollback()
                                            hubspot_data = self.db.query(ParticipantHubspotData).filter(
                                                ParticipantHubspotData.participant_id == participant.id,
                                                ParticipantHubspotData.id_action_formation == id_adf
                                            ).first()
                                            if hubspot_data and not hubspot_data.is_manual_link:
                                                hubspot_data.id_lap = id_lap
                                                hubspot_data.c_url_transaction_hubspot = c_url_transaction_hubspot
                                                hubspot_data.c_id_transaction_hubspot = c_id_transaction_hubspot
                                                hubspot_data.updated_at = datetime.utcnow()
                                                self.stats["hubspot_data_updated"] += 1

                    except Exception as e:
                        logger.warning(f"Error processing LAP {id_lap}: {e}")
                        continue
            else:
                logger.info(f"   No LAPs found for ADF {id_adf}")

            # Fetch and process creneaux
            try:
                creneaux_data = await self.client.get_creneaux(id_adf)
                if creneaux_data:
                    logger.info(f"   Found {len(creneaux_data)} creneaux for ADF {id_adf}")
                    await self._process_creneaux(creneaux_data, id_adf)
                else:
                    logger.debug(f"   No creneaux found for ADF {id_adf}")
            except Exception as e:
                logger.warning(f"Error processing creneaux for ADF {id_adf}: {e}")

            self.db.commit()

            duration = (datetime.now() - start_time).total_seconds()
            rate_limit_stats = self.client.get_rate_limit_stats()
            logger.info(f"✅ Single-ADF sync for {id_adf} completed in {duration:.2f}s. Stats: {self.stats}")

            return {
                "status": "success",
                "message": f"Single-ADF sync for {id_adf} completed in {duration:.2f}s",
                "stats": self.stats,
                "rate_limiting": rate_limit_stats
            }

        except Exception as e:
            logger.error(f"Error during single-ADF sync: {str(e)}")
            self.db.rollback()
            raise

    def _filter_elearning_records(self, data: List[Dict]) -> List[Dict]:
        """Filter records for processing (all module types)"""
        filtered = []
        module_counts = {}  # {id_lam: count} to track trackable modules per course

        if not isinstance(data, list):
            logger.error(f"Invalid data type received: {type(data)}")
            return []

        for record in data:
            if not isinstance(record, dict):
                logger.warning(f"Invalid record type: {type(record)}, skipping")
                continue

            # Check if record has required data
            if not record.get('participant'):
                continue

            id_lam = record.get('id_lam')

            if id_lam:
                filtered.append(record)
                # Track module count for this course
                module_counts[id_lam] = module_counts.get(id_lam, 0) + 1
                logger.debug(f"Found trackable module for LAM {id_lam}")
        
        # Update total_modules for each course
        for id_lam, count in module_counts.items():
            course = self.db.query(Course).filter(Course.id_lam == id_lam).first()
            if course:
                course.total_modules = count
                logger.debug(f"Updated course {course.id_action_formation} with {count} trackable modules")
                
        logger.info(f"Filtered {len(filtered)} records for processing from {len(data)} total records")
        return filtered

    async def _sync_module_categories(self):
        """Fetch and upsert module categories from Dendreo"""
        try:
            categories_data = await self.client.get_module_categories()
            if not categories_data:
                logger.info("No module categories found in API")
                return

            logger.info(f"📁 Syncing {len(categories_data)} module categories...")
            for cat in categories_data:
                id_cat = cat.get('id_categorie_module')
                if not id_cat:
                    continue

                display_order = 0
                try:
                    display_order = int(cat.get('order', 0))
                except (ValueError, TypeError):
                    pass

                existing = self.db.query(ModuleCategory).filter(
                    ModuleCategory.id_categorie_module == str(id_cat)
                ).first()

                if existing:
                    existing.intitule = cat.get('intitule', '')
                    existing.color = cat.get('color', '')
                    existing.status = cat.get('status', '1')
                    existing.display_order = display_order
                    existing.updated_at = datetime.utcnow()
                else:
                    new_cat = ModuleCategory(
                        id_categorie_module=str(id_cat),
                        intitule=cat.get('intitule', ''),
                        color=cat.get('color', ''),
                        status=cat.get('status', '1'),
                        display_order=display_order
                    )
                    self.db.add(new_cat)

                self.stats["categories_synced"] += 1

            logger.info(f"✅ Synced {self.stats['categories_synced']} module categories")
        except Exception as e:
            logger.warning(f"Error syncing module categories: {e}")

    async def _process_adfs(self, adf_batch: List[Dict]) -> Dict[str, Course]:
        """Process ADF data to create or update courses"""
        active_courses = {}

        for adf in adf_batch:
            # Only process active ADFs (status 5, 6, or 7)
            id_etape_process = adf.get('id_etape_process')
            id_adf = adf.get('id_action_de_formation')
            if not id_etape_process or str(id_etape_process) not in ['5', '6', '7']:
                # Update status of existing courses whose etape changed to inactive
                if id_adf:
                    stale_courses = self.db.query(Course).filter(
                        Course.id_action_formation == str(id_adf),
                        Course.status.in_(['5', '6', '7'])
                    ).all()
                    if stale_courses:
                        for c in stale_courses:
                            c.status = str(id_etape_process) if id_etape_process else None
                        self.stats["adfs_status_updated"] += 1
                        self.stats["adfs_left_tracker"].append({
                            "id_adf": str(id_adf),
                            "intitule": adf.get('intitule', ''),
                            "old_status": "5/6/7",
                            "new_status": str(id_etape_process) if id_etape_process else "None"
                        })
                        logger.info(f"📝 Updated {len(stale_courses)} course(s) for ADF {id_adf}: etape → {id_etape_process}")
                continue
            if not id_adf:
                logger.warning("Skipping ADF - missing id_action_de_formation")
                continue

            # Get modules from the ADF
            modules = adf.get('modules', [])
            if not modules:
                logger.debug(f"ADF {id_adf} has no modules, skipping")
                continue

            # Extract formateurs and category data from ADF
            formateurs = adf.get('formateurs', [])
            adf_categorie_module_id = adf.get('categorie_module_id', '') or ''

            # Process each module in the ADF
            for module in modules:
                id_lam = module.get('id_lam')
                if not id_lam:
                    logger.debug(f"Module in ADF {id_adf} missing id_lam, skipping")
                    continue

                # Create or update course for this module
                course = self.db.query(Course).filter(Course.id_action_formation == id_adf, Course.id_lam == id_lam).first()
                # Parse module date_debut and date_fin
                module_date_debut = None
                module_date_fin = None
                date_debut_raw = module.get('date_debut', '')
                date_fin_raw = module.get('date_fin', '')
                if date_debut_raw and date_debut_raw.strip():
                    try:
                        module_date_debut = datetime.strptime(date_debut_raw.strip(), '%Y-%m-%d %H:%M:%S')
                    except ValueError:
                        logger.debug(f"Invalid date_debut format for module {id_lam} in ADF {id_adf}: {date_debut_raw}")
                if date_fin_raw and date_fin_raw.strip():
                    try:
                        module_date_fin = datetime.strptime(date_fin_raw.strip(), '%Y-%m-%d %H:%M:%S')
                    except ValueError:
                        logger.debug(f"Invalid date_fin format for module {id_lam} in ADF {id_adf}: {date_fin_raw}")

                if not course:
                    # Extract planned duration from module data (only for new courses)
                    planned_duration_hours = 0.0
                    duree_heures_str = module.get('duree_heures', '0')
                    if duree_heures_str:
                        try:
                            planned_duration_hours = float(duree_heures_str)
                        except (ValueError, TypeError):
                            planned_duration_hours = 0.0

                    course = Course(
                        id_action_formation=id_adf,
                        id_lam=id_lam,
                        intitule=adf.get('intitule', ''),
                        status=id_etape_process,
                        categorie_module_id=adf_categorie_module_id if adf_categorie_module_id else None,
                        total_modules=0,  # Will be updated when processing LMPs
                        planned_duration_hours=planned_duration_hours,
                        formateurs=formateurs if formateurs else None,
                        date_debut=module_date_debut,
                        date_fin=module_date_fin
                    )
                    self.db.add(course)
                    self.stats["courses_created"] += 1
                    logger.debug(f"Created new course: {id_adf} - {id_lam} with {planned_duration_hours}h planned and {len(formateurs)} formateurs")
                else:
                    # Update basic course info including formateurs and category
                    course.intitule = adf.get('intitule', '')
                    course.status = id_etape_process
                    course.categorie_module_id = adf_categorie_module_id if adf_categorie_module_id else course.categorie_module_id
                    course.formateurs = formateurs if formateurs else None
                    course.date_debut = module_date_debut
                    course.date_fin = module_date_fin
                    self.stats["courses_updated"] += 1
                    logger.debug(f"Updated course: {id_adf} - {id_lam} (kept existing planned duration: {course.planned_duration_hours}h, updated {len(formateurs)} formateurs)")

                # Store course by id_lam
                active_courses[id_lam] = course

        return active_courses

    async def _process_hubspot_data(self, adf_data: List[Dict]):
        """Process HubSpot data from LAPS for each ADF"""
        for adf in adf_data:
            id_adf = adf.get('id_action_de_formation')
            if not id_adf:
                continue
                
            # Only process active ADFs (status 5, 6, or 7)
            id_etape_process = adf.get('id_etape_process')
            if not id_etape_process or str(id_etape_process) not in ['5', '6', '7']:
                continue
            
            try:
                # Get LAPS data for this ADF
                laps_data = await self.client.get_laps(id_adf)
                if not laps_data:
                    logger.debug(f"No LAPS data found for ADF {id_adf}")
                    continue
                
                logger.debug(f"Processing {len(laps_data)} LAP records for ADF {id_adf}")
                
                for lap_record in laps_data:
                    await self._process_lap_record(lap_record, id_adf)
                    
            except Exception as e:
                logger.error(f"Error processing HubSpot data for ADF {id_adf}: {str(e)}")
                continue

    async def _process_lap_record(self, lap_record: Dict, id_adf: str):
        """Process a single LAP record to extract and store HubSpot data, update id_lap, and fetch time spent data"""
        try:
            # Extract HubSpot transaction data
            c_url_transaction_hubspot = lap_record.get('c_url_transaction_hubspot')
            c_id_transaction_hubspot = lap_record.get('c_id_transaction_hubspot')
            id_lap = lap_record.get('id_lap')
            
            # Skip if no id_lap (this is required for participant-ADF linking)
            if not id_lap:
                logger.debug(f"LAP record missing id_lap, skipping")
                return
            
            # Get participant data from the LAP record
            participant_data = lap_record.get('participant')
            if not participant_data:
                logger.warning(f"LAP record {id_lap} missing participant data")
                return

            # Extract id_entreprise from the LAP record (available at top level)
            id_entreprise = lap_record.get('id_entreprise')
            if id_entreprise:
                participant_data['id_entreprise'] = id_entreprise

            # Extract date_add from participant data (when participant was added to ADF)
            date_add_str = participant_data.get('date_add')
            date_add = None
            if date_add_str:
                try:
                    date_add = datetime.strptime(date_add_str, '%Y-%m-%d %H:%M:%S')
                except ValueError as e:
                    logger.warning(f"Invalid date_add format for LAP {id_lap}: {e}")

            # Debug: Log participant data from LAP record
            lap_participant_id = participant_data.get('id_participant')
            logger.debug(f"Processing LAP {id_lap} for ADF {id_adf} with participant ID {lap_participant_id}")

            # Get or create the participant
            participant = await self._get_or_create_participant(participant_data)
            if not participant:
                logger.warning(f"Could not process participant for LAP {id_lap}")
                return

            # Debug: Log the matched participant
            logger.debug(f"LAP {id_lap}: Matched participant DB ID {participant.id} (Dendreo ID {participant.id_participant})")

            # Update id_lap and date_add on all ParticipantCourse rows for this participant and this ADF
            # Find all course_ids for this ADF
            course_ids = [c.id for c in self.db.query(Course).filter(Course.id_action_formation == id_adf).all()]
            if course_ids:
                participant_courses = self.db.query(ParticipantCourse).filter(
                    ParticipantCourse.participant_id == participant.id,
                    ParticipantCourse.course_id.in_(course_ids)
                ).all()

                updated_count = 0
                for pc in participant_courses:
                    pc.id_lap = id_lap
                    if date_add:
                        pc.date_add = date_add
                    pc.updated_at = datetime.utcnow()
                    updated_count += 1
                
                if updated_count > 0:
                    logger.debug(f"Updated {updated_count} ParticipantCourse records with id_lap {id_lap} for participant {participant.id_participant} in ADF {id_adf}")
                else:
                    logger.warning(f"No ParticipantCourse records found to update for participant {participant.id_participant} (DB ID {participant.id}) in ADF {id_adf}")
            else:
                logger.warning(f"No courses found for ADF {id_adf}")
            
            # Fetch LMPs data for this specific LAP to get time spent data
            try:
                lmps_data = await self.client.get_lmps_for_lap(id_lap)
                if lmps_data:
                    logger.debug(f"Found {len(lmps_data)} LMPs for LAP {id_lap}")
                    await self._process_lap_lmps_data(lmps_data, participant, id_lap)
                else:
                    logger.debug(f"No LMPs data found for LAP {id_lap}")
            except Exception as e:
                logger.warning(f"Error fetching LMPs data for LAP {id_lap}: {e}")
            
            # Only process HubSpot data if it exists
            if c_url_transaction_hubspot or c_id_transaction_hubspot:
                # Create or update HubSpot data record
                hubspot_data = self.db.query(ParticipantHubspotData).filter(
                    ParticipantHubspotData.participant_id == participant.id,
                    ParticipantHubspotData.id_action_formation == id_adf
                ).first()
                
                if hubspot_data:
                    if hubspot_data.is_manual_link:
                        # Only update id_lap, preserve manual deal link
                        hubspot_data.id_lap = id_lap
                        hubspot_data.updated_at = datetime.utcnow()
                        logger.debug(f"Preserved manual deal link for participant {participant.id_participant} in ADF {id_adf}")
                    else:
                        # Update existing record
                        hubspot_data.id_lap = id_lap
                        hubspot_data.c_url_transaction_hubspot = c_url_transaction_hubspot
                        hubspot_data.c_id_transaction_hubspot = c_id_transaction_hubspot
                        hubspot_data.updated_at = datetime.utcnow()
                        self.stats["hubspot_data_updated"] += 1
                        logger.debug(f"Updated HubSpot data for participant {participant.id_participant} in ADF {id_adf}")
                else:
                    # Create new record, but handle potential race condition
                    try:
                        hubspot_data = ParticipantHubspotData(
                            participant_id=participant.id,
                            id_action_formation=id_adf,
                            id_lap=id_lap,
                            c_url_transaction_hubspot=c_url_transaction_hubspot,
                            c_id_transaction_hubspot=c_id_transaction_hubspot
                        )
                        self.db.add(hubspot_data)
                        self.db.flush()  # Try to flush immediately to catch constraint violations
                        self.stats["hubspot_data_created"] += 1
                        logger.debug(f"Created HubSpot data for participant {participant.id_participant} in ADF {id_adf}")
                    except Exception as e:
                        # If constraint violation, try to update instead
                        if "unique constraint" in str(e).lower() or "duplicate key" in str(e).lower():
                            self.db.rollback()
                            # Try to get the existing record again
                            hubspot_data = self.db.query(ParticipantHubspotData).filter(
                                ParticipantHubspotData.participant_id == participant.id,
                                ParticipantHubspotData.id_action_formation == id_adf
                            ).first()
                            if hubspot_data and not hubspot_data.is_manual_link:
                                hubspot_data.id_lap = id_lap
                                hubspot_data.c_url_transaction_hubspot = c_url_transaction_hubspot
                                hubspot_data.c_id_transaction_hubspot = c_id_transaction_hubspot
                                hubspot_data.updated_at = datetime.utcnow()
                                self.stats["hubspot_data_updated"] += 1
                                logger.debug(f"Updated HubSpot data after constraint violation for participant {participant.id_participant} in ADF {id_adf}")
                            else:
                                logger.warning(f"Could not create or update HubSpot data for participant {participant.id_participant} in ADF {id_adf}")
                        else:
                            raise  # Re-raise if it's a different error
                
        except Exception as e:
            logger.error(f"Error processing LAP record {lap_record.get('id_lap', 'unknown')}: {str(e)}")

    async def _process_all_laps_for_time_spent(self, adf_data: List[Dict]):
        """Process all LAPs for time spent data, regardless of HubSpot data"""
        logger.info(f"Starting _process_all_laps_for_time_spent with {len(adf_data) if adf_data else 0} ADF records")
        try:
            for adf_record in adf_data:
                id_adf = adf_record.get('id_action_formation')
                if not id_adf:
                    continue
                
                # Get LAPS data for this ADF
                try:
                    laps_data = await self.client.get_laps(id_adf)
                    if not laps_data:
                        logger.debug(f"No LAPS data found for ADF {id_adf}")
                        continue
                    
                    logger.info(f"Processing {len(laps_data)} LAP records for time spent data in ADF {id_adf}")
                    
                    for lap_record in laps_data:
                        await self._process_lap_for_time_spent(lap_record, id_adf)
                        
                except Exception as e:
                    logger.warning(f"Error fetching LAPS data for ADF {id_adf}: {str(e)}")
                    continue
                    
        except Exception as e:
            logger.error(f"Error processing LAPs for time spent data: {str(e)}")
            raise

    async def _process_lap_for_time_spent(self, lap_record: Dict, id_adf: str):
        """Process a single LAP record for time spent data only"""
        try:
            id_lap = lap_record.get('id_lap')
            if not id_lap:
                return
            
            # Get participant data from the LAP record
            participant_data = lap_record.get('participant')
            if not participant_data:
                logger.warning(f"LAP record {id_lap} missing participant data")
                return
            
            # Get or create the participant
            participant = await self._get_or_create_participant(participant_data)
            if not participant:
                logger.warning(f"Could not process participant for LAP {id_lap}")
                return
            
            # Fetch LMPs data for this specific LAP to get time spent data
            try:
                lmps_data = await self.client.get_lmps_for_lap(id_lap)
                if lmps_data:
                    logger.info(f"Found {len(lmps_data)} LMPs for LAP {id_lap}")
                    await self._process_lap_lmps_data(lmps_data, participant, id_lap)
                else:
                    logger.debug(f"No LMPs data found for LAP {id_lap}")
            except Exception as e:
                logger.warning(f"Error fetching LMPs data for LAP {id_lap}: {e}")
                
        except Exception as e:
            logger.error(f"Error processing LAP record {lap_record.get('id_lap', 'unknown')} for time spent: {str(e)}")

    async def _process_lap_lmps_data(self, lmps_data: List[Dict], participant, id_lap: str):
        """Process LMPs data for a specific LAP to update time spent information"""
        try:
            for lmp in lmps_data:
                # Extract time spent data
                time_spent = 0
                time_spent_raw = lmp.get('lms_tempspasse', '0') or '0'
                try:
                    time_spent = int(float(time_spent_raw)) if time_spent_raw else 0
                except (ValueError, TypeError):
                    time_spent = 0

                # Also check custom_properties for total_time_spent
                custom_properties = lmp.get('custom_properties', {})
                if isinstance(custom_properties, dict):
                    total_time_spent_raw = custom_properties.get('total_time_spent', '0') or '0'
                    try:
                        total_time_spent = int(float(total_time_spent_raw)) if total_time_spent_raw else 0
                        # Use the larger value between lms_tempspasse and total_time_spent
                        time_spent = max(time_spent, total_time_spent)
                    except (ValueError, TypeError):
                        pass

                # Parse started_at
                started_at = None
                started_at_raw = lmp.get('lms_started_at', '')
                if started_at_raw and started_at_raw.strip():
                    try:
                        started_at = datetime.strptime(
                            started_at_raw.strip(), 
                            '%Y-%m-%d %H:%M:%S'
                        )
                    except ValueError as e:
                        logger.warning(f"Invalid started_at date format in LMP data: {e}")

                # Parse completed_at
                completed_at = None
                completed_at_raw = lmp.get('lms_completed_at', '')
                if completed_at_raw and completed_at_raw.strip():
                    try:
                        completed_at = datetime.strptime(
                            completed_at_raw.strip(), 
                            '%Y-%m-%d %H:%M:%S'
                        )
                    except ValueError as e:
                        logger.warning(f"Invalid completed_at date format in LMP data: {e}")

                # Get module details
                id_lmp = lmp.get('id_lmp')
                id_lam = lmp.get('id_lam')
                
                if not id_lmp or not id_lam:
                    logger.debug(f"Skipping LMP - missing id_lmp or id_lam")
                    continue

                # Find the corresponding module in the database
                module = self.db.query(Module).filter(
                    Module.id_lmp == id_lmp,
                    Module.participant_id == participant.id
                ).first()

                if module:
                    # Update the module with time spent data
                    module.lms_time_spent = time_spent
                    module.lms_started_at = started_at
                    module.lms_completed_at = completed_at
                    module.updated_at = datetime.utcnow()
                    
                    if time_spent > 0:
                        logger.debug(f"Updated module {id_lmp} for participant {participant.id_participant} with time spent: {time_spent}s")
                    else:
                        logger.debug(f"Updated module {id_lmp} for participant {participant.id_participant} (no time spent data)")
                else:
                    logger.debug(f"Module {id_lmp} not found for participant {participant.id_participant}")

        except Exception as e:
            logger.error(f"Error processing LMPs data for LAP {id_lap}: {e}")
            raise

    async def _create_participant_courses(self, participant_course_modules: Dict):
        """Create or update participant course records"""
        for (participant_id, course_id), module_data in participant_course_modules.items():
            try:
                # Calculate overall progression
                progressions = [data[1] for data in module_data]  # data[1] is progression
                overall_progression = sum(progressions) / len(progressions) if progressions else 0.0
                
                # Get last activity
                last_activities = [data[2] for data in module_data if data[2]]  # data[2] is last_access
                last_activity = max(last_activities) if last_activities else None
                
                # Determine activity status
                activity_status = "inactive"
                if overall_progression >= 100:
                    activity_status = "completed"
                elif last_activity:
                    days_since_access = (datetime.utcnow() - last_activity).days
                    if days_since_access <= 30:
                        activity_status = "active"
                
                # Create or update participant course record
                participant_course = self.db.query(ParticipantCourse).filter(
                    ParticipantCourse.participant_id == participant_id,
                    ParticipantCourse.course_id == course_id
                ).first()
                
                if participant_course:
                    # Update existing record
                    participant_course.overall_progression = overall_progression
                    participant_course.activity_status = activity_status
                    participant_course.last_activity = last_activity
                    participant_course.updated_at = datetime.utcnow()
                    self.stats["participant_courses_updated"] += 1
                else:
                    # Create new record
                    participant_course = ParticipantCourse(
                        participant_id=participant_id,
                        course_id=course_id,
                        overall_progression=overall_progression,
                        activity_status=activity_status,
                        last_activity=last_activity
                    )
                    self.db.add(participant_course)
                    self.stats["participant_courses_created"] += 1
                    
            except Exception as e:
                logger.error(f"Error creating/updating participant course for participant {participant_id}, course {course_id}: {str(e)}")
                continue

    async def _cleanup_removed_participants(self, active_courses: Dict[str, Course], current_participant_courses: set):
        """Remove participants who are no longer in courses"""
        try:
            logger.info("Starting cleanup of removed participants...")
            
            # Get all current participant course records
            existing_participant_courses = self.db.query(ParticipantCourse).all()
            
            # Track what should be removed
            removed_participant_courses = 0
            removed_modules = 0
            
            # ULTRA CONSERVATIVE APPROACH: Only remove if we have explicit evidence
            # that the participant is no longer enrolled AND the course is no longer active
            
            for pc in existing_participant_courses:
                # Check if this participant-course combination is still active
                if (pc.participant_id, pc.course_id) not in current_participant_courses:
                    course = self.db.query(Course).filter(Course.id == pc.course_id).first()
                    
                    # Only remove if:
                    # 1. Course is no longer active (not in active_courses)
                    # 2. AND participant has no modules in this course
                    if course and course.id_lam not in active_courses:
                        # Course is no longer active, check if participant has modules
                        module_count = self.db.query(Module).filter(
                            Module.participant_id == pc.participant_id,
                            Module.course_id == pc.course_id
                        ).count()
                        
                        if module_count == 0:
                            logger.info(f"Removing participant {pc.participant_id} from inactive course {pc.course_id} (no modules found)")
                            
                            # Remove the participant course record
                            self.db.delete(pc)
                            removed_participant_courses += 1
                        else:
                            logger.debug(f"Keeping participant {pc.participant_id} in inactive course {pc.course_id} (has {module_count} modules)")
                    else:
                        # Course is still active, don't remove anything
                        logger.debug(f"Keeping participant {pc.participant_id} in active course {pc.course_id}")
            
            # Update stats
            self.stats["participant_courses_removed"] = removed_participant_courses
            self.stats["modules_removed"] = removed_modules
            
            logger.info(f"Cleanup completed: {removed_participant_courses} participant courses removed (ultra conservative approach)")
            
        except Exception as e:
            logger.error(f"Error during cleanup: {str(e)}")
            self.db.rollback()
            raise

    async def _cleanup_orphaned_participants(self):
        """Remove participants who are no longer enrolled in any courses"""
        try:
            logger.info("Checking for orphaned participants...")
            
            # Find participants who have no remaining participant_course records
            orphaned_participants = self.db.query(Participant).outerjoin(
                ParticipantCourse
            ).filter(
                ParticipantCourse.id.is_(None)
            ).all()
            
            removed_participants = 0
            for participant in orphaned_participants:
                # ULTRA CONSERVATIVE: Only remove if participant has no modules AND no HubSpot data
                # This prevents removing participants who might be enrolled but don't have modules yet
                module_count = self.db.query(Module).filter(
                    Module.participant_id == participant.id
                ).count()
                
                hubspot_count = self.db.query(ParticipantHubspotData).filter(
                    ParticipantHubspotData.participant_id == participant.id
                ).count()
                
                # Only remove if participant has no modules AND no HubSpot data
                if module_count == 0 and hubspot_count == 0:
                    # Clean up creneau_participants FK references before deleting
                    creneau_deleted = self.db.query(CreneauParticipant).filter(
                        CreneauParticipant.participant_id == participant.id
                    ).delete()
                    if creneau_deleted:
                        logger.info(f"Cleared {creneau_deleted} creneau_participant records for participant {participant.id_participant}")

                    logger.info(f"Removing orphaned participant: {participant.id_participant} ({participant.email}) - no modules and no HubSpot data")
                    self.db.delete(participant)
                    removed_participants += 1
                else:
                    logger.debug(f"Keeping participant {participant.id_participant} ({participant.email}) - has {module_count} modules and {hubspot_count} HubSpot records")
            
            # Update stats
            self.stats["participants_removed"] = removed_participants
            
            logger.info(f"Orphaned participants cleanup completed: {removed_participants} participants removed (ultra conservative approach)")
            
        except Exception as e:
            logger.error(f"Error during orphaned participants cleanup: {str(e)}")
            self.db.rollback()
            raise

    async def _cleanup_orphaned_courses(self, active_courses: Dict[str, Course]):
        """Remove courses that are no longer active"""
        try:
            logger.info("Checking for orphaned courses...")
            
            # Get all courses that are not in the active courses list
            all_courses = self.db.query(Course).all()
            active_course_ids = {course.id for course in active_courses.values()}
            
            removed_courses = 0
            for course in all_courses:
                if course.id not in active_course_ids:
                    # ULTRA CONSERVATIVE: Only remove if course has no modules AND no participant courses
                    # This prevents removing courses that might still have participants but no modules in current sync
                    module_count = self.db.query(Module).filter(
                        Module.course_id == course.id
                    ).count()
                    
                    participant_course_count = self.db.query(ParticipantCourse).filter(
                        ParticipantCourse.course_id == course.id
                    ).count()
                    
                    # Only remove if course has no modules AND no participant courses
                    if module_count == 0 and participant_course_count == 0:
                        logger.info(f"Removing orphaned course: {course.intitule} (ID: {course.id}) - no modules and no participant courses")
                        
                        # Remove the course
                        self.db.delete(course)
                        removed_courses += 1
                    else:
                        logger.debug(f"Keeping course {course.intitule} (ID: {course.id}) - has {module_count} modules and {participant_course_count} participant courses")
            
            # Update stats
            self.stats["courses_removed"] = removed_courses
            
            logger.info(f"Orphaned courses cleanup completed: {removed_courses} courses removed (ultra conservative approach)")
            
        except Exception as e:
            logger.error(f"Error during orphaned courses cleanup: {str(e)}")
            self.db.rollback()
            raise

    async def _process_creneaux(self, creneaux_data: List[Dict], id_adf: str):
        """Process creneaux (liveroom session) data and LCP attendance records for an ADF"""
        for creneau_data in creneaux_data:
            id_creneau = creneau_data.get('id_creneau')
            if not id_creneau:
                continue

            # Parse dates
            date_debut = None
            date_debut_raw = creneau_data.get('date_debut', '')
            if date_debut_raw and date_debut_raw.strip():
                try:
                    date_debut = datetime.strptime(date_debut_raw.strip(), '%Y-%m-%d %H:%M:%S')
                except ValueError:
                    pass

            date_fin = None
            date_fin_raw = creneau_data.get('date_fin', '')
            if date_fin_raw and date_fin_raw.strip():
                try:
                    date_fin = datetime.strptime(date_fin_raw.strip(), '%Y-%m-%d %H:%M:%S')
                except ValueError:
                    pass

            # Parse duration
            duration = 0
            try:
                duration = int(creneau_data.get('duration', 0))
            except (ValueError, TypeError):
                duration = 0

            # Upsert Creneau record
            creneau = self.db.query(Creneau).filter(Creneau.id_creneau == id_creneau).first()
            if creneau:
                creneau.id_action_formation = id_adf
                creneau.id_lam = creneau_data.get('id_lam')
                creneau.name = creneau_data.get('name', '')
                creneau.date_debut = date_debut
                creneau.date_fin = date_fin
                creneau.duration = duration
                creneau.id_salle_de_formation = creneau_data.get('id_salle_de_formation')
                creneau.updated_at = datetime.utcnow()
                self.stats["creneaux_updated"] += 1
            else:
                creneau = Creneau(
                    id_creneau=id_creneau,
                    id_action_formation=id_adf,
                    id_lam=creneau_data.get('id_lam'),
                    name=creneau_data.get('name', ''),
                    date_debut=date_debut,
                    date_fin=date_fin,
                    duration=duration,
                    id_salle_de_formation=creneau_data.get('id_salle_de_formation')
                )
                self.db.add(creneau)
                self.stats["creneaux_created"] += 1

            # Flush to get creneau.id for FK
            self.db.flush()

            # Process LCPs (attendance records)
            lcps = creneau_data.get('lcps', [])
            for lcp_data in lcps:
                id_lcp = lcp_data.get('id_lcp')
                if not id_lcp:
                    continue

                # Resolve participant Dendreo ID from nested lap.participant
                lap_data = lcp_data.get('lap', {})
                participant_data = lap_data.get('participant', {}) if lap_data else {}
                dendreo_participant_id = participant_data.get('id_participant') if participant_data else None

                # Resolve DB FK
                participant_id = None
                if dendreo_participant_id:
                    participant = self.db.query(Participant).filter(
                        Participant.id_participant == str(dendreo_participant_id)
                    ).first()
                    if participant:
                        participant_id = participant.id

                # Parse presence hours
                heures_presence = 0.0
                try:
                    heures_presence = float(lcp_data.get('heures_presence', 0))
                except (ValueError, TypeError):
                    pass

                heures_absence = 0.0
                try:
                    heures_absence = float(lcp_data.get('heures_absence', 0))
                except (ValueError, TypeError):
                    pass

                # Upsert CreneauParticipant
                cp = self.db.query(CreneauParticipant).filter(
                    CreneauParticipant.id_lcp == id_lcp
                ).first()

                if cp:
                    cp.id_creneau = id_creneau
                    cp.id_lmp = lcp_data.get('id_lmp')
                    cp.id_lap = lcp_data.get('id_lap')
                    cp.id_participant = str(dendreo_participant_id) if dendreo_participant_id else cp.id_participant
                    cp.participant_id = participant_id
                    cp.creneau_id = creneau.id
                    cp.presence = str(lcp_data.get('presence', ''))
                    cp.heures_presence = heures_presence
                    cp.heures_absence = heures_absence
                    cp.updated_at = datetime.utcnow()
                    self.stats["creneau_participants_updated"] += 1
                else:
                    cp = CreneauParticipant(
                        id_lcp=id_lcp,
                        id_creneau=id_creneau,
                        id_lmp=lcp_data.get('id_lmp'),
                        id_lap=lcp_data.get('id_lap'),
                        id_participant=str(dendreo_participant_id) if dendreo_participant_id else '',
                        participant_id=participant_id,
                        creneau_id=creneau.id,
                        presence=str(lcp_data.get('presence', '')),
                        heures_presence=heures_presence,
                        heures_absence=heures_absence
                    )
                    self.db.add(cp)
                    self.stats["creneau_participants_created"] += 1

    async def _process_lmps(self, lmp_batch: List[Dict], active_courses: Dict[str, Course]) -> set:
        """Process LMP data to create or update modules and participants"""
        # Track participant progressions per course
        participant_course_modules = {}  # {(participant_id, course_id): [(module_id, progression, last_access)]}
        
        for lmp in lmp_batch:
            try:
                # Extract mode_organisation for filtering
                mode_organisation = lmp.get('mode_organisation', '')
                
                # Check module data for mode_organisation if not found at root level
                if not mode_organisation:
                    module_data = lmp.get('module', {})
                    if isinstance(module_data, dict):
                        mode_organisation = module_data.get('mode_organisation', '')
                
                # Store mode_organisation as-is (empty string if not provided)
                if not mode_organisation:
                    mode_organisation = ''
                
                # Extract participant data
                participant_data = lmp.get('participant')
                if not participant_data:
                    logger.warning(f"Skipping LMP - missing participant data")
                    continue

                # Process participant
                participant = await self._get_or_create_participant(participant_data)
                if not participant:
                    continue
                
                # Get LMP details
                id_lmp = lmp.get('id_lmp')
                id_lam = lmp.get('id_lam')
                
                # Extract module intitule from the module data
                module_intitule = ''
                module_data = lmp.get('module', {})
                if isinstance(module_data, dict):
                    module_intitule = module_data.get('intitule', '')
                
                # Handle empty progression values safely
                progression_raw = lmp.get('lms_progression', 0)
                try:
                    progression = float(progression_raw) if progression_raw != '' else 0.0
                except (ValueError, TypeError):
                    progression = 0.0
                
                if not id_lmp or not id_lam:
                    logger.debug(f"Skipping LMP - missing id_lmp or id_lam")
                    continue
                
                # Check if this LMP corresponds to an active course
                course = active_courses.get(id_lam)
                if not course:
                    logger.debug(f"Skipping LMP {id_lmp} - no active course found for id_lam {id_lam}")
                    continue

                # Parse last access date from the main LMP record (not from module sub-object)
                last_access = None
                last_access_raw = lmp.get('lms_last_access_at', '')
                if last_access_raw and last_access_raw.strip():
                    try:
                        last_access = datetime.strptime(
                            last_access_raw.strip(), 
                            '%Y-%m-%d %H:%M:%S'
                        )
                    except ValueError as e:
                        logger.warning(f"Invalid date format in LMP data: {e}")
                
                # Parse time tracking data
                time_spent = 0
                time_spent_raw = lmp.get('lms_tempspasse', '0') or '0'
                try:
                    time_spent = int(float(time_spent_raw)) if time_spent_raw else 0
                except (ValueError, TypeError):
                    time_spent = 0

                # Also check custom_properties for total_time_spent
                custom_properties = lmp.get('custom_properties', {})
                if isinstance(custom_properties, dict):
                    total_time_spent_raw = custom_properties.get('total_time_spent', '0') or '0'
                    try:
                        total_time_spent = int(float(total_time_spent_raw)) if total_time_spent_raw else 0
                        # Use the larger value between lms_tempspasse and total_time_spent
                        time_spent = max(time_spent, total_time_spent)
                    except (ValueError, TypeError):
                        pass

                # Parse started_at
                started_at = None
                started_at_raw = lmp.get('lms_started_at', '')
                if started_at_raw and started_at_raw.strip():
                    try:
                        started_at = datetime.strptime(
                            started_at_raw.strip(), 
                            '%Y-%m-%d %H:%M:%S'
                        )
                    except ValueError as e:
                        logger.warning(f"Invalid started_at date format in LMP data: {e}")

                # Parse completed_at
                completed_at = None
                completed_at_raw = lmp.get('lms_completed_at', '')
                if completed_at_raw and completed_at_raw.strip():
                    try:
                        completed_at = datetime.strptime(
                            completed_at_raw.strip(), 
                            '%Y-%m-%d %H:%M:%S'
                        )
                    except ValueError as e:
                        logger.warning(f"Invalid completed_at date format in LMP data: {e}")
                
                # Parse planned duration from module data
                planned_duration_hours = 0.0
                module_data = lmp.get('module', {})
                if isinstance(module_data, dict):
                    duree_heures_raw = module_data.get('duree_heures', '0') or '0'
                    try:
                        planned_duration_hours = float(duree_heures_raw) if duree_heures_raw else 0.0
                    except (ValueError, TypeError):
                        planned_duration_hours = 0.0
                
                # Update course with planned duration if we have valid data
                if planned_duration_hours > 0:
                    course.planned_duration_hours = planned_duration_hours
                
                # Business rule validation: progression > 0 MUST have last_access_at
                if progression > 0 and not last_access:
                    logger.warning(f"Data inconsistency: LMP {id_lmp} has progression {progression} but no last_access_at. Skipping.")
                    continue

                # Create or update module
                module = self.db.query(Module).filter(
                    Module.id_lmp == id_lmp,
                    Module.participant_id == participant.id
                ).first()

                if module:
                    # Update existing module
                    module.lms_progression = progression
                    module.lms_last_access_at = last_access
                    module.mode_organisation = mode_organisation
                    module.intitule = module_intitule  # Update module title
                    module.lms_time_spent = time_spent
                    module.lms_started_at = started_at
                    module.lms_completed_at = completed_at
                    module.updated_at = datetime.utcnow()
                    self.stats['modules_updated'] += 1
                else:
                    # Create new module
                    module = Module(
                        id_lmp=id_lmp,
                        id_lam=id_lam,
                        intitule=module_intitule,  # Add module title
                        course_id=course.id,
                        participant_id=participant.id,
                        lms_progression=progression,
                        lms_last_access_at=last_access,
                        mode_organisation=mode_organisation,
                        lms_time_spent=time_spent,
                        lms_started_at=started_at,
                        lms_completed_at=completed_at
                    )
                    self.db.add(module)
                    self.stats['modules_created'] += 1

                # Track for participant course creation
                course_key = (participant.id, course.id)
                if course_key not in participant_course_modules:
                    participant_course_modules[course_key] = []
                participant_course_modules[course_key].append((
                    module.id if hasattr(module, 'id') else None,
                    progression,
                    last_access
                ))

            except Exception as e:
                logger.error(f"Error processing LMP: {e}")
                continue

        # Commit modules first
        try:
            self.db.commit()
        except Exception as e:
            logger.error(f"Error committing modules: {e}")
            self.db.rollback()
            return

        # Create or update participant courses
        await self._create_participant_courses(participant_course_modules)
        
        # Return the set of current participant-course combinations
        return set(participant_course_modules.keys())

    async def _get_or_create_participant(self, participant_data: Dict) -> Participant:
        """Get or create a participant"""
        try:
            # Try to get existing participant
            participant = self.db.query(Participant).filter(
                Participant.id_participant == participant_data.get('id_participant')
            ).first()
            
            if not participant:
                # Create new participant
                participant = Participant(
                    id_participant=participant_data.get('id_participant'),
                    nom=participant_data.get('nom', ''),
                    prenom=participant_data.get('prenom', ''),
                    email=participant_data.get('email', ''),
                    id_entreprise=participant_data.get('id_entreprise')
                )
                self.db.add(participant)
                try:
                    self.db.flush()  # Try to flush just this participant
                    self.stats["participants_created"] += 1
                    logger.debug(f"Created new participant: {participant.id_participant}")
                except Exception as e:
                    self.db.rollback()  # Rollback on error
                    # Try to get the participant again in case it was created by another process
                    participant = self.db.query(Participant).filter(
                        Participant.id_participant == participant_data.get('id_participant')
                    ).first()
                    if not participant:
                        raise  # Re-raise if we still can't find the participant
            else:
                # Update existing participant
                participant.nom = participant_data.get('nom', participant.nom)
                participant.prenom = participant_data.get('prenom', participant.prenom)
                participant.email = participant_data.get('email', participant.email)
                participant.id_entreprise = participant_data.get('id_entreprise', participant.id_entreprise)
                self.stats["participants_updated"] += 1
                logger.debug(f"Updated participant: {participant.id_participant}")
                
            return participant
            
        except Exception as e:
            logger.error(f"Error processing participant {participant_data.get('id_participant')}: {str(e)}")
            raise

    async def sync_all_data(self) -> Dict[str, Any]:
        """Sync all data from Dendreo API with batching"""
        try:
            logger.info("Starting full sync from Dendreo API")
            start_time = datetime.now()

            # Fetch data from API (now properly awaited)
            logger.info("Fetching data from API...")
            try:
                data = await self.client.get_lmps_data()
            except DendreoAPIError as e:
                return {
                    "status": "error",
                    "message": f"Failed to fetch data from Dendreo API: {str(e)}"
                }

            if not isinstance(data, list):
                error_msg = f"Invalid data received from Dendreo API. Expected list but got {type(data)}"
                logger.warning(error_msg)
                return {"status": "error", "message": error_msg}

            if not data:
                error_msg = "No data found in response"
                logger.warning(error_msg)
                return {"status": "error", "message": error_msg}

            logger.info(f"Received {len(data)} records from Dendreo")

            # Filter for e-learning only
            logger.info("Filtering e-learning modules...")
            elearning_records = self._filter_elearning_records(data)

            logger.info(f"Found {len(elearning_records)} records with e-learning modules")

            if not elearning_records:
                return {
                    "status": "success",
                    "message": "No e-learning records found",
                    "stats": {
                        "participants_created": 0,
                        "participants_updated": 0,
                        "courses_created": 0,
                        "courses_updated": 0,
                        "modules_created": 0,
                        "modules_updated": 0,
                        "participant_courses_created": 0,
                        "participant_courses_updated": 0
                    }
                }

            # Process data in batches
            batch_size = 50
            total_stats = {
                "participants_created": 0,
                "participants_updated": 0,
                "courses_created": 0,
                "courses_updated": 0,
                "modules_created": 0,
                "modules_updated": 0,
                "participant_courses_created": 0,
                "participant_courses_updated": 0
            }

            total_batches = (len(elearning_records) + batch_size - 1) // batch_size

            for batch_num in range(total_batches):
                start_idx = batch_num * batch_size
                end_idx = min((batch_num + 1) * batch_size, len(elearning_records))
                batch = elearning_records[start_idx:end_idx]

                logger.info(f"Processing batch {batch_num + 1}/{total_batches} ({len(batch)} records)")

                db = next(get_db())
                try:
                    processor = DataProcessor(db)
                    batch_stats = processor.process_dendreo_data(batch)
                    db.commit()

                    # Accumulate stats
                    for key in total_stats:
                        if key in batch_stats:
                            total_stats[key] += batch_stats[key]

                    logger.info(f"Batch {batch_num + 1} completed: {batch_stats}")

                except Exception as e:
                    error_msg = f"Error processing batch {batch_num + 1}: {str(e)}"
                    logger.error(error_msg)
                    db.rollback()
                    return {"status": "error", "message": error_msg}
                finally:
                    db.close()

            end_time = datetime.now()
            duration = (end_time - start_time).total_seconds()

            return {
                "status": "success",
                "message": f"Sync completed successfully in {duration:.2f} seconds",
                "stats": total_stats
            }

        except Exception as e:
            error_msg = f"Sync failed: {str(e)}"
            logger.error(error_msg)
            return {"status": "error", "message": error_msg}

    async def test_sync_small(self) -> Dict[str, Any]:
        """Test sync with a small dataset"""
        try:
            logger.info("Starting test sync with small dataset")

            # Read the test data file
            import json
            with open('elearning_test_data.json', 'r') as f:
                test_data = json.load(f)

            logger.info(f"Loaded {len(test_data)} test records")
            
            # Reset stats
            self.stats = {key: 0 for key in self.stats}
            
            # Create courses from LMP data first (since test data doesn't have ADF structure)
            active_courses = {}
            course_data = {}  # {id_lam: course_info}
            
            # Extract unique courses from LMP data
            for lmp in test_data:
                id_lam = lmp.get('id_lam')
                if id_lam and id_lam not in course_data:
                    # Create a mock ADF structure from LMP data
                    course_data[id_lam] = {
                        'id_action_de_formation': f"test_adf_{id_lam}",
                        'id_lam': id_lam,
                        'intitule': lmp.get('module', {}).get('intitule', f'Test Course {id_lam}'),
                        'id_etape_process': '5',  # Active status
                        'mode_organisation': lmp.get('module', {}).get('mode_organisation', 'elearning_async')
                    }
            
            logger.info(f"Found {len(course_data)} unique courses in test data")
            
            # Process courses
            for id_lam, adf_data in course_data.items():
                id_adf = adf_data['id_action_de_formation']
                
                # Create or update course
                course = self.db.query(Course).filter(Course.id_action_formation == id_adf).first()
                if not course:
                    course = Course(
                        id_action_formation=id_adf,
                        id_lam=id_lam,
                        intitule=adf_data['intitule'],
                        status=adf_data['id_etape_process'],
                        mode_organisation=adf_data['mode_organisation'],
                        total_modules=0
                    )
                    self.db.add(course)
                    self.stats["courses_created"] += 1
                    logger.debug(f"Created test course: {id_adf}")
                else:
                    course.id_lam = id_lam
                    course.intitule = adf_data['intitule']
                    course.status = adf_data['id_etape_process']
                    course.mode_organisation = adf_data['mode_organisation']
                    self.stats["courses_updated"] += 1
                    logger.debug(f"Updated test course: {id_adf}")
                
                active_courses[id_lam] = course
            
            # Commit courses first
            self.db.commit()
            
            # Process LMPs with the created courses
            await self._process_lmps(test_data, active_courses)

            return {
                "status": "success",
                "message": "Test sync completed",
                "stats": self.stats
            }

        except Exception as e:
            logger.error(f"Test sync failed: {str(e)}")
            self.db.rollback()
            raise