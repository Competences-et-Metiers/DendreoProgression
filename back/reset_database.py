#!/usr/bin/env python3
"""
Database Reset Script
Drops all tables and recreates them with fresh schema.
USE WITH CAUTION - This will delete ALL data!
"""

import sys
import logging
from sqlalchemy import create_engine, text, inspect
from app.models.database import get_database_url
from app.models.models import Base
from pathlib import Path

# Add the app directory to the path
sys.path.append(str(Path(__file__).parent))

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def reset_database():
    """
    Complete database reset:
    1. Drop all existing tables
    2. Recreate all tables from SQLAlchemy models
    """
    
    try:
        # Get database URL
        database_url = get_database_url()
        logger.info(f"Connecting to database...")
        
        # Create engine
        engine = create_engine(database_url)
        
        # Test connection
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
            logger.info("✅ Database connection successful")
        
        # Step 1: Drop all existing tables
        logger.info("🗑️  Dropping all existing tables...")
        
        with engine.connect() as connection:
            # Get all table names
            inspector = inspect(engine)
            tables = inspector.get_table_names()
            
            if tables:
                logger.info(f"Found {len(tables)} tables to drop: {tables}")
                
                # Start transaction
                trans = connection.begin()
                
                try:
                    # Drop tables with CASCADE to handle foreign key constraints
                    for table in tables:
                        logger.info(f"  Dropping table: {table}")
                        connection.execute(text(f"DROP TABLE IF EXISTS {table} CASCADE"))
                    
                    # Commit the transaction
                    trans.commit()
                    logger.info("✅ All tables dropped successfully")
                    
                except Exception as e:
                    trans.rollback()
                    logger.error(f"❌ Error dropping tables: {e}")
                    raise
            else:
                logger.info("No existing tables found")
        
        # Step 2: Create all tables from models
        logger.info("🏗️  Creating all tables from SQLAlchemy models...")
        
        Base.metadata.create_all(bind=engine)
        logger.info("✅ All tables created successfully")
        
        # Step 3: Verify tables were created
        with engine.connect() as connection:
            inspector = inspect(engine)
            new_tables = inspector.get_table_names()
            logger.info(f"✅ Created {len(new_tables)} tables: {sorted(new_tables)}")
        
        logger.info("🎉 Database reset completed successfully!")
        
        return {
            "status": "success",
            "message": "Database reset completed successfully",
            "tables_created": len(new_tables),
            "table_names": sorted(new_tables)
        }
        
    except Exception as e:
        logger.error(f"❌ Database reset failed: {e}")
        raise
    finally:
        if 'engine' in locals():
            engine.dispose()

def confirm_reset():
    """Ask for user confirmation before proceeding"""
    print("\n" + "="*60)
    print("⚠️  DATABASE RESET WARNING ⚠️")
    print("="*60)
    print("This will PERMANENTLY DELETE all data in the database!")
    print("- All participants will be removed")
    print("- All courses will be removed") 
    print("- All modules will be removed")
    print("- All progress data will be lost")
    print("="*60)
    
    response = input("\nAre you sure you want to proceed? Type 'YES' to confirm: ")
    
    if response.strip().upper() != 'YES':
        print("❌ Reset cancelled by user")
        sys.exit(0)
    
    print("✅ Reset confirmed. Proceeding...")

if __name__ == "__main__":
    # Ask for confirmation unless --force flag is used
    if "--force" not in sys.argv:
        confirm_reset()
    
    try:
        result = reset_database()
        print(f"\n🎉 Success: {result['message']}")
        print(f"📊 Tables created: {result['tables_created']}")
        
    except Exception as e:
        print(f"\n❌ Reset failed: {str(e)}")
        sys.exit(1) 