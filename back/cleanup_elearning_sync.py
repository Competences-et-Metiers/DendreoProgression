#!/usr/bin/env python3
"""
Database cleanup script to remove all elearning_sync courses and related data
"""

import logging
from sqlalchemy.orm import Session
from app.models.database import get_db, engine
from app.models.models import Participant, Course, Module, ParticipantCourse
from sqlalchemy import text

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def cleanup_elearning_sync_data():
    """Remove all elearning_sync courses and related data from the database"""
    db = next(get_db())
    
    try:
        logger.info("Starting cleanup of elearning_sync data...")
        
        # First, let's see what we're dealing with
        sync_courses = db.query(Course).filter(Course.mode_organisation == 'elearning_sync').all()
        sync_course_ids = [course.id for course in sync_courses]
        
        if not sync_courses:
            logger.info("No elearning_sync courses found in database")
            return
        
        logger.info(f"Found {len(sync_courses)} elearning_sync courses to clean up")
        
        # Also check for modules with elearning_sync mode_organisation
        sync_modules = db.query(Module).filter(Module.mode_organisation == 'elearning_sync').all()
        sync_module_ids = [module.id for module in sync_modules]
        
        logger.info(f"Found {len(sync_modules)} elearning_sync modules to clean up")
        
        # Step 1: Delete ParticipantCourse records for elearning_sync courses
        participant_courses_deleted = 0
        if sync_course_ids:
            participant_courses_deleted = db.query(ParticipantCourse).filter(
                ParticipantCourse.course_id.in_(sync_course_ids)
            ).count()
            
            db.query(ParticipantCourse).filter(
                ParticipantCourse.course_id.in_(sync_course_ids)
            ).delete(synchronize_session=False)
            
            logger.info(f"Deleted {participant_courses_deleted} ParticipantCourse records")
        
        # Step 2: Delete Module records for elearning_sync courses OR with elearning_sync mode
        modules_deleted = 0
        
        # Delete modules linked to elearning_sync courses
        if sync_course_ids:
            modules_by_course = db.query(Module).filter(
                Module.course_id.in_(sync_course_ids)
            ).count()
            
            db.query(Module).filter(
                Module.course_id.in_(sync_course_ids)
            ).delete(synchronize_session=False)
            
            modules_deleted += modules_by_course
            logger.info(f"Deleted {modules_by_course} modules linked to elearning_sync courses")
        
        # Delete modules with elearning_sync mode_organisation
        modules_by_mode = db.query(Module).filter(
            Module.mode_organisation == 'elearning_sync'
        ).count()
        
        db.query(Module).filter(
            Module.mode_organisation == 'elearning_sync'
        ).delete(synchronize_session=False)
        
        modules_deleted += modules_by_mode
        logger.info(f"Deleted {modules_by_mode} modules with elearning_sync mode")
        
        # Step 3: Delete Course records with elearning_sync mode_organisation
        courses_deleted = db.query(Course).filter(
            Course.mode_organisation == 'elearning_sync'
        ).count()
        
        db.query(Course).filter(
            Course.mode_organisation == 'elearning_sync'
        ).delete(synchronize_session=False)
        
        logger.info(f"Deleted {courses_deleted} elearning_sync courses")
        
        # Step 4: Find and optionally delete participants who no longer have any courses
        orphaned_participants = db.execute(text("""
            SELECT p.id, p.id_participant, p.email
            FROM participants p
            LEFT JOIN modules m ON p.id = m.participant_id
            LEFT JOIN participant_courses pc ON p.id = pc.participant_id
            WHERE m.id IS NULL AND pc.id IS NULL
        """)).fetchall()
        
        if orphaned_participants:
            logger.info(f"Found {len(orphaned_participants)} participants with no remaining courses/modules")
            logger.info("Orphaned participants:")
            for participant in orphaned_participants:
                logger.info(f"  - ID: {participant.id}, Dendreo ID: {participant.id_participant}, Email: {participant.email}")
            
            # Uncomment the next lines if you want to delete orphaned participants
            # orphaned_ids = [p.id for p in orphaned_participants]
            # db.query(Participant).filter(Participant.id.in_(orphaned_ids)).delete(synchronize_session=False)
            # logger.info(f"Deleted {len(orphaned_participants)} orphaned participants")
        
        # Commit all changes
        db.commit()
        
        logger.info("✅ Cleanup completed successfully!")
        logger.info(f"Summary:")
        logger.info(f"  - ParticipantCourses deleted: {participant_courses_deleted}")
        logger.info(f"  - Modules deleted: {modules_deleted}")
        logger.info(f"  - Courses deleted: {courses_deleted}")
        logger.info(f"  - Orphaned participants found: {len(orphaned_participants)} (not deleted)")
        
        return {
            "status": "success",
            "participant_courses_deleted": participant_courses_deleted,
            "modules_deleted": modules_deleted,
            "courses_deleted": courses_deleted,
            "orphaned_participants": len(orphaned_participants)
        }
        
    except Exception as e:
        logger.error(f"Error during cleanup: {str(e)}")
        db.rollback()
        raise
    finally:
        db.close()

def get_elearning_sync_stats():
    """Get statistics about elearning_sync data in the database"""
    db = next(get_db())
    
    try:
        # Count elearning_sync courses
        sync_courses_count = db.query(Course).filter(Course.mode_organisation == 'elearning_sync').count()
        
        # Count modules with elearning_sync mode
        sync_modules_count = db.query(Module).filter(Module.mode_organisation == 'elearning_sync').count()
        
        # Count modules linked to elearning_sync courses
        sync_course_ids = [c.id for c in db.query(Course).filter(Course.mode_organisation == 'elearning_sync').all()]
        modules_in_sync_courses = 0
        if sync_course_ids:
            modules_in_sync_courses = db.query(Module).filter(Module.course_id.in_(sync_course_ids)).count()
        
        # Count participant courses linked to elearning_sync courses
        participant_courses_in_sync = 0
        if sync_course_ids:
            participant_courses_in_sync = db.query(ParticipantCourse).filter(ParticipantCourse.course_id.in_(sync_course_ids)).count()
        
        return {
            "elearning_sync_courses": sync_courses_count,
            "elearning_sync_modules": sync_modules_count,
            "modules_in_sync_courses": modules_in_sync_courses,
            "participant_courses_in_sync": participant_courses_in_sync
        }
        
    finally:
        db.close()

if __name__ == "__main__":
    print("🔍 Getting current elearning_sync statistics...")
    stats = get_elearning_sync_stats()
    print(f"Current elearning_sync data in database:")
    print(f"  - elearning_sync courses: {stats['elearning_sync_courses']}")
    print(f"  - elearning_sync modules: {stats['elearning_sync_modules']}")
    print(f"  - modules in sync courses: {stats['modules_in_sync_courses']}")
    print(f"  - participant courses in sync courses: {stats['participant_courses_in_sync']}")
    
    if stats['elearning_sync_courses'] > 0 or stats['elearning_sync_modules'] > 0:
        response = input("\n🗑️  Do you want to proceed with cleanup? (yes/no): ")
        if response.lower() in ['yes', 'y']:
            result = cleanup_elearning_sync_data()
            print(f"\n✅ Cleanup completed: {result}")
        else:
            print("❌ Cleanup cancelled")
    else:
        print("\n✅ No elearning_sync data found to clean up") 