#!/usr/bin/env python3
"""
DendreoProgression Database Migration Script
This script adds time tracking columns to the database.
Can be run inside the backend container.
"""

import os
import sys
import logging
from datetime import datetime
from sqlalchemy import create_engine, text, inspect
from sqlalchemy.exc import SQLAlchemyError

# Add the app directory to the path so we can import models
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'app'))

from models.models import Base

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def get_database_url():
    """Get database URL from environment variables"""
    # Try to get from DATABASE_URL first (for production)
    database_url = os.getenv('DATABASE_URL')
    if database_url:
        return database_url
    
    # Fallback to individual environment variables
    db_host = os.getenv('DB_HOST', 'postgres')
    db_port = os.getenv('DB_PORT', '5432')
    db_name = os.getenv('DB_NAME', 'dendreo_dev_db')
    db_user = os.getenv('DB_USER', 'postgres')
    db_password = os.getenv('DB_PASSWORD', 'admin')
    
    return f"postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"

def check_column_exists(engine, table_name, column_name):
    """Check if a column exists in a table"""
    inspector = inspect(engine)
    columns = [col['name'] for col in inspector.get_columns(table_name)]
    return column_name in columns

def add_column_if_not_exists(engine, table_name, column_name, column_definition):
    """Add a column if it doesn't exist"""
    if not check_column_exists(engine, table_name, column_name):
        try:
            with engine.connect() as conn:
                sql = f"ALTER TABLE {table_name} ADD COLUMN {column_name} {column_definition}"
                conn.execute(text(sql))
                conn.commit()
                logger.info(f"✅ Added column {column_name} to {table_name}")
                return True
        except SQLAlchemyError as e:
            logger.error(f"❌ Failed to add column {column_name} to {table_name}: {e}")
            return False
    else:
        logger.info(f"ℹ️  Column {column_name} already exists in {table_name}")
        return True

def create_index_if_not_exists(engine, index_name, table_name, column_name):
    """Create an index if it doesn't exist"""
    try:
        with engine.connect() as conn:
            # Check if index exists
            sql = """
            SELECT 1 FROM pg_indexes 
            WHERE indexname = :index_name
            """
            result = conn.execute(text(sql), {"index_name": index_name})
            if result.fetchone():
                logger.info(f"ℹ️  Index {index_name} already exists")
                return True
            
            # Create index
            sql = f"CREATE INDEX {index_name} ON {table_name}({column_name})"
            conn.execute(text(sql))
            conn.commit()
            logger.info(f"✅ Created index {index_name} on {table_name}({column_name})")
            return True
    except SQLAlchemyError as e:
        logger.error(f"❌ Failed to create index {index_name}: {e}")
        return False

def add_column_comments(engine):
    """Add comments to document the new columns"""
    comments = [
        ("courses", "planned_duration_hours", "Planned duration in hours from duree_heures field in Dendreo API"),
        ("modules", "lms_time_spent", "Time spent in seconds by participant on this module"),
        ("modules", "lms_started_at", "Timestamp when participant started this module"),
        ("modules", "lms_completed_at", "Timestamp when participant completed this module")
    ]
    
    try:
        with engine.connect() as conn:
            for table_name, column_name, comment in comments:
                if check_column_exists(engine, table_name, column_name):
                    sql = f"COMMENT ON COLUMN {table_name}.{column_name} IS '{comment}'"
                    conn.execute(text(sql))
                    logger.info(f"✅ Added comment to {table_name}.{column_name}")
            conn.commit()
    except SQLAlchemyError as e:
        logger.error(f"❌ Failed to add comments: {e}")

def verify_migration(engine):
    """Verify that all new columns exist"""
    expected_columns = [
        ("courses", "planned_duration_hours"),
        ("modules", "lms_time_spent"),
        ("modules", "lms_started_at"),
        ("modules", "lms_completed_at"),
        ("users", "auth_provider"),
        ("users", "microsoft_id"),
        ("users", "email"),
        ("users", "display_name"),
    ]
    
    all_exist = True
    for table_name, column_name in expected_columns:
        if check_column_exists(engine, table_name, column_name):
            logger.info(f"✅ Verified: {table_name}.{column_name}")
        else:
            logger.error(f"❌ Missing: {table_name}.{column_name}")
            all_exist = False
    
    return all_exist

def main():
    """Main migration function"""
    logger.info("🚀 Starting DendreoProgression Database Migration")
    logger.info("=" * 50)
    
    # Get database connection
    try:
        database_url = get_database_url()
        logger.info(f"📊 Connecting to database: {database_url.split('@')[1]}")
        engine = create_engine(database_url)
        
        # Test connection
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        logger.info("✅ Database connection successful")
        
    except SQLAlchemyError as e:
        logger.error(f"❌ Database connection failed: {e}")
        sys.exit(1)
    
    # Migration steps
    migration_steps = [
        # (table_name, column_name, column_definition)
        ("courses", "planned_duration_hours", "FLOAT DEFAULT 0.0"),
        ("modules", "lms_time_spent", "INTEGER DEFAULT 0"),
        ("modules", "lms_started_at", "TIMESTAMP WITH TIME ZONE"),
        ("modules", "lms_completed_at", "TIMESTAMP WITH TIME ZONE"),
        # Microsoft Entra ID (Azure AD) authentication
        ("users", "auth_provider", "VARCHAR(20) DEFAULT 'local' NOT NULL"),
        ("users", "microsoft_id", "VARCHAR(255) UNIQUE"),
        ("users", "email", "VARCHAR(255)"),
        ("users", "display_name", "VARCHAR(255)"),
    ]
    
    # Add columns
    logger.info("📝 Adding new columns...")
    for table_name, column_name, column_definition in migration_steps:
        if not add_column_if_not_exists(engine, table_name, column_name, column_definition):
            logger.error(f"❌ Migration failed at {table_name}.{column_name}")
            sys.exit(1)
    
    # Make hashed_password nullable for Microsoft-only users
    logger.info("🔑 Making hashed_password nullable for Microsoft auth support...")
    try:
        with engine.connect() as conn:
            conn.execute(text("ALTER TABLE users ALTER COLUMN hashed_password DROP NOT NULL"))
            conn.commit()
            logger.info("✅ Made users.hashed_password nullable")
    except SQLAlchemyError as e:
        logger.info(f"ℹ️  hashed_password already nullable or change skipped: {e}")

    # Create indexes
    logger.info("🔍 Creating indexes...")
    indexes = [
        ("idx_modules_lms_time_spent", "modules", "lms_time_spent"),
        ("idx_modules_lms_started_at", "modules", "lms_started_at"),
        ("idx_modules_lms_completed_at", "modules", "lms_completed_at"),
        ("idx_users_microsoft_id", "users", "microsoft_id"),
    ]
    
    for index_name, table_name, column_name in indexes:
        if not create_index_if_not_exists(engine, index_name, table_name, column_name):
            logger.warning(f"⚠️  Failed to create index {index_name}")
    
    # Add comments
    logger.info("💬 Adding column comments...")
    add_column_comments(engine)
    
    # Verify migration
    logger.info("🔍 Verifying migration...")
    if verify_migration(engine):
        logger.info("✅ Migration completed successfully!")
        logger.info("")
        logger.info("📋 Next steps:")
        logger.info("1. Restart your application containers")
        logger.info("2. Run a sync to populate time tracking data")
        logger.info("3. Verify time tracking appears in the frontend")
    else:
        logger.error("❌ Migration verification failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()
