#!/usr/bin/env python3
"""
Sync Health Check Script

This script checks the health of the sync system and provides monitoring capabilities.
Can be used by Docker healthcheck, monitoring systems, or manual diagnostics.
"""

import sys
import os
import json
from datetime import datetime, timezone, timedelta
from pathlib import Path

# Add the parent directory to the path so we can import from app
sys.path.insert(0, str(Path(__file__).parent.parent))

def check_database_connection():
    """Check if database is accessible"""
    try:
        from app.models.database import get_db_session
        from sqlalchemy import text
        
        with get_db_session() as db:
            result = db.execute(text('SELECT 1')).fetchone()
            return True, "Database connection successful"
    except Exception as e:
        return False, f"Database connection failed: {str(e)}"

def check_sync_metadata_table():
    """Check if sync_metadata table exists"""
    try:
        from app.models.database import get_db_session
        from app.models.models import SyncMetadata
        from sqlalchemy import text
        
        with get_db_session() as db:
            # Check if table exists
            result = db.execute(text(
                "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'sync_metadata');"
            )).fetchone()
            
            if not result[0]:
                return False, "sync_metadata table does not exist"
            
            # Check if we can query it
            sync_count = db.query(SyncMetadata).count()
            return True, f"sync_metadata table exists with {sync_count} records"
            
    except Exception as e:
        return False, f"Error checking sync_metadata table: {str(e)}"

def check_sync_status():
    """Check current sync status and detect issues"""
    try:
        from app.models.database import get_db_session
        from app.models.models import SyncMetadata
        
        with get_db_session() as db:
            # Get the most recent sync
            latest_sync = db.query(SyncMetadata).filter(
                SyncMetadata.sync_type == 'sync_all'
            ).order_by(SyncMetadata.last_sync_at.desc()).first()
            
            if not latest_sync:
                return False, "No sync records found"
            
            now = datetime.now(timezone.utc)
            sync_age = now - latest_sync.last_sync_at
            
            # Check for stuck syncs
            if latest_sync.status == 'in_progress':
                if sync_age > timedelta(minutes=30):
                    return False, f"Sync stuck in progress for {sync_age} (started: {latest_sync.last_sync_at})"
                else:
                    return True, f"Sync currently in progress for {sync_age} (started: {latest_sync.last_sync_at})"
            
            # Check for recent failures (but ignore manually cleared records)
            if latest_sync.status == 'error':
                if sync_age < timedelta(hours=24):
                    # If it was manually cleared, don't treat as a real failure
                    if latest_sync.error_message and "Manually cleared" in latest_sync.error_message:
                        return True, f"Previously stuck sync was manually cleared {sync_age} ago"
                    else:
                        return False, f"Recent sync failure {sync_age} ago: {latest_sync.error_message}"
            
            # Check for very old syncs
            if sync_age > timedelta(days=2):
                return False, f"Last sync too old: {sync_age} ago (status: {latest_sync.status})"
            
            # Check for successful recent sync
            if latest_sync.status == 'success' and sync_age < timedelta(hours=25):
                return True, f"Last successful sync: {sync_age} ago"
            
            return True, f"Latest sync status: {latest_sync.status} ({sync_age} ago)"
            
    except Exception as e:
        return False, f"Error checking sync status: {str(e)}"

def check_stuck_records():
    """Check for stuck sync records"""
    try:
        from app.models.database import get_db_session
        from app.models.models import SyncMetadata
        
        with get_db_session() as db:
            # Find stuck records (in_progress for more than 30 minutes)
            thirty_minutes_ago = datetime.now(timezone.utc) - timedelta(minutes=30)
            stuck_syncs = db.query(SyncMetadata).filter(
                SyncMetadata.status == 'in_progress',
                SyncMetadata.last_sync_at < thirty_minutes_ago
            ).count()
            
            if stuck_syncs > 0:
                return False, f"Found {stuck_syncs} stuck sync record(s)"
            
            return True, "No stuck sync records found"
            
    except Exception as e:
        return False, f"Error checking for stuck records: {str(e)}"

