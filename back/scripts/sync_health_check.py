#!/usr/bin/env python3
"""
Dendreo Sync Health Check Script
Monitors the sync process and reports status, can be used for monitoring systems.
"""

import sys
import json
import logging
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, Any

# Add the parent directory to the path
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.config.settings import settings
from app.models.database import get_db_session
from app.models.models import SyncMetadata

# Configure logging
logging.basicConfig(
    level=logging.WARNING,  # Only show warnings and errors
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def get_sync_health() -> Dict[str, Any]:
    """
    Get the health status of the sync process
    
    Returns:
        Dictionary with health status information
    """
    try:
        with get_db_session() as db:
            # Get the latest sync metadata
            sync_metadata = db.query(SyncMetadata).filter(
                SyncMetadata.sync_type == 'sync_all'
            ).order_by(SyncMetadata.last_sync_at.desc()).first()
            
            if not sync_metadata:
                return {
                    "status": "unknown",
                    "message": "No sync metadata found",
                    "last_sync_at": None,
                    "health_score": 0
                }
            
            now = datetime.utcnow()
            last_sync = sync_metadata.last_sync_at
            
            # Calculate time since last sync
            time_since_sync = now - last_sync if last_sync else None
            
            # Determine health status
            health_status = "healthy"
            health_score = 100
            messages = []
            
            # Check if sync is stuck "in progress"
            if sync_metadata.status == 'in_progress':
                if time_since_sync and time_since_sync > timedelta(hours=2):
                    health_status = "critical"
                    health_score = 0
                    messages.append("Sync has been in progress for more than 2 hours")
                else:
                    health_status = "warning"
                    health_score = 50
                    messages.append("Sync is currently in progress")
            
            # Check if last sync failed
            elif sync_metadata.status == 'error':
                health_status = "critical"
                health_score = 0
                messages.append(f"Last sync failed: {sync_metadata.error_message}")
            
            # Check if sync is overdue (daily sync schedule)
            elif sync_metadata.status == 'success':
                if time_since_sync:
                    if time_since_sync > timedelta(hours=26):  # Allow 2 hours buffer for daily sync
                        health_status = "critical"
                        health_score = 0
                        messages.append("No successful sync in over 26 hours")
                    elif time_since_sync > timedelta(hours=25):  # Warning at 25 hours
                        health_status = "warning"
                        health_score = 30
                        messages.append("Sync is overdue (expected daily)")
                    else:
                        messages.append("Sync is up to date")
            
            # Parse stats if available
            stats = {}
            if sync_metadata.stats:
                try:
                    stats = json.loads(sync_metadata.stats)
                except json.JSONDecodeError:
                    pass
            
            return {
                "status": health_status,
                "message": "; ".join(messages) if messages else "No issues detected",
                "last_sync_at": last_sync.isoformat() if last_sync else None,
                "last_sync_status": sync_metadata.status,
                "time_since_sync_hours": time_since_sync.total_seconds() / 3600 if time_since_sync else None,
                "health_score": health_score,
                "stats": stats,
                "error_message": sync_metadata.error_message if sync_metadata.status == 'error' else None
            }
            
    except Exception as e:
        return {
            "status": "critical",
            "message": f"Health check failed: {str(e)}",
            "last_sync_at": None,
            "health_score": 0
        }

def main():
    """Main function with CLI output"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Dendreo Sync Health Check",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument(
        '--format',
        choices=['human', 'json'],
        default='human',
        help='Output format'
    )
    
    parser.add_argument(
        '--nagios',
        action='store_true',
        help='Output in Nagios/Icinga format'
    )
    
    parser.add_argument(
        '--exit-code',
        action='store_true',
        help='Exit with code based on health status'
    )
    
    args = parser.parse_args()
    
    # Get health status
    health = get_sync_health()
    
    # Format output
    if args.format == 'json':
        print(json.dumps(health, indent=2))
    elif args.nagios:
        # Nagios format
        status_map = {
            'healthy': 'OK',
            'warning': 'WARNING',
            'critical': 'CRITICAL',
            'unknown': 'UNKNOWN'
        }
        
        nagios_status = status_map.get(health['status'], 'UNKNOWN')
        print(f"SYNC {nagios_status} - {health['message']}")
        
        if health.get('last_sync_at'):
            print(f"Last sync: {health['last_sync_at']}")
        if health.get('time_since_sync_hours'):
            print(f"Hours since last sync: {health['time_since_sync_hours']:.1f}")
    else:
        # Human readable format
        print("=" * 50)
        print("🔍 Dendreo Sync Health Check")
        print("=" * 50)
        
        # Status with emoji
        status_emoji = {
            'healthy': '✅',
            'warning': '⚠️',
            'critical': '❌',
            'unknown': '❓'
        }
        
        emoji = status_emoji.get(health['status'], '❓')
        print(f"Status: {emoji} {health['status'].upper()}")
        print(f"Message: {health['message']}")
        print(f"Health Score: {health['health_score']}/100")
        
        if health.get('last_sync_at'):
            print(f"Last Sync: {health['last_sync_at']}")
        
        if health.get('time_since_sync_hours'):
            print(f"Time Since Last Sync: {health['time_since_sync_hours']:.1f} hours")
        
        if health.get('last_sync_status'):
            print(f"Last Sync Status: {health['last_sync_status']}")
        
        if health.get('error_message'):
            print(f"Error: {health['error_message']}")
        
        if health.get('stats'):
            print("\nLast Sync Statistics:")
            for key, value in health['stats'].items():
                print(f"  {key}: {value}")
    
    # Exit with appropriate code
    if args.exit_code:
        exit_codes = {
            'healthy': 0,
            'warning': 1,
            'critical': 2,
            'unknown': 3
        }
        sys.exit(exit_codes.get(health['status'], 3))

if __name__ == "__main__":
    main() 