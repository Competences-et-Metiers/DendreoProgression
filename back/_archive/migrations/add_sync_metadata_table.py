#!/usr/bin/env python3
"""
Add sync_metadata table to existing database
This script creates the sync_metadata table if it doesn't already exist.
"""

import sys
import logging
from pathlib import Path

# Add the app directory to the path
sys.path.append(str(Path(__file__).parent))

from app.config.settings import settings
from app.models.database import engine
from app.models.models import SyncMetadata
from sqlalchemy import text

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def add_sync_metadata_table():
    """Add sync_metadata table if it doesn't exist"""
    try:
        logger.info("Checking if sync_metadata table exists...")
        
        # Check if table exists
        with engine.connect() as connection:
            result = connection.execute(text(
                "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'sync_metadata')"
            ))
            table_exists = result.scalar()
            
            if table_exists:
                logger.info("✅ sync_metadata table already exists")
                return {"status": "exists", "message": "Table already exists"}
        
        logger.info("📋 Creating sync_metadata table...")
        
        # Create just the sync_metadata table
        SyncMetadata.__table__.create(engine)
        
        logger.info("✅ sync_metadata table created successfully")
        
        return {
            "status": "created",
            "message": "sync_metadata table created successfully"
        }
        
    except Exception as e:
        logger.error(f"❌ Error creating sync_metadata table: {e}")
        raise

if __name__ == "__main__":
    try:
        result = add_sync_metadata_table()
        print(f"\n🎉 {result['message']}")
        
    except Exception as e:
        print(f"\n❌ Failed to add table: {str(e)}")
        sys.exit(1) 