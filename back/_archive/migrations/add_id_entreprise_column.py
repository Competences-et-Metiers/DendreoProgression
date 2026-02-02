#!/usr/bin/env python3
"""
Add id_entreprise column to participants table
This script adds the id_entreprise column to the participants table if it doesn't already exist.
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

def add_id_entreprise_column():
    """Add id_entreprise column to participants table if it doesn't exist"""
    try:
        logger.info("Checking if id_entreprise column exists in participants table...")
        
        # Check if column exists
        with engine.connect() as connection:
            result = connection.execute(text("""
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_name = 'participants' AND column_name = 'id_entreprise'
            """))
            column_exists = result.fetchone() is not None
            
            if column_exists:
                logger.info("✅ id_entreprise column already exists in participants table")
                return {"status": "exists", "message": "Column already exists"}
        
        logger.info("📋 Adding id_entreprise column to participants table...")
        
        # Add the column
        with engine.connect() as connection:
            connection.execute(text("""
                ALTER TABLE participants 
                ADD COLUMN id_entreprise VARCHAR
            """))
            connection.commit()
        
        logger.info("✅ id_entreprise column added successfully to participants table")
        
        return {
            "status": "created",
            "message": "id_entreprise column added successfully to participants table"
        }
        
    except Exception as e:
        logger.error(f"❌ Error adding id_entreprise column: {e}")
        raise

if __name__ == "__main__":
    try:
        result = add_id_entreprise_column()
        print(f"\n🎉 {result['message']}")
        
    except Exception as e:
        print(f"\n❌ Failed to add column: {str(e)}")
        sys.exit(1) 