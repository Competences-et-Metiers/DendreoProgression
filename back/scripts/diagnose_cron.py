#!/usr/bin/env python3
"""
Diagnostic Script for Cron Sync Issues
This script helps diagnose why the cron sync isn't running at 8 AM in production.
"""

import sys
import os
import subprocess
import logging
from datetime import datetime, timedelta
from pathlib import Path
import json
from typing import Dict, List, Optional

# Add the parent directory to the path so we can import from app
sys.path.insert(0, str(Path(__file__).parent.parent))

def setup_logging():
    """Setup logging configuration"""
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.StreamHandler(sys.stdout)
        ]
    )
    return logging.getLogger(__name__)

def check_cron_service():
    """Check if cron service is running"""
    logger = logging.getLogger(__name__)
    
    try:
        # Check if cron is running
        result = subprocess.run(['pgrep', '-f', 'cron'], capture_output=True, text=True)
        if result.returncode == 0:
            logger.info("✅ Cron service is running")
            logger.info(f"Cron PIDs: {result.stdout.strip()}")
            return True
        else:
            logger.error("❌ Cron service is not running")
            return False
    except Exception as e:
        logger.error(f"❌ Error checking cron service: {e}")
        return False

def check_cron_jobs():
    """Check what cron jobs are configured"""
    logger = logging.getLogger(__name__)
    
    try:
        # Check current user's cron jobs
        result = subprocess.run(['crontab', '-l'], capture_output=True, text=True)
        if result.returncode == 0:
            logger.info("✅ Cron jobs found:")
            for line in result.stdout.strip().split('\n'):
                if line.strip() and not line.startswith('#'):
                    logger.info(f"  {line}")
            return True
        else:
            logger.warning("⚠️  No cron jobs found for current user")
            return False
    except Exception as e:
        logger.error(f"❌ Error checking cron jobs: {e}")
        return False

def check_environment_variables():
    """Check if required environment variables are set"""
    logger = logging.getLogger(__name__)
    
    required_vars = [
        'DATABASE_URL',
        'DENDREO_API_KEY',
        'DENDREO_BASE_URL'
    ]
    
    missing_vars = []
    
    for var in required_vars:
        if not os.getenv(var):
            missing_vars.append(var)
    
    if missing_vars:
        logger.error(f"❌ Missing environment variables: {', '.join(missing_vars)}")
        return False
    else:
        logger.info("✅ All required environment variables are set")
        return True

def check_sync_script():
    """Check if the sync script exists and is executable"""
    logger = logging.getLogger(__name__)
    
    sync_script = Path('/app/scripts/sync_dendreo.py')
    wrapper_script = Path('/app/sync_wrapper_cron.sh')
    
    if not sync_script.exists():
        logger.error(f"❌ Sync script not found: {sync_script}")
        return False
    
    if not wrapper_script.exists():
        logger.error(f"❌ Sync wrapper script not found: {wrapper_script}")
        return False
    
    if not os.access(sync_script, os.X_OK):
        logger.error(f"❌ Sync script is not executable: {sync_script}")
        return False
    
    if not os.access(wrapper_script, os.X_OK):
        logger.error(f"❌ Sync wrapper script is not executable: {wrapper_script}")
        return False
    
    logger.info("✅ Sync scripts exist and are executable")
    return True

def check_database_connection():
    """Check if database is accessible"""
    logger = logging.getLogger(__name__)
    
    try:
        from app.models.database import get_db_session
        with get_db_session() as db:
            # Simple query to test connection
            result = db.execute('SELECT 1').fetchone()
            if result:
                logger.info("✅ Database connection is working")
                return True
            else:
                logger.error("❌ Database connection failed")
                return False
    except Exception as e:
        logger.error(f"❌ Database connection error: {e}")
        return False

def check_sync_logs():
    """Check recent sync logs"""
    logger = logging.getLogger(__name__)
    
    log_files = [
        '/app/logs/cron.log',
        '/app/logs/sync_dendreo.log',
        '/app/logs/sync.log'
    ]
    
    found_logs = False
    
    for log_file in log_files:
        log_path = Path(log_file)
        if log_path.exists():
            logger.info(f"📋 Found log file: {log_file}")
            found_logs = True
            
            # Show last 10 lines
            try:
                with open(log_path, 'r') as f:
                    lines = f.readlines()
                    if lines:
                        logger.info(f"Last 10 lines of {log_file}:")
                        for line in lines[-10:]:
                            logger.info(f"  {line.strip()}")
                    else:
                        logger.info(f"  (Log file is empty)")
            except Exception as e:
                logger.error(f"❌ Error reading log file {log_file}: {e}")
    
    if not found_logs:
        logger.warning("⚠️  No sync log files found")
    
    return found_logs

