#!/usr/bin/env python3
"""
Clear Stuck Sync Records

This script clears sync records that are stuck in 'in_progress' status,
which prevents new syncs from running.
"""

import sys
import os
from datetime import datetime, timezone, timedelta
from pathlib import Path

# Add the parent directory to the path so we can import from app
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.models.database import get_db_session
from app.models.models import SyncMetadata

def clear_stuck_syncs(force_all: bool = False, interactive: bool = True):
    """Clear sync records stuck in 'in_progress' status"""
    
    print("🔍 Searching for stuck sync records...")
    
    with get_db_session() as db:
        # Define criteria for stuck syncs
        if force_all:
            # Clear ALL in_progress records regardless of age
            stuck_syncs = db.query(SyncMetadata).filter(
                SyncMetadata.status == 'in_progress'
            ).all()
            print("⚠️  FORCE MODE: Will clear ALL in_progress records")
        else:
            # Only clear records older than 30 minutes
            thirty_minutes_ago = datetime.now(timezone.utc) - timedelta(minutes=30)
            stuck_syncs = db.query(SyncMetadata).filter(
                SyncMetadata.status == 'in_progress',
                SyncMetadata.last_sync_at < thirty_minutes_ago
            ).all()
        
        if not stuck_syncs:
            print("✅ No stuck sync records found")
            return 0
        
        print(f"📋 Found {len(stuck_syncs)} stuck sync record(s):")
        print()
        
        for sync in stuck_syncs:
            age = datetime.now(timezone.utc) - sync.last_sync_at
            print(f"  📊 Record ID: {sync.id}")
            print(f"     Type: {sync.sync_type}")
            print(f"     Started: {sync.last_sync_at}")
            print(f"     Age: {age}")
            print(f"     Status: {sync.status}")
            if sync.error_message:
                print(f"     Last Error: {sync.error_message}")
            print()
        
        # Ask for confirmation if interactive
        if interactive:
            confirm = input("❓ Do you want to clear these stuck records? (y/N): ").lower().strip()
            
            if confirm != 'y':
                print("❌ Operation cancelled")
                return 0
        
        # Clear the stuck records
        cleared_count = 0
        for sync in stuck_syncs:
            age = datetime.now(timezone.utc) - sync.last_sync_at
            print(f"🔧 Clearing sync ID {sync.id} (stuck for {age})")
            
            sync.status = 'error'
            sync.error_message = f'Manually cleared - was stuck in progress for {age}'
            sync.updated_at = datetime.now(timezone.utc)
            cleared_count += 1
            
        db.commit()
        
        print()
        print(f"✅ Successfully cleared {cleared_count} stuck sync record(s)")
        print("🎉 New syncs can now run normally!")
        return cleared_count

def show_sync_status():
    """Show current sync status"""
    print("📊 Current Sync Status:")
    print("-" * 50)
    
    with get_db_session() as db:
        # Get recent sync records
        recent_syncs = db.query(SyncMetadata).order_by(
            SyncMetadata.last_sync_at.desc()
        ).limit(10).all()
        
        if not recent_syncs:
            print("📭 No sync records found")
            return
        
        for sync in recent_syncs:
            age = datetime.now(timezone.utc) - sync.last_sync_at
            status_emoji = {
                'success': '✅',
                'error': '❌', 
                'in_progress': '🔄',
                'skipped': '⏭️'
            }.get(sync.status, '❓')
            
            print(f"{status_emoji} {sync.sync_type} - {sync.status}")
            print(f"   Started: {sync.last_sync_at} ({age} ago)")
            if sync.error_message:
                print(f"   Error: {sync.error_message}")
            if sync.stats:
                print(f"   Stats: {sync.stats[:100]}...")
            print()

def main():
    """Main function with CLI argument parsing"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Clear Stuck Sync Records",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python clear_stuck_sync.py                    # Clear stuck records (>30 min old)
  python clear_stuck_sync.py --force           # Clear ALL in_progress records
  python clear_stuck_sync.py --status          # Show current sync status
  python clear_stuck_sync.py --non-interactive # Don't ask for confirmation
        """
    )
    
    parser.add_argument(
        '--force', 
        action='store_true',
        help='Clear ALL in_progress records regardless of age'
    )
    
    parser.add_argument(
        '--status', 
        action='store_true',
        help='Show current sync status and exit'
    )
    
    parser.add_argument(
        '--non-interactive', 
        action='store_true',
        help='Don\'t ask for confirmation before clearing'
    )
    
    args = parser.parse_args()
    
    print("🧹 Dendreo Stuck Sync Cleaner")
    print("=" * 50)
    
    try:
        if args.status:
            show_sync_status()
            return
        
        cleared_count = clear_stuck_syncs(
            force_all=args.force,
            interactive=not args.non_interactive
        )
        
        if cleared_count > 0:
            print()
            print("💡 Tip: You can now run a sync:")
            print("   python scripts/sync_dendreo.py")
            print()
            print("💡 Or check sync status:")
            print("   python scripts/clear_stuck_sync.py --status")
        
        sys.exit(0)
        
    except KeyboardInterrupt:
        print("\n🛑 Operation cancelled by user")
        sys.exit(130)
    except Exception as e:
        print(f"\n💥 Error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main() 