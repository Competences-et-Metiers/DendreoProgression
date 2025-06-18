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

                    # Process course
                    course_data = record.get('module', {})  # Module contains course info
                    course = self._process_course(course_data, record.get('id_lmp'), stats)

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
                email=email
            )
            self.db.add(participant)
            self.db.flush()  # Get the ID
            stats['participants_created'] += 1
            logger.debug(f"Created participant: {email}")
        else:
            # Update existing participant
            participant.nom = participant_data.get('nom', participant.nom)
            participant.prenom = participant_data.get('prenom', participant.prenom)
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

    def _process_module(self, record: Dict[str, Any], participant_id: int, course_id: int, stats: Dict[str, int]) -> Module:
        """Process module data"""
        id_lam = record.get('id_lam')

        # Get mode organisation from module data
        module_data = record.get('module', {})
        mode_organisation = module_data.get('mode_organisation', '')

        # Skip if not elearning_async
        if mode_organisation != 'elearning_async':
            logger.debug(f"Skipping module {id_lam} with mode_organisation: {mode_organisation}")
            return None

        # Find existing module by id_lam
        module = self.db.query(Module).filter(Module.id_lam == id_lam).first()

        # Parse progression
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

        if not module:
            # Create new module
            module = Module(
                id_lam=id_lam,
                course_id=course_id,
                participant_id=participant_id,
                lms_progression=progression,
                lms_last_access_at=last_access,
                mode_organisation=mode_organisation
            )
            self.db.add(module)
            self.db.flush()
            stats['modules_created'] += 1
            logger.debug(f"Created module: {id_lam}")
        else:
            # Update existing module
            module.lms_progression = progression
            module.lms_last_access_at = last_access
            module.mode_organisation = mode_organisation
            module.updated_at = datetime.utcnow()
            stats['modules_updated'] += 1
            logger.debug(f"Updated module: {id_lam}")

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
