#!/usr/bin/env python3
"""
Database Migration: Add Admin Features
Adds role-based authentication and sync management features.

Changes:
1. Add role column to users table
2. Add api_calls_count and duration_seconds to sync_metadata table
3. Create admin_sync_config table
4. Set first user (or user with id=1) as admin
"""

import sys
import os
from pathlib import Path

# Add the app directory to the path
sys.path.append(str(Path(__file__).parent.parent))

from app.models.database import engine, get_db_session
from app.models.models import User, SyncMetadata, AdminSyncConfig
from sqlalchemy import text, inspect
import logging

logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)


def column_exists(table_name, column_name):
    """Check if a column exists in a table"""
    inspector = inspect(engine)
    columns = [col['name'] for col in inspector.get_columns(table_name)]
    return column_name in columns


def table_exists(table_name):
    """Check if a table exists"""
    inspector = inspect(engine)
    return table_name in inspector.get_table_names()


def add_role_to_users():
    """Add role column to users table"""
    logger.info("Checking users.role column...")

    if column_exists('users', 'role'):
        logger.info("✓ users.role column already exists")
        return

    logger.info("Adding users.role column...")
    with engine.begin() as conn:
        conn.execute(text("""
            ALTER TABLE users
            ADD COLUMN role VARCHAR(20) DEFAULT 'user' NOT NULL
        """))
    logger.info("✓ users.role column added")


def add_api_tracking_to_sync_metadata():
    """Add API tracking columns to sync_metadata table"""
    logger.info("Checking sync_metadata API tracking columns...")

    changes_made = False

    with engine.begin() as conn:
        if not column_exists('sync_metadata', 'api_calls_count'):
            logger.info("Adding sync_metadata.api_calls_count column...")
            conn.execute(text("""
                ALTER TABLE sync_metadata
                ADD COLUMN api_calls_count INTEGER DEFAULT 0 NOT NULL
            """))
            logger.info("✓ sync_metadata.api_calls_count column added")
            changes_made = True
        else:
            logger.info("✓ sync_metadata.api_calls_count column already exists")

        if not column_exists('sync_metadata', 'duration_seconds'):
            logger.info("Adding sync_metadata.duration_seconds column...")
            conn.execute(text("""
                ALTER TABLE sync_metadata
                ADD COLUMN duration_seconds FLOAT
            """))
            logger.info("✓ sync_metadata.duration_seconds column added")
            changes_made = True
        else:
            logger.info("✓ sync_metadata.duration_seconds column already exists")

    if not changes_made:
        logger.info("✓ All sync_metadata tracking columns already exist")


def create_admin_sync_config_table():
    """Create admin_sync_config table"""
    logger.info("Checking admin_sync_config table...")

    if table_exists('admin_sync_config'):
        logger.info("✓ admin_sync_config table already exists")
        return

    logger.info("Creating admin_sync_config table...")
    with engine.begin() as conn:
        conn.execute(text("""
            CREATE TABLE admin_sync_config (
                id SERIAL PRIMARY KEY,
                cron_enabled BOOLEAN DEFAULT true NOT NULL,
                cooldown_hours FLOAT DEFAULT 1.0 NOT NULL,
                last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                updated_by_user_id INTEGER REFERENCES users(id)
            )
        """))

        # Insert initial config row
        conn.execute(text("""
            INSERT INTO admin_sync_config (cron_enabled, cooldown_hours)
            VALUES (true, 1.0)
        """))

    logger.info("✓ admin_sync_config table created with initial config")


def set_first_user_as_admin():
    """Set the first user (or user with id=1) as admin"""
    logger.info("Setting first user as admin...")

    with get_db_session() as db:
        # Try to find user with id=1 first
        user = db.query(User).filter(User.id == 1).first()

        # If no user with id=1, get the first user by creation date
        if not user:
            user = db.query(User).order_by(User.created_at).first()

        if not user:
            logger.warning("⚠ No users found in database. Create a user first, then run this migration.")
            return

        if user.role == 'admin':
            logger.info(f"✓ User '{user.username}' is already an admin")
            return

        user.role = 'admin'
        db.commit()
        logger.info(f"✓ User '{user.username}' set as admin")
        logger.info(f"  User ID: {user.id}")
        logger.info(f"  Username: {user.username}")


def main():
    """Run all migrations"""
    logger.info("=" * 60)
    logger.info("Starting Admin Features Migration")
    logger.info("=" * 60)

    try:
        # Step 1: Add role to users
        add_role_to_users()

        # Step 2: Add API tracking to sync_metadata
        add_api_tracking_to_sync_metadata()

        # Step 3: Create admin_sync_config table
        create_admin_sync_config_table()

        # Step 4: Set first user as admin
        set_first_user_as_admin()

        logger.info("=" * 60)
        logger.info("✓ Migration completed successfully!")
        logger.info("=" * 60)
        logger.info("")
        logger.info("Next steps:")
        logger.info("1. Restart the backend: docker compose -f docker-compose.prod.yml restart backend")
        logger.info("2. Login with your admin user")
        logger.info("3. Access admin dashboard at /admin/sync")
        logger.info("")

        return 0

    except Exception as e:
        logger.error("=" * 60)
        logger.error(f"✗ Migration failed: {str(e)}")
        logger.error("=" * 60)
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
