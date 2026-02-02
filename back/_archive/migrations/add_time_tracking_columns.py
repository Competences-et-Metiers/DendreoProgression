#!/usr/bin/env python3
"""
Add time tracking columns to modules table
This script adds the time tracking columns to the modules table if they don't already exist.
"""

import sys
import logging
from pathlib import Path

# Add the app directory to the path
sys.path.append(str(Path(__file__).parent))

from app.config.settings import settings
from app.models.database import engine
from sqlalchemy import text

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def add_time_tracking_columns():
    """Add time tracking columns to modules table if they don't exist"""
    try:
        logger.info("Checking if time tracking columns exist in modules table...")
        
        # Check if columns exist
        with engine.connect() as connection:
            result = connection.execute(text("""
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_name = 'modules' AND column_name IN ('lms_time_spent', 'lms_started_at', 'lms_completed_at')
            """))
            existing_columns = {row[0] for row in result.fetchall()}
            
            columns_to_add = []
            if 'lms_time_spent' not in existing_columns:
                columns_to_add.append("ADD COLUMN lms_time_spent INTEGER DEFAULT 0")
            if 'lms_started_at' not in existing_columns:
                columns_to_add.append("ADD COLUMN lms_started_at TIMESTAMP WITH TIME ZONE")
            if 'lms_completed_at' not in existing_columns:
                columns_to_add.append("ADD COLUMN lms_completed_at TIMESTAMP WITH TIME ZONE")
            
            if not columns_to_add:
                logger.info("✅ All time tracking columns already exist in modules table")
                return {"status": "exists", "message": "All columns already exist"}
        
        logger.info("📋 Adding time tracking columns to modules table...")
        
        # Add the columns
        with engine.connect() as connection:
            for column_sql in columns_to_add:
                connection.execute(text(f"ALTER TABLE modules {column_sql}"))
            connection.commit()
        
        logger.info("✅ Time tracking columns added successfully to modules table")
        
        return {
            "status": "created",
            "message": "Time tracking columns added successfully to modules table"
        }
        
    except Exception as e:
        logger.error(f"❌ Error adding time tracking columns: {e}")
        raise

if __name__ == "__main__":
    try:
        result = add_time_tracking_columns()
        print(f"\n🎉 {result['message']}")
        
    except Exception as e:
        print(f"\n❌ Failed to add columns: {str(e)}")
        sys.exit(1) 