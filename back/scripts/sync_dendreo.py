#!/usr/bin/env python3
"""
Standalone Dendreo Sync Script
Runs the sync process independently of the API for scheduled execution.
"""

import sys
import os
import asyncio
import logging
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Optional

# Add the parent directory to the path so we can import from app
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.config.settings import settings
from app.models.database import get_db_session
from app.services.dendreo_sync import DendreoSync
from app.services.dendreo_client import DendreoClient
from app.models.models import SyncMetadata
import json

# Configure logging specifically for this script
def setup_logging(log_level: str = "INFO"):
    """Setup logging for the sync script"""
    
    # Create logs directory if it doesn't exist
    log_dir = Path(__file__).parent.parent / "logs"
    log_dir.mkdir(exist_ok=True)
    
    # Configure logging
    log_format = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    
    # File handler for sync-specific logs
    sync_log_file = log_dir / f"sync_{datetime.now().strftime('%Y%m%d')}.log"
    
    logging.basicConfig(
        level=getattr(logging, log_level.upper()),
        format=log_format,
        handlers=[
            logging.FileHandler(sync_log_file),
            logging.StreamHandler()  # Also log to console
        ]
    )
    
    # Silence noisy loggers
    logging.getLogger('httpx').setLevel(logging.WARNING)
    logging.getLogger('sqlalchemy').setLevel(logging.WARNING)
    
    return logging.getLogger(__name__)

def cleanup_stuck_sync_metadata(force_cleanup: bool = False):
    """Clean up any sync metadata records stuck in 'in_progress' state"""
    logger = logging.getLogger(__name__)
    
    try:
        with get_db_session() as db:
            # Define timeout for stuck syncs (default: 30 minutes, but can be forced)
            timeout_minutes = 5 if force_cleanup else 30
            timeout_ago = datetime.now(timezone.utc) - timedelta(minutes=timeout_minutes)
            
            stuck_syncs = db.query(SyncMetadata).filter(
                SyncMetadata.status == 'in_progress',
                SyncMetadata.last_sync_at < timeout_ago
            ).all()
            
            if stuck_syncs:
                logger.info(f"🔧 Found {len(stuck_syncs)} stuck sync metadata records (older than {timeout_minutes} minutes), cleaning up...")
                for sync in stuck_syncs:
                    # Calculate how long it was stuck
                    stuck_duration = datetime.now(timezone.utc) - sync.last_sync_at
                    
                    logger.info(f"  - Cleaning sync ID {sync.id} (stuck for {stuck_duration})")
                    sync.status = 'error'
                    sync.error_message = f'Sync process was interrupted or timed out after {stuck_duration}'
                    sync.updated_at = datetime.now(timezone.utc)
                
                db.commit()
                logger.info("✅ Cleaned up stuck sync metadata records")
                return len(stuck_syncs)
            else:
                logger.debug("✅ No stuck sync metadata records found")
                return 0
                
    except Exception as e:
        logger.error(f"❌ Failed to cleanup stuck sync metadata: {e}")
        return -1

