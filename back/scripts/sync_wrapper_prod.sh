#!/bin/bash
# Production Sync Wrapper Script for Cron
# This script properly handles the production cron environment

# Set PATH explicitly for cron environment
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"

# Set Python path
export PYTHONPATH="/app:$PYTHONPATH"

# Change to app directory
cd /app

# Log start
echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - Starting production sync process (PID: $$, Shell: $0)"

# Check if environment file exists and source it
if [ -f "/app/cron_env.sh" ]; then
    echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - Sourcing environment variables"
    . /app/cron_env.sh
else
    echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - No cron_env.sh found, using container environment"
fi

# Verify Python is available
if ! command -v python3 >/dev/null 2>&1; then
    echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - ERROR: python3 not found in PATH: $PATH"
    echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - Production sync process failed (PID: $$)"
    exit 1
fi

# Verify sync script exists
if [ ! -f "/app/scripts/sync_dendreo.py" ]; then
    echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - ERROR: sync_dendreo.py not found"
    echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - Production sync process failed (PID: $$)"
    exit 1
fi

# Check if sync_metadata table exists, create if needed
echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - Checking sync_metadata table..."
if ! python3 -c "from app.models.database import get_db_session; from app.models.models import SyncMetadata; from sqlalchemy import text; 
with get_db_session() as db:
    result = db.execute(text('SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = \'public\' AND table_name = \'sync_metadata\');')).fetchone()
    if not result[0]:
        print('sync_metadata table does not exist')
        exit(1)
    print('sync_metadata table exists')
" 2>/dev/null; then
    echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - sync_metadata table verified"
else
    echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - Creating sync_metadata table..."
    if python3 /app/scripts/setup_sync_table.py; then
        echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - sync_metadata table created successfully"
    else
        echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - ERROR: Failed to create sync_metadata table"
        echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - Production sync process failed (PID: $$)"
        exit 1
    fi
fi

# Run the sync with proper error handling
echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - Executing production sync script..."
echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - Environment: ${APP_ENV:-production}"
echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - ADF Limit: ${DENDREO_ADF_LIMIT:-unlimited}"

if python3 /app/scripts/sync_dendreo.py --log-level "${LOG_LEVEL:-INFO}" 2>&1; then
    echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - Production sync process completed successfully (PID: $$)"
    
    # Optional: Run HubSpot updates if configured
    if [ -n "${HUBSPOT_API_KEY}" ] && [ "${HUBSPOT_API_KEY}" != "your_hubspot_api_key_here" ]; then
        echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - Running HubSpot progression updates..."
        if python3 /app/update_hubspot_progression.py 2>&1; then
            echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - HubSpot updates completed successfully"
        else
            echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - WARNING: HubSpot updates failed (not critical)"
        fi
    fi
    
    exit 0
else
    echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - Production sync process failed with errors (PID: $$)"
    exit 1
fi 