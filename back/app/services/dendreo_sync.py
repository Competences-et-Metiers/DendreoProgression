import logging
from typing import Dict, Any, List, Optional
from app.services.dendreo_client import DendreoClient, DendreoAPIError
from app.services.data_processor import DataProcessor
from app.models.database import get_db
from datetime import datetime
from sqlalchemy.orm import Session
from app.models.models import Participant, Course, Module, ParticipantCourse
import os

logger = logging.getLogger(__name__)

class DendreoSync:
    def __init__(self, db: Session, client: DendreoClient):
        self.db = db
        self.client = client
        self.batch_size = 50
        # Get ADF limit from environment variable, default to None (no limit)
        self.adf_limit = int(os.getenv('DENDREO_ADF_LIMIT', '0')) or None
        self.stats = {
            "participants_created": 0,
            "participants_updated": 0,
            "courses_created": 0,
            "courses_updated": 0,
            "modules_created": 0,
            "modules_updated": 0,
            "participant_courses_created": 0,
            "participant_courses_updated": 0
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

            # Process LMPs in batches
            logger.info("Processing LMPs...")
            lmp_batches = [elearning_records[i:i + self.batch_size] for i in range(0, len(elearning_records), self.batch_size)]
            
            for batch_num, lmp_batch in enumerate(lmp_batches, 1):
                logger.info(f"Processing LMP batch {batch_num}/{len(lmp_batches)}")
                await self._process_lmps(lmp_batch, active_courses)
                # Note: _process_lmps now handles its own commit

            # Final commit for any remaining changes
            try:
                self.db.commit()
                logger.info("Final commit completed successfully")
            except Exception as e:
                logger.error(f"Error in final commit: {str(e)}")
                self.db.rollback()
                raise

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
                
                # Get LAPS data for HubSpot information
                laps_data = await self.client.get_laps(id_adf)
                
                # Extract HubSpot data
                hubspot_url = ''
                hubspot_id = ''
                if laps_data:
                    hubspot_url = laps_data.get('c_url_transaction_hubspot', '')
                    hubspot_id = laps_data.get('c_id_transaction_hubspot', '')
                
                # Create or update course for this module
                course = self.db.query(Course).filter(Course.id_action_formation == id_adf, Course.id_lam == id_lam).first()
                if not course:
                    course = Course(
                        id_action_formation=id_adf,
                        id_lam=id_lam,
                        intitule=adf.get('intitule', ''),
                        status=id_etape_process,
                        mode_organisation=adf.get('mode_organisation', ''),
                        hubspot_transaction_url=hubspot_url,
                        hubspot_transaction_id=hubspot_id,
                        total_modules=0  # Will be updated when processing LMPs
                    )
                    self.db.add(course)
                    self.stats["courses_created"] += 1
                    logger.debug(f"Created new course: {id_adf} - {id_lam}")
                else:
                    course.intitule = adf.get('intitule', '')
                    course.status = id_etape_process
                    course.mode_organisation = adf.get('mode_organisation', '')
                    course.hubspot_transaction_url = hubspot_url
                    course.hubspot_transaction_id = hubspot_id
                    self.stats["courses_updated"] += 1
                    logger.debug(f"Updated course: {id_adf} - {id_lam}")
                
                # Store course by id_lam
                active_courses[id_lam] = course
            
        return active_courses

    async def _process_lmps(self, lmp_batch: List[Dict], active_courses: Dict[str, Course]):
        """Process LMP data to create or update modules and participants"""
        # Track participant progressions per course
        participant_course_modules = {}  # {(participant_id, course_id): [(module_id, progression, last_access)]}
        
        for lmp in lmp_batch:
            try:
                # Filter out elearning_sync courses
                mode_organisation = lmp.get('mode_organisation', '')
                if mode_organisation == 'elearning_sync':
                    logger.debug(f"Skipping LMP - elearning_sync mode not allowed")
                    continue
                
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
                progression = float(lmp.get('lms_progression', 0))
                
                if not id_lmp or not id_lam:
                    logger.debug(f"Skipping LMP - missing id_lmp or id_lam")
                    continue
                
                # Check if this LMP corresponds to an active course
                course = active_courses.get(id_lam)
                if not course:
                    logger.debug(f"Skipping LMP {id_lmp} - no active course found for id_lam {id_lam}")
                    continue

                # Parse last access date
                last_access = None
                module_data = lmp.get('module', {})
                if module_data and module_data.get('lms_last_access_at'):
                    try:
                        last_access = datetime.strptime(
                            module_data['lms_last_access_at'], 
                            '%Y-%m-%d %H:%M:%S'
                        )
                    except ValueError as e:
                        logger.warning(f"Invalid date format in module data: {e}")

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
                    module.updated_at = datetime.utcnow()
                    self.stats['modules_updated'] += 1
                else:
                    # Create new module
                    module = Module(
                        id_lmp=id_lmp,
                        id_lam=id_lam,
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
                        hubspot_transaction_url='',
                        hubspot_transaction_id='',
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