async def run_sync(force: bool = False, dry_run: bool = False) -> dict:
    """
    Run the Dendreo sync process
    
    Args:
        force: Force sync even if recent sync exists
        dry_run: Don't actually update the database
    
    Returns:
        Dictionary with sync results
    """
    logger = logging.getLogger(__name__)
    
    try:
        # Always clean up stuck sync metadata before starting
        logger.info("🧹 Checking for stuck sync records...")
        cleaned_count = cleanup_stuck_sync_metadata(force_cleanup=force)
        
        if cleaned_count > 0:
            logger.info(f"🔧 Cleaned up {cleaned_count} stuck sync record(s)")
        elif cleaned_count == 0:
            logger.info("✅ No stuck sync records found")
        
        # Check if a sync is already in progress (after cleanup)
        with get_db_session() as db:
            in_progress_sync = db.query(SyncMetadata).filter(
                SyncMetadata.sync_type == 'sync_all',
                SyncMetadata.status == 'in_progress'
            ).first()
            
            if in_progress_sync and not force:
                # Double-check if this is truly stuck (within last 5 minutes)
                five_minutes_ago = datetime.now(timezone.utc) - timedelta(minutes=5)
                if in_progress_sync.last_sync_at > five_minutes_ago:
                    logger.warning("⚠️  Sync already in progress (started recently). Use --force to override.")
                    return {
                        "status": "skipped",
                        "message": "Sync already in progress",
                        "last_sync_started": in_progress_sync.last_sync_at.isoformat()
                    }
                else:
                    # This sync is old enough to be considered stuck, clean it up
                    logger.warning(f"🔧 Found a potentially stuck sync from {in_progress_sync.last_sync_at}, cleaning up...")
                    in_progress_sync.status = 'error'
                    in_progress_sync.error_message = 'Sync was stuck and automatically cleaned up'
                    in_progress_sync.updated_at = datetime.now(timezone.utc)
                    db.commit()
            
            # Check for recent successful sync (within last hour) - only if not forced
            if not force:
                one_hour_ago = datetime.now(timezone.utc) - timedelta(hours=1)
                recent_sync = db.query(SyncMetadata).filter(
                    SyncMetadata.sync_type == 'sync_all',
                    SyncMetadata.status == 'success',
                    SyncMetadata.last_sync_at > one_hour_ago
                ).first()
                
                if recent_sync:
                    logger.info(f"ℹ️  Recent successful sync found at {recent_sync.last_sync_at}. Use --force to override.")
                    return {
                        "status": "skipped",
                        "message": "Recent sync found",
                        "last_sync_at": recent_sync.last_sync_at.isoformat()
                    }
        
        if dry_run:
            logger.info("🧪 DRY RUN MODE - No database changes will be made")
            logger.warning("⚠️  DRY RUN: Sync metadata will NOT be created to avoid stuck records")
        
        logger.info("🚀 Starting Dendreo sync process...")
        sync_start_time = datetime.now(timezone.utc)
        
        # Create sync metadata record (only for real syncs, not dry runs)
        sync_metadata = None
        if not dry_run:
            with get_db_session() as db:
                # Create a new sync metadata record for each sync operation
                sync_metadata = SyncMetadata(
                    sync_type='sync_all',
                    last_sync_at=sync_start_time,
                    status='in_progress'
                )
                db.add(sync_metadata)
                db.commit()
                logger.info(f"📝 Created sync metadata record (ID: {sync_metadata.id})")
        
        # Run the sync
        if not dry_run:
            with get_db_session() as db:
                client = DendreoClient()
                sync_service = DendreoSync(db, client)
                result = await sync_service.sync_all()
        else:
            # Simulate sync for dry run
            logger.info("🧪 Simulating sync process...")
            await asyncio.sleep(1)  # Simulate some work
            result = {
                "status": "success",
                "message": "Dry run completed successfully",
                "stats": {
                    "note": "This was a dry run - no actual changes made",
                    "simulated": True,
                    "timestamp": datetime.now(timezone.utc).isoformat()
                }
            }
        
        # Update sync metadata with success (only for real syncs)
        if not dry_run and sync_metadata:
            with get_db_session() as db:
                # Refresh the sync_metadata object
                sync_metadata = db.query(SyncMetadata).filter(
                    SyncMetadata.id == sync_metadata.id
                ).first()
                
                if sync_metadata:
                    sync_metadata.status = 'success'
                    sync_metadata.stats = json.dumps(result.get('stats', {}))
                    sync_metadata.updated_at = datetime.now(timezone.utc)
                    db.commit()
                    logger.info(f"✅ Updated sync metadata record to success (ID: {sync_metadata.id})")
        
        logger.info(f"✅ Sync completed successfully: {result.get('message', 'No message')}")
        return result
        
    except Exception as e:
        logger.error(f"❌ Sync failed: {str(e)}")
        
        # Update sync metadata with error (only for real syncs)
        if not dry_run and sync_metadata:
            try:
                with get_db_session() as db:
                    # Refresh the sync_metadata object
                    sync_metadata = db.query(SyncMetadata).filter(
                        SyncMetadata.id == sync_metadata.id
                    ).first()
                    
                    if sync_metadata:
                        sync_metadata.status = 'error'
                        sync_metadata.error_message = str(e)
                        sync_metadata.updated_at = datetime.now(timezone.utc)
                        db.commit()
                        logger.info(f"📝 Updated sync metadata record to error (ID: {sync_metadata.id})")
            except Exception as meta_error:
                logger.error(f"Failed to update sync metadata: {meta_error}")
        
        return {
            "status": "error",
            "message": str(e),
            "timestamp": datetime.now(timezone.utc).isoformat()
        }

