#!/usr/bin/env python3
"""
Complete database migration script for time tracking and planned duration features.
This script adds:
1. Time tracking columns to modules table (lms_time_spent, lms_started_at, lms_completed_at)
2. Planned duration column to courses table (planned_duration_hours)

This script is designed to be run in Docker containers and is idempotent.
"""

import logging
import sys
import os
from sqlalchemy import create_engine, text, inspect
from sqlalchemy.orm import sessionmaker

# Add the back directory to the Python path
sys.path.append(os.path.join(os.path.dirname(__file__), 'app'))

from app.config.settings import settings

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def check_column_exists(engine, table_name, column_name):
    """Check if a column exists in a table"""
    try:
        inspector = inspect(engine)
        existing_columns = [col['name'] for col in inspector.get_columns(table_name)]
        return column_name in existing_columns
    except Exception as e:
        logger.error(f"Error checking column {column_name} in table {table_name}: {e}")
        return False

def add_time_tracking_columns(engine):
    """Add time tracking columns to modules table if they don't exist"""
    try:
        logger.info("🔍 Checking time tracking columns in modules table...")
        
        columns_to_add = []
        
        # Check each column
        if not check_column_exists(engine, 'modules', 'lms_time_spent'):
            columns_to_add.append("ADD COLUMN lms_time_spent INTEGER DEFAULT 0")
            logger.info("  - lms_time_spent: needs to be added")
        else:
            logger.info("  - lms_time_spent: already exists")
            
        if not check_column_exists(engine, 'modules', 'lms_started_at'):
            columns_to_add.append("ADD COLUMN lms_started_at TIMESTAMP WITH TIME ZONE")
            logger.info("  - lms_started_at: needs to be added")
        else:
            logger.info("  - lms_started_at: already exists")
            
        if not check_column_exists(engine, 'modules', 'lms_completed_at'):
            columns_to_add.append("ADD COLUMN lms_completed_at TIMESTAMP WITH TIME ZONE")
            logger.info("  - lms_completed_at: needs to be added")
        else:
            logger.info("  - lms_completed_at: already exists")
        
        if not columns_to_add:
            logger.info("✅ All time tracking columns already exist in modules table")
            return {"status": "exists", "message": "All time tracking columns already exist"}
        
        logger.info("📋 Adding time tracking columns to modules table...")
        with engine.connect() as connection:
            for column_sql in columns_to_add:
                logger.info(f"  - Executing: ALTER TABLE modules {column_sql}")
                connection.execute(text(f"ALTER TABLE modules {column_sql}"))
            connection.commit()
        
        logger.info("✅ Time tracking columns added successfully to modules table")
        return {"status": "created", "message": "Time tracking columns added successfully to modules table"}
        
    except Exception as e:
        logger.error(f"❌ Error adding time tracking columns: {e}")
        raise

def add_planned_duration_column(engine):
    """Add planned_duration_hours column to courses table if it doesn't exist"""
    try:
        logger.info("🔍 Checking planned_duration_hours column in courses table...")
        
        if check_column_exists(engine, 'courses', 'planned_duration_hours'):
            logger.info("✅ planned_duration_hours column already exists in courses table")
            return {"status": "exists", "message": "planned_duration_hours column already exists"}
        
        logger.info("📋 Adding planned_duration_hours column to courses table...")
        with engine.connect() as connection:
            connection.execute(text("ALTER TABLE courses ADD COLUMN planned_duration_hours FLOAT DEFAULT 0.0"))
            connection.commit()
        
        logger.info("✅ planned_duration_hours column added successfully to courses table")
        return {"status": "created", "message": "planned_duration_hours column added successfully to courses table"}
        
    except Exception as e:
        logger.error(f"❌ Error adding planned_duration_hours column: {e}")
        raise

def run_complete_migration():
    """Run the complete migration for both time tracking and planned duration"""
    try:
        logger.info("🚀 Starting complete database migration for time tracking and planned duration features...")
        
        # Get database URL and create engine
        database_url = settings.database_url
        logger.info(f"📊 Connecting to database: {database_url.split('@')[1] if '@' in database_url else 'local'}")
        
        engine = create_engine(database_url)
        
        # Test database connection
        try:
            with engine.connect() as connection:
                connection.execute(text("SELECT 1"))
            logger.info("✅ Database connection successful")
        except Exception as e:
            logger.error(f"❌ Database connection failed: {e}")
            raise
        
        # Run migrations
        results = {}
        
        # 1. Add time tracking columns to modules table
        logger.info("\n" + "="*60)
        logger.info("STEP 1: Adding time tracking columns to modules table")
        logger.info("="*60)
        results['time_tracking'] = add_time_tracking_columns(engine)
        
        # 2. Add planned duration column to courses table
        logger.info("\n" + "="*60)
        logger.info("STEP 2: Adding planned duration column to courses table")
        logger.info("="*60)
        results['planned_duration'] = add_planned_duration_column(engine)
        
        # Summary
        logger.info("\n" + "="*60)
        logger.info("🎉 MIGRATION SUMMARY")
        logger.info("="*60)
        logger.info(f"Time tracking columns: {results['time_tracking']['status']}")
        logger.info(f"Planned duration column: {results['planned_duration']['status']}")
        logger.info("="*60)
        
        return results
        
    except Exception as e:
        logger.error(f"❌ Migration failed: {e}")
        raise

if __name__ == "__main__":
    try:
        results = run_complete_migration()
        print(f"\n🎉 Migration completed successfully!")
        print(f"Results: {results}")
        sys.exit(0)
    except Exception as e:
        logger.error(f"Migration failed: {e}")
        print(f"\n❌ Migration failed: {e}")
        sys.exit(1) 