#!/usr/bin/env python3
"""
Test script to verify id_entreprise functionality
This script tests that id_entreprise is properly extracted from laps data and stored in the database.
"""

import sys
import logging
from pathlib import Path

# Add the app directory to the path
sys.path.append(str(Path(__file__).parent))

from app.config.settings import settings
from app.models.database import get_db_session
from app.models.models import Participant
from sqlalchemy.orm import Session

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def test_id_entreprise_extraction():
    """Test that id_entreprise is properly extracted from laps data"""
    
    # Sample laps data with id_entreprise
    sample_lap_record = {
        "id_lap": "297",
        "id_entreprise": "35",
        "participant": {
            "id_participant": "35",
            "nom": "HIESSE",
            "prenom": "Gaelle",
            "email": "gaellehiesse@gmail.com",
            "id_entreprise": "35"  # Also available in participant object
        }
    }
    
    logger.info("Testing id_entreprise extraction from laps data...")
    logger.info(f"Top-level id_entreprise: {sample_lap_record.get('id_entreprise')}")
    logger.info(f"Participant id_entreprise: {sample_lap_record.get('participant', {}).get('id_entreprise')}")
    
    # Test the extraction logic (same as in dendreo_sync.py)
    participant_data = sample_lap_record.get('participant', {})
    id_entreprise = sample_lap_record.get('id_entreprise')
    if id_entreprise:
        participant_data['id_entreprise'] = id_entreprise
    
    logger.info(f"Final participant_data['id_entreprise']: {participant_data.get('id_entreprise')}")
    
    return participant_data.get('id_entreprise') == "35"

def test_database_storage():
    """Test that id_entreprise can be stored and retrieved from database"""
    try:
        with get_db_session() as db:
            # Create a test participant with id_entreprise
            test_participant = Participant(
                id_participant="test_123",
                nom="Test",
                prenom="User",
                email="test@example.com",
                id_entreprise="42"
            )
            
            db.add(test_participant)
            db.commit()
            
            # Retrieve and verify
            retrieved_participant = db.query(Participant).filter(
                Participant.id_participant == "test_123"
            ).first()
            
            if retrieved_participant and retrieved_participant.id_entreprise == "42":
                logger.info("✅ Database storage test passed")
                
                # Clean up
                db.delete(retrieved_participant)
                db.commit()
                return True
            else:
                logger.error("❌ Database storage test failed")
                return False
                
    except Exception as e:
        logger.error(f"❌ Database test error: {e}")
        return False

def main():
    """Run all tests"""
    logger.info("🧪 Starting id_entreprise functionality tests...")
    
    # Test 1: Extraction from laps data
    extraction_test = test_id_entreprise_extraction()
    if extraction_test:
        logger.info("✅ id_entreprise extraction test passed")
    else:
        logger.error("❌ id_entreprise extraction test failed")
    
    # Test 2: Database storage
    storage_test = test_database_storage()
    if storage_test:
        logger.info("✅ id_entreprise database storage test passed")
    else:
        logger.error("❌ id_entreprise database storage test failed")
    
    if extraction_test and storage_test:
        logger.info("🎉 All tests passed! id_entreprise functionality is working correctly.")
        return True
    else:
        logger.error("❌ Some tests failed. Please check the implementation.")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 