def check_recent_activity():
    """Check for recent sync activity (within last 48 hours)"""
    try:
        from app.models.database import get_db_session
        from app.models.models import SyncMetadata
        
        with get_db_session() as db:
            # Check for any activity in last 48 hours
            two_days_ago = datetime.now(timezone.utc) - timedelta(hours=48)
            recent_syncs = db.query(SyncMetadata).filter(
                SyncMetadata.last_sync_at > two_days_ago
            ).count()
            
            if recent_syncs == 0:
                return False, "No sync activity in the last 48 hours"
            
            # Check for successful syncs in last 48 hours
            successful_syncs = db.query(SyncMetadata).filter(
                SyncMetadata.last_sync_at > two_days_ago,
                SyncMetadata.status == 'success'
            ).count()
            
            if successful_syncs == 0:
                return False, f"No successful syncs in last 48 hours ({recent_syncs} attempts found)"
            
            return True, f"Found {successful_syncs} successful syncs in last 48 hours"
            
    except Exception as e:
        return False, f"Error checking recent activity: {str(e)}"

def run_health_checks():
    """Run all health checks and return results"""
    checks = [
        ("Database Connection", check_database_connection),
        ("Sync Metadata Table", check_sync_metadata_table),
        ("Sync Status", check_sync_status),
        ("Stuck Records", check_stuck_records),
        ("Recent Activity", check_recent_activity),
    ]
    
    results = {}
    overall_healthy = True
    
    for check_name, check_func in checks:
        try:
            is_healthy, message = check_func()
            results[check_name] = {
                "healthy": is_healthy,
                "message": message
            }
            if not is_healthy:
                overall_healthy = False
        except Exception as e:
            results[check_name] = {
                "healthy": False,
                "message": f"Check failed with exception: {str(e)}"
            }
            overall_healthy = False
    
    return overall_healthy, results

def print_health_report(overall_healthy, results):
    """Print a human-readable health report"""
    print("🏥 Dendreo Sync Health Check")
    print("=" * 50)
    print(f"Overall Status: {'✅ HEALTHY' if overall_healthy else '❌ UNHEALTHY'}")
    print(f"Timestamp: {datetime.now(timezone.utc)}")
    print()
    
    for check_name, result in results.items():
        status_emoji = "✅" if result["healthy"] else "❌"
        print(f"{status_emoji} {check_name}")
        print(f"   {result['message']}")
        print()

def main():
    """Main function with CLI argument parsing"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Dendreo Sync Health Check",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python sync_health_check.py                 # Human-readable report
  python sync_health_check.py --json         # JSON output
  python sync_health_check.py --nagios       # Nagios-compatible output
  python sync_health_check.py --exit-code    # Exit with non-zero if unhealthy
        """
    )
    
    parser.add_argument(
        '--json', 
        action='store_true',
        help='Output results in JSON format'
    )
    
    parser.add_argument(
        '--nagios', 
        action='store_true',
        help='Output in Nagios-compatible format'
    )
    
    parser.add_argument(
        '--exit-code', 
        action='store_true',
        help='Exit with non-zero code if unhealthy (useful for monitoring)'
    )
    
    parser.add_argument(
        '--quiet', 
        action='store_true',
        help='Suppress output (useful with --exit-code)'
    )
    
    args = parser.parse_args()
    
    try:
        overall_healthy, results = run_health_checks()
        
        if args.json:
            output = {
                "overall_healthy": overall_healthy,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "checks": results
            }
            print(json.dumps(output, indent=2))
        elif args.nagios:
            # Nagios output format
            status = "OK" if overall_healthy else "CRITICAL"
            failed_checks = [name for name, result in results.items() if not result["healthy"]]
            
            if failed_checks:
                message = f"Sync health issues: {', '.join(failed_checks)}"
            else:
                message = "All sync health checks passed"
            
            print(f"SYNC {status} - {message}")
        elif not args.quiet:
            print_health_report(overall_healthy, results)
        
        # Exit with appropriate code
        if args.exit_code:
            sys.exit(0 if overall_healthy else 1)
        else:
            sys.exit(0)
        
    except KeyboardInterrupt:
        if not args.quiet:
            print("\n🛑 Health check interrupted by user")
        sys.exit(130)
    except Exception as e:
        if not args.quiet:
            print(f"\n💥 Health check failed: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main() 