def check_sync_metadata():
    """Check sync metadata in database"""
    logger = logging.getLogger(__name__)
    
    try:
        from app.models.database import get_db_session
        from app.models.models import SyncMetadata
        
        with get_db_session() as db:
            # Get recent sync metadata
            recent_syncs = db.query(SyncMetadata).order_by(
                SyncMetadata.last_sync_at.desc()
            ).limit(5).all()
            
            if recent_syncs:
                logger.info("📊 Recent sync metadata:")
                for sync in recent_syncs:
                    logger.info(f"  {sync.last_sync_at}: {sync.sync_type} - {sync.status}")
                    if sync.error_message:
                        logger.info(f"    Error: {sync.error_message}")
                return True
            else:
                logger.warning("⚠️  No sync metadata found in database")
                return False
                
    except Exception as e:
        logger.error(f"❌ Error checking sync metadata: {e}")
        return False

def check_timezone():
    """Check system timezone"""
    logger = logging.getLogger(__name__)
    
    try:
        # Check system timezone
        result = subprocess.run(['date'], capture_output=True, text=True)
        if result.returncode == 0:
            logger.info(f"📅 System date/time: {result.stdout.strip()}")
        
        # Check timezone
        result = subprocess.run(['timedatectl', 'show', '--property=Timezone'], 
                              capture_output=True, text=True)
        if result.returncode == 0:
            timezone = result.stdout.strip().split('=')[1]
            logger.info(f"🌍 System timezone: {timezone}")
        
        return True
    except Exception as e:
        logger.error(f"❌ Error checking timezone: {e}")
        return False

def test_manual_sync():
    """Test running sync manually"""
    logger = logging.getLogger(__name__)
    
    try:
        logger.info("🧪 Testing manual sync execution...")
        
        # Test the sync wrapper script
        result = subprocess.run(['/app/sync_wrapper_cron.sh'], 
                              capture_output=True, text=True, timeout=300)
        
        if result.returncode == 0:
            logger.info("✅ Manual sync test successful")
            logger.info(f"Output: {result.stdout}")
            return True
        else:
            logger.error("❌ Manual sync test failed")
            logger.error(f"Error output: {result.stderr}")
            return False
            
    except subprocess.TimeoutExpired:
        logger.error("❌ Manual sync test timed out (5 minutes)")
        return False
    except Exception as e:
        logger.error(f"❌ Error testing manual sync: {e}")
        return False

def generate_recommendations(checks: Dict[str, bool]) -> List[str]:
    """Generate recommendations based on check results"""
    recommendations = []
    
    if not checks.get('cron_service'):
        recommendations.append("🔧 Start the cron service: service cron start")
    
    if not checks.get('cron_jobs'):
        recommendations.append("🔧 Add cron job manually: crontab -e")
    
    if not checks.get('environment_variables'):
        recommendations.append("🔧 Set missing environment variables in container")
    
    if not checks.get('sync_script'):
        recommendations.append("🔧 Check sync script permissions: chmod +x /app/scripts/sync_dendreo.py")
    
    if not checks.get('database_connection'):
        recommendations.append("🔧 Check database connection and credentials")
    
    if not checks.get('sync_logs'):
        recommendations.append("🔧 Check log directory permissions: mkdir -p /app/logs && chmod 755 /app/logs")
    
    if not checks.get('manual_sync'):
        recommendations.append("🔧 Debug sync script issues manually")
    
    return recommendations

def main():
    """Main diagnostic function"""
    logger = setup_logging()
    
    logger.info("=" * 60)
    logger.info("🔍 Dendreo Cron Sync Diagnostic Tool")
    logger.info("=" * 60)
    
    # Run all checks
    checks = {
        'cron_service': check_cron_service(),
        'cron_jobs': check_cron_jobs(),
        'environment_variables': check_environment_variables(),
        'sync_script': check_sync_script(),
        'database_connection': check_database_connection(),
        'sync_logs': check_sync_logs(),
        'sync_metadata': check_sync_metadata(),
        'timezone': check_timezone(),
        'manual_sync': test_manual_sync()
    }
    
    # Summary
    logger.info("=" * 60)
    logger.info("📊 Diagnostic Summary")
    logger.info("=" * 60)
    
    passed = sum(1 for result in checks.values() if result)
    total = len(checks)
    
    logger.info(f"Checks passed: {passed}/{total}")
    
    for check_name, result in checks.items():
        status = "✅ PASS" if result else "❌ FAIL"
        logger.info(f"{check_name.replace('_', ' ').title()}: {status}")
    
    # Generate recommendations
    recommendations = generate_recommendations(checks)
    
    if recommendations:
        logger.info("\n💡 Recommendations:")
        for rec in recommendations:
            logger.info(f"  {rec}")
    else:
        logger.info("\n🎉 All checks passed! Cron sync should be working.")
    
    logger.info("=" * 60)
    
    # Exit with appropriate code
    sys.exit(0 if passed == total else 1)

if __name__ == "__main__":
    main() 