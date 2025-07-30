import logging
from typing import Dict, Any, List, Optional
from app.services.dendreo_client import DendreoClient, DendreoAPIError
from app.services.data_processor import DataProcessor
from app.models.database import get_db
from datetime import datetime
from sqlalchemy.orm import Session
from app.models.models import Participant, Course, Module, ParticipantCourse, ParticipantHubspotData
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
            "hubspot_updates_total": 0,
            "hubspot_updates_successful": 0,
            "hubspot_updates_failed": 0,
            "hubspot_status": "unknown",
            "hubspot_error": None
        }

    async def sync_all(self) -> Dict[str, Any]:
        """Synchronize all data from Dendreo"""
        try:
            logger.info("Starting full sync from Dendreo API")
            start_time = datetime.now()

            # Get all data from Dendreo
            lmps_data = await self.client.get_lmps()
            if not isinstance(lmps_data, list):
                logger.error(f"Invalid LMPs data type received: {type(lmps_data)}")
                return {
                    "status": "error",
                    "message": "Invalid LMPs data received from API"
                }
                
            adf_data = await self.client.get_actions_de_formation()
            if not isinstance(adf_data, list):
                logger.error(f"Invalid ADFs data type received: {type(adf_data)}")
                return {
                    "status": "error",
                    "message": "Invalid ADFs data received from API"
                }
            
            # Apply ADF limit if set
            if self.adf_limit:
                logger.info(f"Limiting total ADFs to {self.adf_limit} (DENDREO_ADF_LIMIT)")
                adf_data = adf_data[:self.adf_limit]
            
            # Filter for e-learning only
            logger.info("Filtering e-learning modules...")
            elearning_records = self._filter_elearning_records(lmps_data)
            logger.info(f"Found {len(elearning_records)} e-learning records")

            # Process ADFs in batches
            logger.info("Processing ADFs...")
            active_courses = {}
            adf_batches = [adf_data[i:i + self.batch_size] for i in range(0, len(adf_data), self.batch_size)]
            
            for batch_num, adf_batch in enumerate(adf_batches, 1):
                logger.info(f"Processing ADF batch {batch_num}/{len(adf_batches)}")
                batch_courses = await self._process_adfs(adf_batch)
                active_courses.update(batch_courses)
                self.db.commit()

            # Process LMPs in batches FIRST (to create ParticipantCourse records)
            logger.info("Processing LMPs...")
            lmp_batches = [elearning_records[i:i + self.batch_size] for i in range(0, len(elearning_records), self.batch_size)]
            
            # Track all current participant-course combinations
            all_current_participant_courses = set()
            
            for batch_num, lmp_batch in enumerate(lmp_batches, 1):
                logger.info(f"Processing LMP batch {batch_num}/{len(lmp_batches)}")
                batch_participant_courses = await self._process_lmps(lmp_batch, active_courses)
                all_current_participant_courses.update(batch_participant_courses)
                # Note: _process_lmps now handles its own commit

            # Process HubSpot data from LAPS AFTER LMPs (to update ParticipantCourse records with id_lap)
            logger.info("Processing HubSpot data from LAPS...")
            await self._process_hubspot_data(adf_data)
            self.db.commit()

            # Cleanup removed participants (only if enabled)
            if self.enable_cleanup:
                logger.info("Cleaning up removed participants...")
                await self._cleanup_removed_participants(active_courses, all_current_participant_courses)
                self.db.commit()

                # Cleanup orphaned participants
                logger.info("Cleaning up orphaned participants...")
                await self._cleanup_orphaned_participants()
                self.db.commit()

                # Cleanup orphaned courses
                logger.info("Cleaning up orphaned courses...")
                await self._cleanup_orphaned_courses(active_courses)
                self.db.commit()
            else:
                logger.info("🧹 Skipping cleanup (DENDREO_ENABLE_CLEANUP=false)")

            # Update HubSpot deals with progression data
            logger.info("🔄 Updating HubSpot deals with progression data...")
            try:
                # Import the function here to avoid circular imports
                from update_hubspot_progression import update_hubspot_progressions_for_sync
                
                hubspot_result = await update_hubspot_progressions_for_sync(self.db)
                
                # Add HubSpot stats to our sync stats
                self.stats["hubspot_updates_total"] = hubspot_result.get("total_processed", 0)
                self.stats["hubspot_updates_successful"] = hubspot_result.get("successful_updates", 0)
                self.stats["hubspot_updates_failed"] = hubspot_result.get("failed_updates", 0)
                self.stats["hubspot_status"] = hubspot_result.get("status", "unknown")
                
                if hubspot_result["status"] == "skipped":
                    logger.info("⏭️  HubSpot progression updates skipped (API key not configured)")
                elif hubspot_result["status"] == "error":
                    logger.warning(f"⚠️  HubSpot progression updates failed: {hubspot_result['message']}")
                else:
                    logger.info(f"✅ HubSpot progression updates completed: {hubspot_result['successful_updates']}/{hubspot_result['total_processed']} successful")
                    
            except Exception as e:
                logger.error(f"❌ Error during HubSpot progression updates: {str(e)}")
                # Don't fail the entire sync if HubSpot updates fail
                self.stats["hubspot_status"] = "error"
                self.stats["hubspot_error"] = str(e)

            end_time = datetime.now()
            duration = (end_time - start_time).total_seconds()

            logger.info(f"Sync completed successfully. Final stats: {self.stats}")
            return {
                "status": "success",
                "message": f"Sync completed successfully in {duration:.2f} seconds",
                "stats": self.stats
            }

        except Exception as e:
            logger.error(f"Error during sync: {str(e)}")
            self.db.rollback()
            raise

    def _filter_elearning_records(self, data: List[Dict]) -> List[Dict]:
        """Filter records for e-learning modules only"""
        filtered = []
        module_counts = {}  # {id_lam: count} to track e-learning modules per course
        
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
                
            # Check if it's an e-learning module
            is_elearning = False
            id_lam = record.get('id_lam')
            
            # Check module data first
            module_data = record.get('module', {})
            if isinstance(module_data, dict):
                if module_data.get('mode_organisation') == 'elearning_async':
                    is_elearning = True
            
            # Check root level if not found in module data
            if not is_elearning and record.get('mode_organisation') == 'elearning_async':
                is_elearning = True
                
            # Check custom properties if not found at other levels
            custom_props = record.get('custom_properties')
            if not is_elearning and isinstance(custom_props, dict):
                if custom_props.get('mode_organisation') == 'elearning_async':
                    is_elearning = True
                
            if is_elearning and id_lam:
                filtered.append(record)
                # Track module count for this course
                module_counts[id_lam] = module_counts.get(id_lam, 0) + 1
                logger.debug(f"Found e-learning module for LAM {id_lam}")
        
        # Update total_modules for each course
        for id_lam, count in module_counts.items():
            course = self.db.query(Course).filter(Course.id_lam == id_lam).first()
            if course:
                course.total_modules = count
                logger.debug(f"Updated course {course.id_action_formation} with {count} e-learning modules")
                
        logger.info(f"Filtered {len(filtered)} e-learning records from {len(data)} total records")
        return filtered

    async def _process_adfs(self, adf_batch: List[Dict]) -> Dict[str, Course]:
        """Process ADF data to create or update courses"""
        active_courses = {}
        
        for adf in adf_batch:
            # Only process active ADFs (status 5 or 6)
            id_etape_process = adf.get('id_etape_process')
            if not id_etape_process or id_etape_process not in ['5', '6']:
                logger.debug(f"Skipping inactive ADF with status {id_etape_process}")
                continue
                
            id_adf = adf.get('id_action_de_formation')
            if not id_adf:
                logger.warning("Skipping ADF - missing id_action_de_formation")
                continue
            
            # Get modules from the ADF
            modules = adf.get('modules', [])
            if not modules:
                logger.debug(f"ADF {id_adf} has no modules, skipping")
                continue
            
            # Process each module in the ADF
            for module in modules:
                id_lam = module.get('id_lam')
                if not id_lam:
                    logger.debug(f"Module in ADF {id_adf} missing id_lam, skipping")
                    continue
                
                # Create or update course for this module
                course = self.db.query(Course).filter(Course.id_action_formation == id_adf, Course.id_lam == id_lam).first()
                if not course:
                    course = Course(
                        id_action_formation=id_adf,
                        id_lam=id_lam,
                        intitule=adf.get('intitule', ''),
                        status=id_etape_process,
                        total_modules=0  # Will be updated when processing LMPs
                    )
                    self.db.add(course)
                    self.stats["courses_created"] += 1
                    logger.debug(f"Created new course: {id_adf} - {id_lam}")
                else:
                    course.intitule = adf.get('intitule', '')
                    course.status = id_etape_process
                    self.stats["courses_updated"] += 1
                    logger.debug(f"Updated course: {id_adf} - {id_lam}")
                
                # Store course by id_lam
                active_courses[id_lam] = course
            
        return active_courses

    async def _process_hubspot_data(self, adf_data: List[Dict]):
        """Process HubSpot data from LAPS for each ADF"""
        for adf in adf_data:
            id_adf = adf.get('id_action_de_formation')
            if not id_adf:
                continue
                
            # Only process active ADFs (status 5 or 6)
            id_etape_process = adf.get('id_etape_process')
            if not id_etape_process or id_etape_process not in ['5', '6']:
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
        """Process a single LAP record to extract and store HubSpot data and update id_lap on all relevant ParticipantCourse rows"""
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
            
            # Update id_lap on all ParticipantCourse rows for this participant and this ADF
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
                    pc.updated_at = datetime.utcnow()
                    updated_count += 1
                
                if updated_count > 0:
                    logger.debug(f"Updated {updated_count} ParticipantCourse records with id_lap {id_lap} for participant {participant.id_participant} in ADF {id_adf}")
                else:
                    logger.warning(f"No ParticipantCourse records found to update for participant {participant.id_participant} (DB ID {participant.id}) in ADF {id_adf}")
            else:
                logger.warning(f"No courses found for ADF {id_adf}")
            
            # Only process HubSpot data if it exists
            if c_url_transaction_hubspot or c_id_transaction_hubspot:
                # Create or update HubSpot data record
                hubspot_data = self.db.query(ParticipantHubspotData).filter(
                    ParticipantHubspotData.participant_id == participant.id,
                    ParticipantHubspotData.id_action_formation == id_adf
                ).first()
                
                if hubspot_data:
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
                            if hubspot_data:
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
                    logger.info(f"Removing orphaned participant: {participant.id_participant} ({participant.email}) - no modules and no HubSpot data")
                    
                    # Remove the participant
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
                
                # Skip non-elearning_async modules
                if mode_organisation and mode_organisation != 'elearning_async':
                    logger.debug(f"Skipping LMP - mode_organisation is '{mode_organisation}' (not elearning_async)")
                    continue
                
                # Default to elearning_async if no mode_organisation found (for existing data)
                if not mode_organisation:
                    mode_organisation = 'elearning_async'
                
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
                        mode_organisation=mode_organisation
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
                    email=participant_data.get('email', '')
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