#!/usr/bin/env python3
"""
Database Migration: Add Period API Limits
Adds daily/weekly/monthly API limit columns to admin_sync_config
and hubspot_api_calls_count to sync_metadata.

Changes:
1. Add hubspot_api_calls_count to sync_metadata
2. Add dendreo_daily_limit, dendreo_weekly_limit, dendreo_monthly_limit to admin_sync_config
3. Add hubspot_daily_limit, hubspot_weekly_limit, hubspot_monthly_limit to admin_sync_config
"""

import sys
import os
from pathlib import Path

# Add the app directory to the path
sys.path.append(str(Path(__file__).parent.parent))

from app.models.database import engine
from sqlalchemy import text, inspect
import logging

logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)


def column_exists(table_name, column_name):
    """Check if a column exists in a table"""
    inspector = inspect(engine)
    columns = [col['name'] for col in inspector.get_columns(table_name)]
    return column_name in columns


def add_column(conn, table_name, column_name, definition):
    """Add a column if it doesn't exist"""
    if column_exists(table_name, column_name):
        logger.info(f"  ✓ {table_name}.{column_name} already exists")
        return
    conn.execute(text(f"ALTER TABLE {table_name} ADD COLUMN {column_name} {definition}"))
    logger.info(f"  ✓ Added {table_name}.{column_name}")


def main():
    logger.info("=" * 60)
    logger.info("Migration: Add Period API Limits")
    logger.info("=" * 60)

    try:
        with engine.begin() as conn:
            # sync_metadata: add hubspot API call tracking
            logger.info("sync_metadata columns:")
            add_column(conn, 'sync_metadata', 'hubspot_api_calls_count', 'INTEGER DEFAULT 0 NOT NULL')

            # admin_sync_config: add period limit columns
            logger.info("admin_sync_config columns:")
            for prefix in ['dendreo', 'hubspot']:
                for period in ['daily', 'weekly', 'monthly']:
                    col_name = f'{prefix}_{period}_limit'
                    add_column(conn, 'admin_sync_config', col_name, 'INTEGER')

        logger.info("=" * 60)
        logger.info("✓ Migration completed successfully!")
        logger.info("=" * 60)
        return 0

    except Exception as e:
        logger.error(f"✗ Migration failed: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
