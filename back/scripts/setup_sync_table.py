#!/usr/bin/env python3
"""
Setup Sync Metadata Table
Ensures the sync_metadata table exists in the database
"""

import sys
import os
from pathlib import Path

# Add the parent directory to the path so we can import from app
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.models.database import get_db_session, engine
from app.models.models import Base, SyncMetadata
from sqlalchemy import text
import logging

def setup_logging():
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )
    return logging.getLogger(__name__)

def create_sync_metadata_table():
    """Create sync_metadata table if it doesn't exist"""
    logger = setup_logging()
    
    try:
        logger.info("🔧 Checking if sync_metadata table exists...")
        
        # Create all tables defined in models
        Base.metadata.create_all(bind=engine)
        
        # Verify the table was created
        with get_db_session() as db:
            result = db.execute(text("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_schema = 'public' 
                    AND table_name = 'sync_metadata'
                );
            """)).fetchone()
            
            if result[0]:
                logger.info("✅ sync_metadata table exists")
                
                # Check if we have any test records
                count = db.query(SyncMetadata).filter(
                    SyncMetadata.sync_type == 'test_sync_cron'
                ).count()
                
                logger.info(f"📊 Found {count} test_sync_cron records")
                
                if count == 0:
                    # Create a test record to verify the table works
                    from datetime import datetime
                    test_record = SyncMetadata(
                        sync_type='table_setup_test',
                        last_sync_at=datetime.utcnow(),
                        status='success',
                        stats='{"message": "Table setup verification"}',
                    )
                    db.add(test_record)
                    db.commit()
                    logger.info("✅ Created test record successfully")
                
                return True
            else:
                logger.error("❌ sync_metadata table was not created")
                return False
                
    except Exception as e:
        logger.error(f"❌ Error setting up sync_metadata table: {e}")
        return False

def main():
    logger = setup_logging()
    logger.info("🚀 Setting up sync_metadata table...")
    
    success = create_sync_metadata_table()
    
    if success:
        logger.info("🎉 Setup completed successfully!")
        sys.exit(0)
    else:
        logger.error("💥 Setup failed!")
        sys.exit(1)

if __name__ == "__main__":
    main() 