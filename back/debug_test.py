import logging
import json
from sqlalchemy.orm import sessionmaker
from sqlalchemy import create_engine
from app.models.models import Participant, Course, Module, ParticipantCourse
from datetime import datetime

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Database setup
engine = create_engine('sqlite:///./dendreo_progression.db', echo=False)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def process_single_record():
    """Process exactly one record with correct field names"""

    with open('elearning_test_data.json', 'r') as f:
        test_data = json.load(f)

    record = test_data[0]
    logger.info(f"Processing record ID: {record.get('id_lmp')}")

    db = SessionLocal()

    try:
        # Step 1: Process participant
        participant_data = record.get('participant', {})
        email = participant_data.get('email', '').strip()

        participant = db.query(Participant).filter(Participant.email == email).first()

        if not participant:
            participant = Participant(
                nom=participant_data.get('nom', ''),
                prenom=participant_data.get('prenom', ''),
                email=email
            )
            db.add(participant)
            db.flush()
            logger.info(f"Created participant: {email}")
        else:
            logger.info(f"Found participant: {email}")

        # Step 2: Process course
        id_lmp = record.get('id_lmp')
        course_data = record.get('module', {})

        course = db.query(Course).filter(Course.id_lmp == id_lmp).first()

        if not course:
            course = Course(
                id_lmp=id_lmp,
                intitule=course_data.get('intitule', '')
            )
            db.add(course)
            db.flush()
            logger.info(f"Created course: {course.intitule}")
        else:
            logger.info(f"Found course: {course.intitule}")

        # Step 3: Process module
        id_lam = record.get('id_lam')

        module = db.query(Module).filter(Module.id_lam == id_lam).first()

        # Parse progression
        progression_str = record.get('lms_progression', '0') or '0'
        try:
            progression = float(progression_str)
        except:
            progression = 0.0

        if not module:
            module = Module(
                id_lam=id_lam,
                course_id=course.id,
                participant_id=participant.id,
                lms_progression=progression,
                mode_organisation=course_data.get('mode_organisation', '')
            )
            db.add(module)
            db.flush()
            logger.info(f"Created module: {id_lam}")
        else:
            logger.info(f"Found module: {id_lam}")

        # Step 4: Process participant-course relationship
        pc = db.query(ParticipantCourse).filter(
            ParticipantCourse.participant_id == participant.id,
            ParticipantCourse.course_id == course.id
        ).first()

        if not pc:
            pc = ParticipantCourse(
                participant_id=participant.id,
                course_id=course.id,
                overall_progression=0.0,
                activity_status='active'
            )
            db.add(pc)
            logger.info("Created participant-course relationship")
        else:
            logger.info("Found participant-course relationship")

        # Commit
        db.commit()
        logger.info("SUCCESS: Single record processed!")
        return True

    except Exception as e:
        logger.error(f"ERROR: {e}")
        db.rollback()
        return False
    finally:
        db.close()

if __name__ == "__main__":
    success = process_single_record()
    print(f"Result: {'SUCCESS' if success else 'FAILED'}")
