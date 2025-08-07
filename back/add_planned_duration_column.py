#!/usr/bin/env python3
"""
Database migration script to add planned_duration_hours column to courses table.
This script adds the planned_duration_hours column to store the duree_heures value from LMPs data.
"""

import logging
import sys
import os
from sqlalchemy import create_engine, text, inspect
from sqlalchemy.orm import sessionmaker

# Add the back directory to the Python path
sys.path.append(os.path.join(os.path.dirname(__file__), 'app'))

from app.config.settings import get_database_url

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def add_planned_duration_column():
    """Add planned_duration_hours column to courses table if it doesn't exist"""
    try:
        # Get database URL and create engine
        database_url = get_database_url()
        engine = create_engine(database_url)
        
        # Check if the column already exists
        inspector = inspect(engine)
        existing_columns = [col['name'] for col in inspector.get_columns('courses')]
        
        if 'planned_duration_hours' in existing_columns:
            logger.info("✅ planned_duration_hours column already exists in courses table")
            return {"status": "exists", "message": "Column already exists"}
        
        logger.info("📋 Adding planned_duration_hours column to courses table...")
        with engine.connect() as connection:
            connection.execute(text("ALTER TABLE courses ADD COLUMN planned_duration_hours FLOAT DEFAULT 0.0"))
            connection.commit()
        
        logger.info("✅ planned_duration_hours column added successfully to courses table")
        return {"status": "created", "message": "planned_duration_hours column added successfully to courses table"}
        
    except Exception as e:
        logger.error(f"❌ Error adding planned_duration_hours column: {e}")
        raise

if __name__ == "__main__":
    try:
        result = add_planned_duration_column()
        print(f"Migration result: {result}")
        sys.exit(0)
    except Exception as e:
        logger.error(f"Migration failed: {e}")
        sys.exit(1) 