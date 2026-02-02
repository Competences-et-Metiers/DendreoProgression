#!/usr/bin/env python3
"""
Test script for sync deployment logic
This script tests the should_run_sync_on_deployment() function to verify it works correctly.
"""

import sys
import logging
from pathlib import Path

# Add the app directory to the path
sys.path.append(str(Path(__file__).parent))

from scripts.sync_dendreo import should_run_sync_on_deployment
from app.models.database import get_db_session
from app.models.models import Participant, SyncMetadata
from datetime import datetime, timezone, timedelta

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def test_sync_deployment_logic():
    """Test the sync deployment logic"""
    logger.info("🧪 Testing sync deployment logic...")
    
    try:
        with get_db_session() as db:
            # Check current state
            participant_count = db.query(Participant).count()
            logger.info(f"📊 Current participant count: {participant_count}")
            
            # Check recent syncs
            twenty_four_hours_ago = datetime.now(timezone.utc) - timedelta(hours=24)
            recent_syncs = db.query(SyncMetadata).filter(
                SyncMetadata.sync_type == 'sync_all',
                SyncMetadata.status == 'success',
                SyncMetadata.last_sync_at > twenty_four_hours_ago
            ).all()
            
            logger.info(f"📅 Recent syncs (last 24 hours): {len(recent_syncs)}")
            for sync in recent_syncs:
                logger.info(f"   - {sync.last_sync_at} (ID: {sync.id})")
            
            # Test the function
            should_run = should_run_sync_on_deployment()
            logger.info(f"🎯 should_run_sync_on_deployment() returned: {should_run}")
            
            # Explain the decision
            if participant_count == 0:
                logger.info("💡 Decision: Database is empty, sync should run")
            elif recent_syncs:
                logger.info("💡 Decision: Recent sync found, sync should NOT run")
            else:
                logger.info("💡 Decision: No recent sync, sync should run")
            
            return should_run
            
    except Exception as e:
        logger.error(f"❌ Error testing sync deployment logic: {e}")
        return None

def main():
    """Main function"""
    logger.info("=" * 60)
    logger.info("🧪 Sync Deployment Logic Test")
    logger.info("=" * 60)
    
    result = test_sync_deployment_logic()
    
    logger.info("=" * 60)
    if result is True:
        logger.info("✅ RESULT: Sync SHOULD run on deployment")
        sys.exit(0)
    elif result is False:
        logger.info("⏭️  RESULT: Sync should NOT run on deployment")
        sys.exit(1)
    else:
        logger.error("❌ RESULT: Error occurred during test")
        sys.exit(2)

if __name__ == "__main__":
    main() 