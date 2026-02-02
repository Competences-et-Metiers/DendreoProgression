#!/usr/bin/env python3
"""
Test script to verify cleanup functionality
This script tests the new cleanup methods in the DendreoSync class.
"""

import sys
import logging
from pathlib import Path

# Add the app directory to the path
sys.path.append(str(Path(__file__).parent))

from app.config.settings import settings
from app.models.database import get_db
from app.models.models import Participant, Course, Module, ParticipantCourse, ParticipantHubspotData
from app.services.dendreo_client import DendreoClient
from app.services.dendreo_sync import DendreoSync
from sqlalchemy.orm import Session

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

async def test_cleanup_functionality():
    """Test the cleanup functionality"""
    try:
        logger.info("🧪 Testing cleanup functionality...")
        
        # Get database session
        db = next(get_db())
        
        # Create test data
        logger.info("📝 Creating test data...")
        
        # Create test participants
        participant1 = Participant(
            id_participant="TEST001",
            nom="Test",
            prenom="User1",
            email="test1@example.com"
        )
        participant2 = Participant(
            id_participant="TEST002",
            nom="Test",
            prenom="User2",
            email="test2@example.com"
        )
        db.add(participant1)
        db.add(participant2)
        db.flush()
        
        # Create test courses
        course1 = Course(
            id_action_formation="ADF001",
            id_lam="LAM001",
            intitule="Test Course 1",
            status="active"
        )
        course2 = Course(
            id_action_formation="ADF002",
            id_lam="LAM002",
            intitule="Test Course 2",
            status="active"
        )
        db.add(course1)
        db.add(course2)
        db.flush()
        
        # Create test modules
        module1 = Module(
            id_lmp="LMP001",
            id_lam="LAM001",
            intitule="Test Module 1",
            course_id=course1.id,
            participant_id=participant1.id,
            lms_progression=50.0
        )
        module2 = Module(
            id_lmp="LMP002",
            id_lam="LAM001",
            intitule="Test Module 2",
            course_id=course1.id,
            participant_id=participant1.id,
            lms_progression=75.0
        )
        db.add(module1)
        db.add(module2)
        db.flush()
        
        # Create test participant courses
        pc1 = ParticipantCourse(
            participant_id=participant1.id,
            course_id=course1.id,
            overall_progression=62.5,
            activity_status="active"
        )
        pc2 = ParticipantCourse(
            participant_id=participant2.id,
            course_id=course2.id,
            overall_progression=0.0,
            activity_status="inactive"
        )
        db.add(pc1)
        db.add(pc2)
        db.flush()
        
        # Create test HubSpot data
        hubspot_data = ParticipantHubspotData(
            participant_id=participant1.id,
            id_action_formation="ADF001",
            id_lap="LAP001",
            c_url_transaction_hubspot="https://example.com/deal/123",
            c_id_transaction_hubspot="123"
        )
        db.add(hubspot_data)
        db.commit()
        
        logger.info("✅ Test data created successfully")
        
        # Test cleanup functionality
        logger.info("🧹 Testing cleanup methods...")
        
        # Create DendreoSync instance
        client = DendreoClient()
        sync = DendreoSync(db, client)
        
        # Test orphaned courses cleanup
        logger.info("Testing orphaned courses cleanup...")
        active_courses = {course1.id_lam: course1}  # Only course1 is active
        await sync._cleanup_orphaned_courses(active_courses)
        
        # Check results
        remaining_courses = db.query(Course).all()
        logger.info(f"Remaining courses: {len(remaining_courses)}")
        
        # Test orphaned participants cleanup
        logger.info("Testing orphaned participants cleanup...")
        await sync._cleanup_orphaned_participants()
        
        # Check results
        remaining_participants = db.query(Participant).all()
        logger.info(f"Remaining participants: {len(remaining_participants)}")
        
        # Test removed participants cleanup
        logger.info("Testing removed participants cleanup...")
        current_participant_courses = {(participant1.id, course1.id)}  # Only participant1 in course1
        await sync._cleanup_removed_participants(active_courses, current_participant_courses)
        
        # Check results
        remaining_participant_courses = db.query(ParticipantCourse).all()
        logger.info(f"Remaining participant courses: {len(remaining_participant_courses)}")
        
        # Print final stats
        logger.info(f"📊 Final cleanup stats: {sync.stats}")
        
        # Clean up test data
        logger.info("🧹 Cleaning up test data...")
        db.query(ParticipantHubspotData).delete()
        db.query(Module).delete()
        db.query(ParticipantCourse).delete()
        db.query(Participant).delete()
        db.query(Course).delete()
        db.commit()
        
        logger.info("✅ Cleanup functionality test completed successfully")
        
    except Exception as e:
        logger.error(f"❌ Test failed: {str(e)}")
        db.rollback()
        raise

if __name__ == "__main__":
    import asyncio
    asyncio.run(test_cleanup_functionality()) 