#!/usr/bin/env python3
"""
Script to restore participants that were incorrectly removed during sync
This script helps identify and potentially restore participants who were removed incorrectly.
"""

import sys
import logging
from pathlib import Path
from datetime import datetime, timedelta

# Add the app directory to the path
sys.path.append(str(Path(__file__).parent))

from app.config.settings import settings
from app.models.database import get_db
from app.models.models import Participant, Course, Module, ParticipantCourse, ParticipantHubspotData, SyncMetadata
from sqlalchemy import text

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def analyze_removed_participants():
    """Analyze the sync metadata to understand what was removed"""
    try:
        logger.info("🔍 Analyzing sync metadata for removed participants...")
        
        db = next(get_db())
        
        # Get the most recent sync metadata
        latest_sync = db.query(SyncMetadata).filter(
            SyncMetadata.sync_type == 'sync_all'
        ).order_by(SyncMetadata.last_sync_at.desc()).first()
        
        if not latest_sync:
            logger.error("No sync metadata found")
            return
        
        logger.info(f"📊 Latest sync: {latest_sync.last_sync_at}")
        logger.info(f"📊 Sync status: {latest_sync.status}")
        
        if latest_sync.stats:
            import json
            try:
                stats = json.loads(latest_sync.stats)
                logger.info("📊 Sync Statistics:")
                logger.info(f"   - Participants removed: {stats.get('participants_removed', 0)}")
                logger.info(f"   - Participant courses removed: {stats.get('participant_courses_removed', 0)}")
                logger.info(f"   - Courses removed: {stats.get('courses_removed', 0)}")
                logger.info(f"   - Modules removed: {stats.get('modules_removed', 0)}")
            except json.JSONDecodeError:
                logger.error("Could not parse sync stats")
        
        # Check current database state
        current_participants = db.query(Participant).count()
        current_courses = db.query(Course).count()
        current_modules = db.query(Module).count()
        current_participant_courses = db.query(ParticipantCourse).count()
        
        logger.info("📊 Current Database State:")
        logger.info(f"   - Participants: {current_participants}")
        logger.info(f"   - Courses: {current_courses}")
        logger.info(f"   - Modules: {current_modules}")
        logger.info(f"   - Participant Courses: {current_participant_courses}")
        
        # Check for participants with modules but no participant_course records
        orphaned_modules = db.query(Module).outerjoin(
            ParticipantCourse, 
            (Module.participant_id == ParticipantCourse.participant_id) & 
            (Module.course_id == ParticipantCourse.course_id)
        ).filter(
            ParticipantCourse.id.is_(None)
        ).all()
        
        if orphaned_modules:
            logger.warning(f"⚠️  Found {len(orphaned_modules)} modules without participant_course records")
            logger.warning("This suggests participants were removed but their modules remain")
            
            # Group by participant and course
            orphaned_by_participant = {}
            for module in orphaned_modules:
                key = (module.participant_id, module.course_id)
                if key not in orphaned_by_participant:
                    orphaned_by_participant[key] = []
                orphaned_by_participant[key].append(module)
            
            logger.info(f"📋 Orphaned modules by participant-course combination:")
            for (participant_id, course_id), modules in orphaned_by_participant.items():
                participant = db.query(Participant).filter(Participant.id == participant_id).first()
                course = db.query(Course).filter(Course.id == course_id).first()
                
                if participant and course:
                    logger.info(f"   - Participant {participant.id_participant} ({participant.email}) in course {course.intitule}: {len(modules)} modules")
                else:
                    logger.warning(f"   - Missing participant {participant_id} or course {course_id}: {len(modules)} modules")
        
        # Check for participants with no courses but still have modules
        participants_with_modules_no_courses = db.query(Participant).join(
            Module, Participant.id == Module.participant_id
        ).outerjoin(
            ParticipantCourse, Participant.id == ParticipantCourse.participant_id
        ).filter(
            ParticipantCourse.id.is_(None)
        ).distinct(Participant.id).all()
        
        if participants_with_modules_no_courses:
            logger.warning(f"⚠️  Found {len(participants_with_modules_no_courses)} participants with modules but no course enrollments")
            for participant in participants_with_modules_no_courses:
                module_count = db.query(Module).filter(Module.participant_id == participant.id).count()
                logger.info(f"   - {participant.id_participant} ({participant.email}): {module_count} modules")
        
        logger.info("✅ Analysis completed")
        
    except Exception as e:
        logger.error(f"❌ Error during analysis: {str(e)}")
        raise

def suggest_restoration_actions():
    """Suggest actions to restore incorrectly removed participants"""
    logger.info("💡 Suggested Restoration Actions:")
    logger.info("")
    logger.info("1. **Immediate Actions:**")
    logger.info("   - Check if you have a database backup from before the sync")
    logger.info("   - If yes, restore from backup")
    logger.info("")
    logger.info("2. **If no backup available:**")
    logger.info("   - The new conservative cleanup logic should prevent future incorrect removals")
    logger.info("   - Run the next sync to see if the issue is resolved")
    logger.info("")
    logger.info("3. **Manual Restoration (if needed):**")
    logger.info("   - Check the logs for specific participants that were removed")
    logger.info("   - Manually recreate participant_course records for valid participants")
    logger.info("")
    logger.info("4. **Prevention:**")
    logger.info("   - The cleanup logic has been made more conservative")
    logger.info("   - It now only removes participants/courses that have no modules")
    logger.info("   - This should prevent future incorrect removals")

def main():
    """Main function"""
    try:
        logger.info("🔄 Participant Restoration Analysis Tool")
        logger.info("=" * 50)
        
        analyze_removed_participants()
        print()
        suggest_restoration_actions()
        
    except Exception as e:
        logger.error(f"❌ Script failed: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main() 