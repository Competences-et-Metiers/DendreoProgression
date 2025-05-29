import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.models.database import get_db, engine
from app.models.models import Base, Participant, Course, Module
import json
import logging
from datetime import datetime

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def test_db_operations():
    """Test basic database operations"""

    # Create tables
    Base.metadata.create_all(bind=engine)

    # Get database session
    db = next(get_db())

    try:
        logger.info("Testing participant creation...")

        # Test creating a participant
        participant = Participant(
            nom="Test",
            prenom="User",
            email="test@example.com"
        )
        db.add(participant)
        db.flush()

        logger.info(f"Created participant with ID: {participant.id}")

        # Test creating a course
        course = Course(
            id_lmp="test_course_123",
            intitule="Test Course"
        )
        db.add(course)
        db.flush()

        logger.info(f"Created course with ID: {course.id}")

        # Test creating a module
        module = Module(
            id_lam="test_module_123",
            course_id=course.id,
            participant_id=participant.id,
            lms_progression=50.0,
            mode_organisation="elearning_async"
        )
        db.add(module)
        db.flush()

        logger.info(f"Created module with ID: {module.id}")

        # Commit
        db.commit()
        logger.info("All operations committed successfully!")

        # Test querying
        participants = db.query(Participant).all()
        courses = db.query(Course).all()
        modules = db.query(Module).all()

        logger.info(f"Found {len(participants)} participants, {len(courses)} courses, {len(modules)} modules")

    except Exception as e:
        logger.error(f"Database error: {e}")
        db.rollback()
    finally:
        db.close()

def test_single_record_processing():
    """Test processing a single record"""

    # Load test data if it exists
    try:
        with open('elearning_test_data.json', 'r') as f:
            test_data = json.load(f)

        if len(test_data) == 0:
            logger.error("No test data found")
            return

        record = test_data[0]
        logger.info("Testing single record processing...")

        db = next(get_db())

        try:
            # Extract participant data
            participant_data = record.get('participant', {})
            email = participant_data.get('email')

            logger.info(f"Processing participant: {email}")

            # Check if participant exists
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
                logger.info(f"Found existing participant: {email}")

            # Process course
            id_lmp = record.get('id_lmp')
            course = db.query(Course).filter(Course.id_lmp == id_lmp).first()

            if not course:
                module_data = record.get('module', {})
                course = Course(
                    id_lmp=id_lmp,
                    intitule=module_data.get('intitule', 'Unknown Course')
                )
                db.add(course)
                db.flush()
                logger.info(f"Created course: {id_lmp}")
            else:
                logger.info(f"Found existing course: {id_lmp}")

            # Process module
            id_lam = record.get('id_lam')
            module = db.query(Module).filter(Module.id_lam == id_lam).first()

            if not module:
                progression = 0.0
                lms_progression_raw = record.get('lms_progression', '')
                if lms_progression_raw and lms_progression_raw.strip():
                    try:
                        progression = float(lms_progression_raw)
                    except ValueError:
                        pass

                module = Module(
                    id_lam=id_lam,
                    course_id=course.id,
                    participant_id=participant.id,
                    lms_progression=progression,
                    mode_organisation=record.get('module', {}).get('mode_organisation', '')
                )
                db.add(module)
                db.flush()
                logger.info(f"Created module: {id_lam}")
            else:
                logger.info(f"Found existing module: {id_lam}")

            db.commit()
            logger.info("Single record processing completed successfully!")

        except Exception as e:
            logger.error(f"Error processing single record: {e}")
            db.rollback()
        finally:
            db.close()

    except FileNotFoundError:
        logger.error("No test data file found. Run test_small_sync.py first.")

if __name__ == "__main__":
    print("1. Testing database operations...")
    test_db_operations()

    print("\n2. Testing single record processing...")
    test_single_record_processing()
