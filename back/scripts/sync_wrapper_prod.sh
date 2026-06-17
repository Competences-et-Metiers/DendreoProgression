#!/bin/bash
# Production Sync Wrapper Script for Cron
# Cron runs this hourly. This script checks the DB-driven schedule config
# to decide whether to actually run a sync.

# Set PATH explicitly for cron environment
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"

# Set Python path
export PYTHONPATH="/app:$PYTHONPATH"

# Change to app directory
cd /app

# Log start
echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - Cron check started (PID: $$)"

# Source environment variables
if [ -f "/app/cron_env.sh" ]; then
    . /app/cron_env.sh
else
    echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - No cron_env.sh found, using container environment"
fi

# Verify Python is available
if ! command -v python3 >/dev/null 2>&1; then
    if [ -f "/usr/local/bin/python3" ]; then
        export PATH="/usr/local/bin:$PATH"
    elif [ -f "/usr/bin/python3" ]; then
        export PATH="/usr/bin:$PATH"
    else
        echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - ERROR: python3 not found"
        exit 1
    fi
fi

# Verify sync script exists
if [ ! -f "/app/scripts/sync_dendreo.py" ]; then
    echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - ERROR: sync_dendreo.py not found"
    exit 1
fi

# Comprehensive schedule check: cron_enabled, day, hour, cooldown
# Exit codes: 0=run, 10=disabled, 11=wrong day, 12=wrong hour, 13=cooldown, 1=error
echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - Checking schedule config..."
SCHEDULE_OUTPUT=$(python3 -c "
import sys, os
from datetime import datetime, timezone, timedelta
from zoneinfo import ZoneInfo
try:
    from app.models.database import get_db_session
    from app.models.models import AdminSyncConfig, SyncMetadata

    # Use container timezone (TZ env var, defaults to Europe/Paris)
    local_tz = ZoneInfo(os.environ.get('TZ', 'Europe/Paris'))
    now = datetime.now(local_tz)

    with get_db_session() as db:
        config = db.query(AdminSyncConfig).first()
        if not config:
            print('No config found - defaulting to run')
            sys.exit(0)

        # 1. Master toggle
        if not config.cron_enabled:
            print('Cron scheduling DISABLED')
            sys.exit(10)

        # 2. Day check (Mon=0..Sun=6)
        today_day = str(now.weekday())
        allowed_days = [d.strip() for d in config.schedule_days.split(',')]
        if today_day not in allowed_days:
            day_names = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']
            print(f'Not a scheduled day ({day_names[int(today_day)]}). Schedule: {config.schedule_days} (now={now.strftime(\"%H:%M %Z\")})')
            sys.exit(11)

        # 3. Hour check
        schedule_hour = int(config.schedule_time.split(':')[0])
        if now.hour != schedule_hour:
            print(f'Not scheduled hour (now={now.hour}:xx {now.tzname()}, schedule={config.schedule_time})')
            sys.exit(12)

        # 4. Cooldown: skip if last successful sync is recent enough
        if config.cooldown_hours > 0:
            cutoff = now - timedelta(hours=config.cooldown_hours)
            recent = db.query(SyncMetadata).filter(
                SyncMetadata.sync_type == 'sync_all',
                SyncMetadata.status == 'success',
                SyncMetadata.last_sync_at > cutoff
            ).first()
            if recent:
                age_h = (now - recent.last_sync_at.astimezone(local_tz)).total_seconds() / 3600
                print(f'Last sync {age_h:.1f}h ago (cooldown={config.cooldown_hours}h) - skipping')
                sys.exit(13)

        print(f'All checks passed - sync should run (local time: {now.strftime(\"%H:%M %Z\")})')
        sys.exit(0)
except Exception as e:
    print(f'Schedule check error: {e}')
    sys.exit(1)
" 2>&1)
SCHEDULE_EXIT=$?

echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - $SCHEDULE_OUTPUT"

case $SCHEDULE_EXIT in
    0)
        echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - Running scheduled sync..."
        ;;
    10)
        exit 0
        ;;
    11|12|13)
        exit 0
        ;;
    1)
        echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - Schedule check failed, running sync as fallback"
        ;;
    *)
        echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - Unexpected exit code $SCHEDULE_EXIT, running sync as fallback"
        ;;
esac

# Clean up stuck sync records
if [ -f "/app/scripts/clear_stuck_sync.py" ]; then
    python3 /app/scripts/clear_stuck_sync.py --non-interactive 2>&1 || true
fi

# Run sync (30 min timeout)
SYNC_TIMEOUT=1800

# Live log file paths (shared volume with backend container for admin dashboard)
LIVE_LOG="/app/logs/sync_live.log"
API_COUNTERS="/app/logs/sync_api_counters.json"

# Clear live log files so the frontend starts fresh
> "$LIVE_LOG"
echo '{"dendreo": 0, "hubspot": 0}' > "$API_COUNTERS"

# Run sync — tee sends output to both stdout (cron.log) and the live log file
timeout $SYNC_TIMEOUT python3 -u /app/scripts/sync_dendreo.py --force --log-level "${LOG_LEVEL:-INFO}" 2>&1 | tee "$LIVE_LOG"
SYNC_EXIT_CODE=${PIPESTATUS[0]}

if [ "$SYNC_EXIT_CODE" -eq 0 ]; then
    echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - Sync completed successfully (PID: $$)"
    # Note: EDOF deal auto-linking now runs inside sync_dendreo.py; the obsolete
    # HubSpot progression push has been removed.

    exit 0
else
    if [ "$SYNC_EXIT_CODE" -eq 124 ]; then
        echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - ERROR: Sync timed out after ${SYNC_TIMEOUT}s"
        if [ -f "/app/scripts/clear_stuck_sync.py" ]; then
            python3 /app/scripts/clear_stuck_sync.py --force --non-interactive 2>&1 || true
        fi
    else
        echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') - Sync failed with exit code $SYNC_EXIT_CODE"
    fi
    exit 1
fi
