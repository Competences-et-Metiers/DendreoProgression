#!/usr/bin/env python3
"""
Comprehensive Sync Status Checker
Works even when database tables don't exist or have issues
"""

import sys
import os
import subprocess
import json
from datetime import datetime, timedelta
from pathlib import Path
import logging

# Add the parent directory to the path so we can import from app
sys.path.insert(0, str(Path(__file__).parent.parent))

def setup_logging():
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )
    return logging.getLogger(__name__)

def check_cron_status():
    """Check if cron is running and configured"""
    logger = logging.getLogger(__name__)
    status = {"cron_running": False, "cron_jobs": [], "issues": []}
    
    try:
        # Check if cron is running - try multiple methods
        cron_running = False
        
        # Method 1: Try pgrep
        try:
            result = subprocess.run(['pgrep', '-f', 'cron'], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                cron_running = True
        except FileNotFoundError:
            pass
        
        # Method 2: Try ps if pgrep not available
        if not cron_running:
            try:
                result = subprocess.run(['ps', 'aux'], 
                                      capture_output=True, text=True)
                if result.returncode == 0 and 'cron' in result.stdout:
                    cron_running = True
            except FileNotFoundError:
                pass
        
        # Method 3: Check if cron service file exists
        if not cron_running:
            try:
                result = subprocess.run(['service', 'cron', 'status'], 
                                      capture_output=True, text=True)
                if result.returncode == 0:
                    cron_running = True
            except FileNotFoundError:
                pass
        
        status["cron_running"] = cron_running
        if cron_running:
            logger.info("✅ Cron service is running")
        else:
            status["issues"].append("Cron service not running or not detectable")
            logger.warning("⚠️  Cron service not running or not detectable")
        
        # Check cron jobs
        try:
            result = subprocess.run(['crontab', '-l'], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                jobs = [line.strip() for line in result.stdout.strip().split('\n') 
                       if line.strip() and not line.startswith('#')]
                status["cron_jobs"] = jobs
                logger.info(f"✅ Found {len(jobs)} cron jobs")
                for job in jobs:
                    logger.info(f"  {job}")
            else:
                status["issues"].append("No cron jobs found")
                logger.warning("⚠️  No cron jobs found")
        except Exception as e:
            status["issues"].append(f"Error checking cron jobs: {e}")
            logger.error(f"❌ Error checking cron jobs: {e}")
            
    except Exception as e:
        status["issues"].append(f"Error checking cron: {e}")
        logger.error(f"❌ Error checking cron: {e}")
    
    return status

def check_log_files():
    """Check log files for sync activity"""
    logger = logging.getLogger(__name__)
    status = {"log_files": {}, "recent_activity": [], "issues": []}
    
    log_files = [
        "/app/logs/cron.log",
        "/app/logs/sync_dendreo.log", 
        "/app/logs/test_sync_20250710.log",
        "/app/logs/sync.log"
    ]
    
    for log_file in log_files:
        log_path = Path(log_file)
        if log_path.exists():
            try:
                stat = log_path.stat()
                status["log_files"][log_file] = {
                    "exists": True,
                    "size": stat.st_size,
                    "modified": datetime.fromtimestamp(stat.st_mtime).isoformat(),
                    "recent": (datetime.now() - datetime.fromtimestamp(stat.st_mtime)) < timedelta(hours=1)
                }
                
                # Read last few lines
                with open(log_path, 'r') as f:
                    lines = f.readlines()
                    if lines:
                        last_lines = lines[-5:]  # Last 5 lines
                        status["log_files"][log_file]["last_lines"] = [line.strip() for line in last_lines]
                        
                        # Look for success/error indicators
                        recent_text = ''.join(last_lines).lower()
                        if 'completed successfully' in recent_text or 'sync completed' in recent_text or 'sync test successful' in recent_text:
                            status["recent_activity"].append(f"SUCCESS in {log_file}")
                        elif 'error' in recent_text or 'failed' in recent_text:
                            status["recent_activity"].append(f"ERROR in {log_file}")
                        elif 'starting sync' in recent_text or 'sync process' in recent_text:
                            status["recent_activity"].append(f"ACTIVITY in {log_file}")
                
                logger.info(f"📋 {log_file}: {stat.st_size} bytes, modified {status['log_files'][log_file]['modified']}")
                
            except Exception as e:
                status["log_files"][log_file] = {"exists": True, "error": str(e)}
                status["issues"].append(f"Error reading {log_file}: {e}")
        else:
            status["log_files"][log_file] = {"exists": False}
    
    return status

def check_database_status():
    """Check database connection and tables"""
    logger = logging.getLogger(__name__)
    status = {"db_connected": False, "tables_exist": {}, "issues": []}
    
    try:
        from app.models.database import get_db_session
        from sqlalchemy import text
        
        with get_db_session() as db:
            # Test basic connection
            result = db.execute(text('SELECT 1')).fetchone()
            if result:
                status["db_connected"] = True
                logger.info("✅ Database connection working")
                
                # Check for important tables
                tables_to_check = ['sync_metadata', 'participants', 'courses', 'modules']
                
                for table in tables_to_check:
                    try:
                        result = db.execute(text(f"""
                            SELECT EXISTS (
                                SELECT FROM information_schema.tables 
                                WHERE table_schema = 'public' 
                                AND table_name = '{table}'
                            );
                        """)).fetchone()
                        
                        if result[0]:
                            # Get row count
                            count_result = db.execute(text(f"SELECT COUNT(*) FROM {table}")).fetchone()
                            status["tables_exist"][table] = {
                                "exists": True, 
                                "row_count": count_result[0] if count_result else 0
                            }
                            logger.info(f"✅ Table {table}: {status['tables_exist'][table]['row_count']} rows")
                        else:
                            status["tables_exist"][table] = {"exists": False}
                            status["issues"].append(f"Table {table} does not exist")
                            logger.warning(f"⚠️  Table {table} does not exist")
                            
                    except Exception as e:
                        status["tables_exist"][table] = {"exists": False, "error": str(e)}
                        status["issues"].append(f"Error checking table {table}: {e}")
            else:
                status["issues"].append("Database connection test failed")
                
    except Exception as e:
        status["issues"].append(f"Database error: {e}")
        logger.error(f"❌ Database error: {e}")
    
    return status

def check_environment():
    """Check environment variables"""
    logger = logging.getLogger(__name__)
    status = {"env_vars": {}, "issues": []}
    
    required_vars = [
        'DATABASE_URL', 'DENDREO_API_KEY', 'DENDREO_BASE_URL',
        'APP_ENV', 'LOG_LEVEL', 'SYNC_SCHEDULE'
    ]
    
    for var in required_vars:
        value = os.getenv(var)
        if value:
            # Don't log sensitive values fully
            if 'key' in var.lower() or 'password' in var.lower():
                display_value = value[:8] + "..." if len(value) > 8 else "***"
            else:
                display_value = value
            
            status["env_vars"][var] = {"set": True, "value": display_value}
            logger.info(f"✅ {var}: {display_value}")
        else:
            status["env_vars"][var] = {"set": False}
            status["issues"].append(f"Environment variable {var} not set")
            logger.warning(f"⚠️  {var}: Not set")
    
    return status

def check_container_processes():
    """Check what processes are running in the container"""
    logger = logging.getLogger(__name__)
    status = {"processes": [], "issues": []}
    
    try:
        # Check running processes
        result = subprocess.run(['ps', 'aux'], capture_output=True, text=True)
        if result.returncode == 0:
            processes = result.stdout.strip().split('\n')
            for process in processes:
                if any(keyword in process.lower() for keyword in ['cron', 'python', 'sync']):
                    status["processes"].append(process.strip())
                    logger.info(f"🔍 Process: {process.strip()}")
        else:
            status["issues"].append("Could not check processes")
            
    except Exception as e:
        status["issues"].append(f"Error checking processes: {e}")
        logger.error(f"❌ Error checking processes: {e}")
    
    return status

def analyze_sync_success():
    """Analyze all indicators to determine if sync is working"""
    logger = logging.getLogger(__name__)
    
    logger.info("🔍 Analyzing sync status...")
    
    cron_status = check_cron_status()
    log_status = check_log_files()
    db_status = check_database_status()
    env_status = check_environment()
    process_status = check_container_processes()
    
    # Overall analysis
    issues = []
    issues.extend(cron_status.get("issues", []))
    issues.extend(log_status.get("issues", []))
    issues.extend(db_status.get("issues", []))
    issues.extend(env_status.get("issues", []))
    issues.extend(process_status.get("issues", []))
    
    success_indicators = len(log_status.get("recent_activity", []))
    cron_configured = len(cron_status.get("cron_jobs", [])) > 0
    db_working = db_status.get("db_connected", False)
    
    # Check if cron or sync processes are running
    sync_processes = len(process_status.get("processes", []))
    
    overall_status = {
        "sync_likely_working": success_indicators > 0 and (cron_configured or sync_processes > 0),
        "cron_configured": cron_configured,
        "database_accessible": db_working,
        "recent_activity": success_indicators,
        "active_processes": sync_processes,
        "total_issues": len(issues),
        "issues": issues,
        "recommendations": []
    }
    
    # Generate recommendations
    if not cron_configured and sync_processes == 0:
        overall_status["recommendations"].append("Configure cron jobs or check if sync service is running")
    if not db_working:
        overall_status["recommendations"].append("Fix database connection")
    if 'Table sync_metadata does not exist' in str(issues):
        overall_status["recommendations"].append("Run: python3 scripts/setup_sync_table.py")
    if success_indicators == 0:
        overall_status["recommendations"].append("Run manual sync test")
    
    return {
        "timestamp": datetime.utcnow().isoformat(),
        "cron": cron_status,
        "logs": log_status,
        "database": db_status,
        "environment": env_status,
        "processes": process_status,
        "overall": overall_status
    }

def main():
    logger = setup_logging()
    
    logger.info("=" * 60)
    logger.info("🔍 Comprehensive Sync Status Check")
    logger.info("=" * 60)
    
    try:
        status = analyze_sync_success()
        
        # Print summary
        overall = status["overall"]
        logger.info("📊 SUMMARY:")
        logger.info(f"  Sync likely working: {'✅ YES' if overall['sync_likely_working'] else '❌ NO'}")
        logger.info(f"  Cron configured: {'✅ YES' if overall['cron_configured'] else '❌ NO'}")
        logger.info(f"  Database accessible: {'✅ YES' if overall['database_accessible'] else '❌ NO'}")
        logger.info(f"  Active processes: {overall['active_processes']}")
        logger.info(f"  Recent activity indicators: {overall['recent_activity']}")
        logger.info(f"  Total issues: {overall['total_issues']}")
        
        # Show recent activities
        if status["logs"]["recent_activity"]:
            logger.info("\n🔍 RECENT ACTIVITY:")
            for activity in status["logs"]["recent_activity"]:
                logger.info(f"  • {activity}")
        
        if overall["recommendations"]:
            logger.info("\n💡 RECOMMENDATIONS:")
            for rec in overall["recommendations"]:
                logger.info(f"  • {rec}")
        
        if overall["issues"]:
            logger.info("\n⚠️  ISSUES:")
            for issue in overall["issues"]:
                logger.info(f"  • {issue}")
        
        # Save detailed status to file
        status_file = Path("/app/logs/sync_status.json")
        status_file.parent.mkdir(exist_ok=True)
        with open(status_file, 'w') as f:
            json.dump(status, f, indent=2)
        
        logger.info(f"\n📄 Detailed status saved to: {status_file}")
        logger.info("=" * 60)
        
        # Exit code based on overall status
        if overall["sync_likely_working"]:
            sys.exit(0)
        elif overall["total_issues"] <= 2:
            sys.exit(1)  # Minor issues
        else:
            sys.exit(2)  # Major issues
            
    except Exception as e:
        logger.error(f"💥 Error during status check: {e}")
        sys.exit(3)

if __name__ == "__main__":
    main() 