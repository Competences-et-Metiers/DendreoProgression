#!/usr/bin/env python3
"""
Dendreo Sync Script
Synchronizes data from Dendreo API to local database
"""

import asyncio
import logging
import sys
import os
from datetime import datetime, timezone, timedelta
from pathlib import Path

# Add the app directory to the path
sys.path.append(str(Path(__file__).parent.parent))

from app.models.database import get_db_session
from app.models.models import SyncMetadata
from app.services.dendreo_sync import DendreoSync
from app.services.dendreo_client import DendreoClient
from app.config.settings import settings

def setup_logging(log_level: str = "INFO"):
    """Setup logging configuration"""
    logging.basicConfig(
        level=getattr(logging, log_level.upper()),
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.StreamHandler(),
            logging.FileHandler('logs/sync.log')
        ]
    )
    return logging.getLogger(__name__)

def cleanup_stuck_sync_metadata(force_cleanup: bool = False):
    """
    Clean up stuck sync metadata records
    
    Args:
        force_cleanup: Force cleanup even if records are recent
        
    Returns:
        Number of records cleaned up
    """
    logger = logging.getLogger(__name__)
    
    try:
        with get_db_session() as db:
            # Find stuck sync records (in_progress for more than 30 minutes)
            thirty_minutes_ago = datetime.now(timezone.utc) - timedelta(minutes=30)
            
            stuck_records = db.query(SyncMetadata).filter(
                SyncMetadata.status == 'in_progress',
                SyncMetadata.last_sync_at < thirty_minutes_ago
            ).all()
            
            if not stuck_records and not force_cleanup:
                return 0
            
            cleaned_count = 0
            for record in stuck_records:
                record.status = 'error'
                record.error_message = 'Automatically cleaned up stuck sync record'
                record.updated_at = datetime.now(timezone.utc)
                cleaned_count += 1
                logger.info(f"Cleaned up stuck sync record from {record.last_sync_at}")
            
            if force_cleanup:
                # Also clean up any in_progress records regardless of age
                force_records = db.query(SyncMetadata).filter(
                    SyncMetadata.status == 'in_progress'
                ).all()
                
                for record in force_records:
                    if record not in stuck_records:  # Avoid double processing
                        record.status = 'error'
                        record.error_message = 'Force cleaned up sync record'
                        record.updated_at = datetime.now(timezone.utc)
                        cleaned_count += 1
                        logger.info(f"Force cleaned up sync record from {record.last_sync_at}")
            
            db.commit()
            return cleaned_count
            
    except Exception as e:
        logger.error(f"Error cleaning up stuck sync records: {e}")
        return -1

def should_run_sync_on_deployment() -> bool:
    """
    Determine if a sync should be run on deployment based on:
    1. If no sync has ever been performed
    2. If the last sync was more than 24 hours ago
    3. If it's the first time the service is running (database empty)
    
    Returns:
        True if sync should be run, False otherwise
    """
    logger = logging.getLogger(__name__)
    
    try:
        with get_db_session() as db:
            # Check if database is empty (no participants)
            from app.models.models import Participant
            participant_count = db.query(Participant).count()
            
            if participant_count == 0:
                logger.info("📊 Database is empty - sync should run on deployment")
                return True
            
            # Check for recent successful sync (within last 24 hours)
            twenty_four_hours_ago = datetime.now(timezone.utc) - timedelta(hours=24)
            
            recent_sync = db.query(SyncMetadata).filter(
                SyncMetadata.sync_type == 'sync_all',
                SyncMetadata.status == 'success',
                SyncMetadata.last_sync_at > twenty_four_hours_ago
            ).order_by(SyncMetadata.last_sync_at.desc()).first()
            
            if recent_sync:
                logger.info(f"✅ Recent sync found at {recent_sync.last_sync_at} (within 24 hours) - skipping deployment sync")
                return False
            else:
                # Check for any sync at all
                last_sync = db.query(SyncMetadata).filter(
                    SyncMetadata.sync_type == 'sync_all',
                    SyncMetadata.status == 'success'
                ).order_by(SyncMetadata.last_sync_at.desc()).first()
                
                if last_sync:
                    logger.info(f"📅 Last sync was at {last_sync.last_sync_at} (more than 24 hours ago) - sync should run on deployment")
                else:
                    logger.info("🆕 No previous syncs found - sync should run on deployment")
                
                return True
                
    except Exception as e:
        logger.error(f"Error checking sync status: {e}")
        # In case of error, be conservative and run sync
        return True

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
        sync_metadata_id = None
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
                sync_metadata_id = sync_metadata.id
                logger.info(f"📝 Created sync metadata record (ID: {sync_metadata_id})")
        
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
                    "participants_created": 0,
                    "participants_updated": 0,
                    "courses_created": 0,
                    "courses_updated": 0,
                    "modules_created": 0,
                    "modules_updated": 0,
                    "participant_courses_created": 0,
                    "participant_courses_updated": 0
                }
            }
        
        # Update sync metadata with success
        if sync_metadata_id and not dry_run:
            with get_db_session() as db:
                record = db.query(SyncMetadata).get(sync_metadata_id)
                if record:
                    record.status = 'success'
                    record.stats = str(result.get('stats', {}))
                    record.updated_at = datetime.now(timezone.utc)
                    db.commit()
                    logger.info("✅ Sync metadata updated with success")
                else:
                    logger.error(f"Could not find sync metadata record ID {sync_metadata_id} to update")
        
        logger.info("✅ Sync completed successfully")
        return {
            "status": "success",
            "message": "Sync completed successfully",
            "stats": result.get('stats', {}),
            "sync_start_time": sync_start_time.isoformat()
        }
        
    except Exception as e:
        logger.error(f"❌ Sync failed: {str(e)}")
        
        # Update sync metadata with error
        if sync_metadata_id and not dry_run:
            try:
                with get_db_session() as db:
                    record = db.query(SyncMetadata).get(sync_metadata_id)
                    if record:
                        record.status = 'error'
                        record.error_message = str(e)
                        record.updated_at = datetime.now(timezone.utc)
                        db.commit()
                        logger.info("📝 Sync metadata updated with error")
                    else:
                        logger.error(f"Could not find sync metadata record ID {sync_metadata_id} to update")
            except Exception as metadata_error:
                logger.error(f"Failed to update sync metadata: {metadata_error}")
        
        return {
            "status": "error",
            "message": f"Sync failed: {str(e)}"
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