def main():
    """Main function with CLI argument parsing"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Dendreo Sync Script",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python sync_dendreo.py                    # Normal sync
  python sync_dendreo.py --force           # Force sync (ignore recent syncs)
  python sync_dendreo.py --dry-run         # Test run without changes
  python sync_dendreo.py --log-level DEBUG # Debug mode
  python sync_dendreo.py --cleanup-stuck   # Clean up stuck sync records
        """
    )
    
    parser.add_argument(
        '--force', 
        action='store_true',
        help='Force sync even if recent sync exists or records are stuck'
    )
    
    parser.add_argument(
        '--dry-run', 
        action='store_true',
        help='Test run without making database changes (will not create sync metadata)'
    )
    
    parser.add_argument(
        '--log-level',
        choices=['DEBUG', 'INFO', 'WARNING', 'ERROR'],
        default='INFO',
        help='Set logging level'
    )
    
    parser.add_argument(
        '--cleanup-stuck',
        action='store_true',
        help='Clean up stuck sync metadata records and exit'
    )
    
    args = parser.parse_args()
    
    # Setup logging
    logger = setup_logging(args.log_level)
    
    # Handle cleanup-stuck option
    if args.cleanup_stuck:
        logger.info("🧹 Manual cleanup of stuck sync records requested...")
        cleaned_count = cleanup_stuck_sync_metadata(force_cleanup=True)
        if cleaned_count > 0:
            logger.info(f"✅ Cleaned up {cleaned_count} stuck sync record(s)")
        elif cleaned_count == 0:
            logger.info("✅ No stuck sync records found")
        else:
            logger.error("❌ Error occurred during cleanup")
            sys.exit(1)
        logger.info("🧹 Cleanup completed, exiting...")
        sys.exit(0)
    
    # Print startup info
    logger.info("=" * 60)
    logger.info("🌟 Dendreo Sync Script Starting")
    logger.info("=" * 60)
    logger.info(f"Environment: {settings.app_env}")
    logger.info(f"Database: {settings.database_url.split('@')[-1] if '@' in settings.database_url else 'local'}")
    logger.info(f"Force mode: {args.force}")
    logger.info(f"Dry run: {args.dry_run}")
    logger.info(f"Log level: {args.log_level}")
    logger.info("=" * 60)
    
    # Run the sync
    try:
        result = asyncio.run(run_sync(force=args.force, dry_run=args.dry_run))
        
        # Print results
        logger.info("=" * 60)
        logger.info("📊 Sync Results")
        logger.info("=" * 60)
        logger.info(f"Status: {result['status']}")
        logger.info(f"Message: {result['message']}")
        
        if 'stats' in result:
            stats = result['stats']
            if isinstance(stats, dict):
                for key, value in stats.items():
                    logger.info(f"  {key}: {value}")
        
        # Exit with appropriate code
        sys.exit(0 if result['status'] in ['success', 'skipped'] else 1)
        
    except KeyboardInterrupt:
        logger.warning("🛑 Sync interrupted by user")
        sys.exit(130)
    except Exception as e:
        logger.error(f"💥 Unexpected error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main() 