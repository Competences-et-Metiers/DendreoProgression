import logging
from typing import Dict, Any, List
from sqlalchemy.orm import Session
from app.models.models import Participant, Course, Module, ParticipantCourse
from datetime import datetime

logger = logging.getLogger(__name__)

class DataProcessor:
    def __init__(self, db: Session):
        self.db = db

    def process_dendreo_data(self, records: List[Dict[str, Any]]) -> Dict[str, int]:
        """Process Dendreo data and store in database"""
        try:
            stats = {
                'participants_created': 0,
                'participants_updated': 0,
                'courses_created': 0,
                'courses_updated': 0,
                'modules_created': 0,
                'modules_updated': 0,
                'participant_courses_created': 0,
                'participant_courses_updated': 0
            }

            logger.info(f"Processing {len(records)} records...")

            for i, record in enumerate(records):
                if i % 100 == 0:
                    logger.info(f"Processed {i}/{len(records)} records...")

                try:
                    # Process participant
                    participant_data = record.get('participant', {})
                    participant = self._process_participant(participant_data, stats)

                    # Find course using LAP -> ADF -> Course relationship
                    course = self._find_course_for_lmp(record, stats)
                    if not course:
                        logger.warning(f"Could not find course for LMP {record.get('id_lmp')}, LAP {record.get('id_lap')}, LAM {record.get('id_lam')}")
                        continue

                    # Process module
                    module = self._process_module(record, participant.id, course.id, stats)
                    
                    # Only process participant-course relationship if module was processed
                    if module:
                        # Process participant-course relationship
                        self._process_participant_course(participant.id, course.id, stats, record.get('id_lap'))

                    # Commit every 100 records to prevent memory issues
                    if i % 100 == 99:
                        self.db.commit()

                except Exception as e:
                    logger.error(f"Error processing record {i}: {e}")
                    continue

            # Final commit
            self.db.commit()
            logger.info(f"Processing completed. Stats: {stats}")
            return stats

        except Exception as e:
            logger.error(f"Error in process_dendreo_data: {e}")
            self.db.rollback()
            raise

    def _process_participant(self, participant_data: Dict[str, Any], stats: Dict[str, int]) -> Participant:
        """Process participant data"""
        email = participant_data.get('email', '').strip()
        if not email:
            raise ValueError("Participant email is required")

        # Find existing participant by email
        participant = self.db.query(Participant).filter(Participant.email == email).first()

        if not participant:
            # Create new participant
            participant = Participant(
                nom=participant_data.get('nom', ''),
                prenom=participant_data.get('prenom', ''),
                email=email,
                id_entreprise=participant_data.get('id_entreprise')
            )
            self.db.add(participant)
            self.db.flush()  # Get the ID
            stats['participants_created'] += 1
            logger.debug(f"Created participant: {email}")
        else:
            # Update existing participant
            participant.nom = participant_data.get('nom', participant.nom)
            participant.prenom = participant_data.get('prenom', participant.prenom)
            participant.id_entreprise = participant_data.get('id_entreprise', participant.id_entreprise)
            participant.updated_at = datetime.utcnow()
            stats['participants_updated'] += 1
            logger.debug(f"Updated participant: {email}")

        return participant

    def _process_course(self, course_data: Dict[str, Any], id_lmp: str, stats: Dict[str, int]) -> Course:
        """Process course data"""

        # Find existing course by intitule (since id_lmp is not a Course field)
        course = self.db.query(Course).filter(Course.intitule == course_data.get('intitule', '')).first()

        if not course:
            # Create new course (Course model doesn't have id_lmp field)
            course = Course(
                intitule=course_data.get('intitule', ''),
                id_action_formation=f"generated_adf_{id_lmp}",  # Generate a placeholder ADF ID
                id_lam=id_lmp,  # Use id_lmp as id_lam
                status='5'  # Default active status
            )
            self.db.add(course)
            self.db.flush()  # Get the ID
            stats['courses_created'] += 1
            logger.debug(f"Created course: {course.intitule}")
        else:
            # Update existing course
            course.intitule = course_data.get('intitule', course.intitule)
            course.updated_at = datetime.utcnow()
            stats['courses_updated'] += 1
            logger.debug(f"Updated course: {course.intitule}")

        return course

    def _find_course_for_lmp(self, record: Dict[str, Any], stats: Dict[str, int]) -> Course:
        """Find the correct course for an LMP record using LAP -> ADF -> Course relationship"""
        id_lap = record.get('id_lap')
        id_lam = record.get('id_lam')
        
        if not id_lap or not id_lam:
            logger.warning(f"Missing id_lap ({id_lap}) or id_lam ({id_lam}) in LMP record")
            return None
        
        # First, try to find course by existing ParticipantCourse relationship with id_lap
        participant_course = self.db.query(ParticipantCourse).filter(
            ParticipantCourse.id_lap == id_lap
        ).first()
        
        if participant_course:
            # Get the course from the existing relationship
            course = self.db.query(Course).filter(Course.id == participant_course.course_id).first()
            if course:
                logger.debug(f"Found course via existing ParticipantCourse: {course.id} for LAP {id_lap}")
                return course
        
        # If not found, try to find course by id_lam (module ID) 
        # This assumes the course was created by the sync process
        course = self.db.query(Course).filter(Course.id_lam == id_lam).first()
        if course:
            logger.debug(f"Found course by id_lam: {course.id} for LAM {id_lam}")
            return course
        
        # If still not found, create a placeholder course
        # This shouldn't happen in a properly synced system, but provides fallback
        module_data = record.get('module', {})
        course_title = module_data.get('intitule', f'Course for LAM {id_lam}')
        
        course = Course(
            id_lam=id_lam,
            intitule=course_title,
            id_action_formation=f'unknown_adf_for_lap_{id_lap}',
            status='5'  # Active
        )
        self.db.add(course)
        self.db.flush()  # Get the ID
        stats['courses_created'] += 1
        logger.warning(f"Created fallback course for LAM {id_lam}, LAP {id_lap}: {course.id}")
        
        return course

    def _process_module(self, record: Dict[str, Any], participant_id: int, course_id: int, stats: Dict[str, int]) -> Module:
        """Process module data"""
        id_lam = record.get('id_lam')
        id_lmp = record.get('id_lmp')

        # Get mode organisation and title from module data
        module_data = record.get('module', {})
        mode_organisation = module_data.get('mode_organisation', '')
        module_title = module_data.get('intitule', '')

        # Determine if this is an e-learning module (for progression tracking)
        is_elearning = mode_organisation == 'elearning_async'

        # Find existing module by id_lam AND participant_id (unique constraint)
        module = self.db.query(Module).filter(
            Module.id_lam == id_lam,
            Module.participant_id == participant_id
        ).first()

        # Parse progression - only for e-learning modules
        progression = 0.0
        if is_elearning:
            progression_str = record.get('lms_progression', '0') or '0'
            try:
                progression = float(progression_str) if progression_str else 0.0
            except (ValueError, TypeError):
                progression = 0.0

        # Parse last access
        last_access = None
        last_access_str = record.get('lms_last_access_at')
        if last_access_str:
            try:
                last_access = datetime.fromisoformat(last_access_str.replace('Z', '+00:00'))
            except:
                last_access = None

        # Parse time tracking data
        time_spent = 0
        time_spent_str = record.get('lms_tempspasse', '0') or '0'
        try:
            time_spent = int(float(time_spent_str)) if time_spent_str else 0
        except (ValueError, TypeError):
            time_spent = 0

        # Also check custom_properties for total_time_spent
        custom_properties = record.get('custom_properties', {})
        if isinstance(custom_properties, dict):
            total_time_spent_str = custom_properties.get('total_time_spent', '0') or '0'
            try:
                total_time_spent = int(float(total_time_spent_str)) if total_time_spent_str else 0
                # Use the larger value between lms_tempspasse and total_time_spent
                time_spent = max(time_spent, total_time_spent)
            except (ValueError, TypeError):
                pass

        # Parse started_at
        started_at = None
        started_at_str = record.get('lms_started_at')
        if started_at_str:
            try:
                started_at = datetime.fromisoformat(started_at_str.replace('Z', '+00:00'))
            except:
                started_at = None

        # Parse completed_at
        completed_at = None
        completed_at_str = record.get('lms_completed_at')
        if completed_at_str:
            try:
                completed_at = datetime.fromisoformat(completed_at_str.replace('Z', '+00:00'))
            except:
                completed_at = None

        if not module:
            # Create new module
            module = Module(
                id_lmp=id_lmp,
                id_lam=id_lam,
                intitule=module_title,
                course_id=course_id,
                participant_id=participant_id,
                lms_progression=progression if is_elearning else 0.0,
                lms_last_access_at=last_access,
                mode_organisation=mode_organisation,
                lms_time_spent=time_spent,
                lms_started_at=started_at,
                lms_completed_at=completed_at
            )
            self.db.add(module)
            self.db.flush()
            stats['modules_created'] += 1
            logger.debug(f"Created module: {id_lam} for participant {participant_id} with {time_spent}s ({'elearning' if is_elearning else 'non-elearning'})")
        else:
            # Update existing module - AGGREGATE data from multiple LMP entries
            # Take the highest progression (most complete) - only for e-learning modules
            if is_elearning and progression > (module.lms_progression or 0):
                module.lms_progression = progression
            
            # Take the latest last access date
            if last_access and (not module.lms_last_access_at or last_access > module.lms_last_access_at):
                module.lms_last_access_at = last_access
            
            # Keep mode_organisation and update title if missing
            module.mode_organisation = mode_organisation
            if not module.intitule and module_title:
                module.intitule = module_title
            
            # AGGREGATE time spent (add to existing time)
            module.lms_time_spent = (module.lms_time_spent or 0) + time_spent
            
            # Take the earliest started_at date
            if started_at and (not module.lms_started_at or started_at < module.lms_started_at):
                module.lms_started_at = started_at
            
            # Take the latest completed_at date  
            if completed_at and (not module.lms_completed_at or completed_at > module.lms_completed_at):
                module.lms_completed_at = completed_at
                
            module.updated_at = datetime.utcnow()
            stats['modules_updated'] += 1
            logger.debug(f"Aggregated module data: {id_lam} for participant {participant_id} - added {time_spent}s (total: {module.lms_time_spent}s) ({'elearning' if is_elearning else 'non-elearning'})")

        return module

    def _process_participant_course(self, participant_id: int, course_id: int, stats: Dict[str, int], id_lap: str = None):
        """Process participant-course relationship, optionally setting id_lap"""

        # Find existing relationship
        pc = self.db.query(ParticipantCourse).filter(
            ParticipantCourse.participant_id == participant_id,
            ParticipantCourse.course_id == course_id
        ).first()

        if not pc:
            # Create new relationship
            pc = ParticipantCourse(
                participant_id=participant_id,
                course_id=course_id,
                overall_progression=0.0,
                activity_status='active',
                id_lap=id_lap
            )
            self.db.add(pc)
            stats['participant_courses_created'] += 1
            logger.debug(f"Created participant-course relationship")
        else:
            # Update will happen later when we calculate progressions
            if id_lap:
                pc.id_lap = id_lap
            stats['participant_courses_updated'] += 1
