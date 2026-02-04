#!/usr/bin/env python3
"""
Add formateurs column to courses table and date_add column to participant_courses table
This script adds:
- formateurs JSON column to courses table (stores formateur data from Dendreo ADF)
- date_add timestamp column to participant_courses table (stores when participant was added to ADF)
"""

import sys
import logging
from pathlib import Path

# Add the app directory to the path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from app.config.settings import settings
from app.models.database import engine
from sqlalchemy import text

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def add_formateurs_column():
    """Add formateurs JSON column to courses table if it doesn't exist"""
    try:
        logger.info("Checking if formateurs column exists in courses table...")

        # Check if column exists
        with engine.connect() as connection:
            result = connection.execute(text("""
                SELECT column_name
                FROM information_schema.columns
                WHERE table_name = 'courses' AND column_name = 'formateurs'
            """))
            column_exists = result.fetchone() is not None

            if column_exists:
                logger.info("✅ formateurs column already exists in courses table")
                return {"status": "exists", "message": "Column already exists"}

        logger.info("📋 Adding formateurs column to courses table...")

        # Add the column (using JSONB for PostgreSQL)
        with engine.connect() as connection:
            connection.execute(text("""
                ALTER TABLE courses
                ADD COLUMN formateurs JSONB
            """))
            connection.commit()

        logger.info("✅ formateurs column added successfully to courses table")

        return {
            "status": "created",
            "message": "formateurs column added successfully to courses table"
        }

    except Exception as e:
        logger.error(f"❌ Error adding formateurs column: {e}")
        raise

def add_date_add_column():
    """Add date_add timestamp column to participant_courses table if it doesn't exist"""
    try:
        logger.info("Checking if date_add column exists in participant_courses table...")

        # Check if column exists
        with engine.connect() as connection:
            result = connection.execute(text("""
                SELECT column_name
                FROM information_schema.columns
                WHERE table_name = 'participant_courses' AND column_name = 'date_add'
            """))
            column_exists = result.fetchone() is not None

            if column_exists:
                logger.info("✅ date_add column already exists in participant_courses table")
                return {"status": "exists", "message": "Column already exists"}

        logger.info("📋 Adding date_add column to participant_courses table...")

        # Add the column
        with engine.connect() as connection:
            connection.execute(text("""
                ALTER TABLE participant_courses
                ADD COLUMN date_add TIMESTAMP WITH TIME ZONE
            """))
            connection.commit()

        logger.info("✅ date_add column added successfully to participant_courses table")

        return {
            "status": "created",
            "message": "date_add column added successfully to participant_courses table"
        }

    except Exception as e:
        logger.error(f"❌ Error adding date_add column: {e}")
        raise

if __name__ == "__main__":
    try:
        print("\n🚀 Starting migration: add formateurs and date_add columns")

        # Add formateurs column to courses
        result1 = add_formateurs_column()
        print(f"📊 Courses table: {result1['message']}")

        # Add date_add column to participant_courses
        result2 = add_date_add_column()
        print(f"📊 ParticipantCourses table: {result2['message']}")

        print("\n🎉 Migration completed successfully!")

    except Exception as e:
        print(f"\n❌ Migration failed: {str(e)}")
        sys.exit(1)
