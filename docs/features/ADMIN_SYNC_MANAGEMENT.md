# Admin Sync Management Dashboard

## Overview

The Admin Sync Management Dashboard provides comprehensive control and monitoring of the Dendreo API synchronization system. It requires admin role privileges to access.

---

## Features

### 📊 API Usage Monitoring
Track API consumption across different time periods:
- **Last Sync**: API calls, duration, timestamp, status
- **Today**: Total API calls and sync count
- **This Week**: Last 7 days totals
- **This Month**: Current month totals

### ⚡ Sync Status
Real-time monitoring:
- Current sync status (running/idle)
- Last sync details (time, status, API calls, duration)
- Visual indicators for active syncs

### 🎮 Sync Actions
Execute sync operations manually:
- **Dry Run**: Test sync without making database changes
- **Force Sync**: Run full sync immediately (bypasses cooldown)
- **Sync Specific ADF**: Sync only one Action de Formation by ID

### ⚙️ Configuration
Control sync behavior:
- **Enable/Disable Cron Scheduling**: Turn scheduled syncs on/off
- **Cooldown Hours**: Set minimum time between syncs (prevents rapid re-syncing)

### 📜 Sync History
View recent sync operations:
- Timestamp, type, status
- API calls made
- Duration
- Error messages (if failed)

---

## Access

### Prerequisites
1. **Admin Role**: User must have `role='admin'` in the database
2. **Authentication**: Must be logged in with JWT token containing admin role

### URL
```
http://your-domain/admin/sync
```

### Navigation
- Sidebar menu: **Admin: Sync** (only visible to admin users)

---

## Installation & Setup

### 1. Run Database Migration

```bash
# Enter backend container
docker compose -f docker-compose.prod.yml exec backend bash

# Run migration script
python3 scripts/migrate_add_admin_features.py
```

This will:
- Add `role` column to `users` table
- Add API tracking columns to `sync_metadata` table
- Create `admin_sync_config` table
- Set first user as admin

### 2. Restart Services

```bash
# Restart backend to load new models
docker compose -f docker-compose.prod.yml restart backend

# Restart sync container to use updated config checks
docker compose -f docker-compose.prod.yml restart sync
```

### 3. Verify Admin Access

```bash
# Check database
docker compose -f docker-compose.prod.yml exec postgres \
  psql -U postgres -d dendreo_prod_db -c \
  "SELECT id, username, role FROM users;"
```

Expected output:
```
 id | username | role
----+----------+-------
  1 | admin    | admin
```

---

## Usage Guide

### Monitoring API Usage

**Dashboard automatically refreshes every 30 seconds**

View cumulative statistics:
- Check if approaching API quota limits
- Identify sync patterns (frequency, API usage)
- Compare current vs historical usage

### Running Manual Syncs

#### Dry Run (Recommended First)
```
1. Click "🧪 Run Dry Run"
2. Confirm the action
3. Wait for completion
4. Review output in the dashboard
```

**Use Case**: Test API connectivity and sync logic without making changes

#### Force Sync
```
1. Click "⚡ Force Sync Now"
2. Confirm (this WILL make API calls and DB changes)
3. Monitor progress (page shows "Sync in progress")
4. Check output when complete
```

**Use Case**: Emergency sync needed, bypass cooldown protection

#### Sync Specific ADF
```
1. Enter ADF ID in input field (e.g., "124")
2. Click "🎯 Sync ADF"
3. Confirm
4. Review results
```

**Use Case**: Update data for one specific Action de Formation without full sync

### Configuring Sync Behavior

#### Disable Scheduled Syncs
```
1. Uncheck "Enable Scheduled Cron Syncs"
2. Confirm
```

**Effect**:
- Cron job will NOT run syncs on schedule
- Manual syncs still work
- Useful during maintenance or API quota issues

**To Re-enable**:
- Check the box again
- Cron will resume on next scheduled time

#### Set Cooldown
```
1. Enter hours (e.g., 2.0 for 2 hours)
2. Click "Save"
3. Confirm
```

**Effect**:
- Prevents syncs from running too frequently
- Only applies to non-forced syncs (manual force sync bypasses this)
- Protects against accidental quota exhaustion

---

## API Endpoints

All admin endpoints require JWT with `role='admin'`:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/admin/sync/api-usage` | GET | Get API usage stats |
| `/api/admin/sync/dry-run` | POST | Execute dry-run sync |
| `/api/admin/sync/force` | POST | Force full sync |
| `/api/admin/sync/adf/{id}` | POST | Sync specific ADF |
| `/api/admin/sync/config` | GET | Get sync configuration |
| `/api/admin/sync/config` | PUT | Update configuration |
| `/api/admin/sync/status` | GET | Get current sync status |
| `/api/admin/sync/history` | GET | Get sync history |

### Example API Calls

```bash
# Get API usage (requires auth token)
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost/api/admin/sync/api-usage

# Disable cron scheduling
curl -X PUT -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"cron_enabled": false}' \
  http://localhost/api/admin/sync/config

# Force sync
curl -X POST -H "Authorization: Bearer $TOKEN" \
  http://localhost/api/admin/sync/force
```

---

## Troubleshooting

### "Admin access required" error

**Cause**: User does not have admin role

**Solution**:
```bash
# Set user as admin in database
docker compose -f docker-compose.prod.yml exec postgres \
  psql -U postgres -d dendreo_prod_db -c \
  "UPDATE users SET role='admin' WHERE username='your_username';"

# Log out and log back in to get new JWT with role
```

### Sync stuck in "running" state

**Cause**: Previous sync was interrupted

**Solution**:
```bash
# Clear stuck sync
docker compose -f docker-compose.prod.yml exec postgres \
  psql -U postgres -d dendreo_prod_db -c \
  "UPDATE sync_metadata SET status='error', error_message='Manually cleared' WHERE status='in_progress';"
```

### Cron toggle not working

**Cause**: Sync container needs restart to read new config

**Solution**:
```bash
docker compose -f docker-compose.prod.yml restart sync
```

### Actions timeout

**Cause**: Sync operations have 30-minute timeout

**Solution**: Wait for sync to complete or check container logs:
```bash
docker compose -f docker-compose.prod.yml logs -f sync
```

---

## Security Notes

- ⚠️ **Admin role has full sync control** - only grant to trusted users
- 🔒 **JWT tokens contain role claim** - re-login required after role changes
- 🔐 **All endpoints require authentication** - no public access
- 📝 **All admin actions are logged** - check backend logs for audit trail

---

## Database Schema

### users table
```sql
id               SERIAL PRIMARY KEY
username         VARCHAR(50) UNIQUE NOT NULL
hashed_password  VARCHAR(255) NOT NULL
role             VARCHAR(20) DEFAULT 'user' NOT NULL  -- NEW
is_active        BOOLEAN DEFAULT true
created_at       TIMESTAMP WITH TIME ZONE
updated_at       TIMESTAMP WITH TIME ZONE
```

### sync_metadata table
```sql
id                  SERIAL PRIMARY KEY
sync_type           VARCHAR NOT NULL
last_sync_at        TIMESTAMP WITH TIME ZONE NOT NULL
status              VARCHAR NOT NULL
stats               TEXT
error_message       TEXT
api_calls_count     INTEGER DEFAULT 0 NOT NULL      -- NEW
duration_seconds    FLOAT                            -- NEW
created_at          TIMESTAMP WITH TIME ZONE
updated_at          TIMESTAMP WITH TIME ZONE
```

### admin_sync_config table (NEW)
```sql
id                    SERIAL PRIMARY KEY
cron_enabled          BOOLEAN DEFAULT true NOT NULL
cooldown_hours        FLOAT DEFAULT 1.0 NOT NULL
last_updated_at       TIMESTAMP WITH TIME ZONE
updated_by_user_id    INTEGER REFERENCES users(id)
```

---

## Environment Variables

Works with existing sync control variables:

| Variable | Default | Effect |
|----------|---------|--------|
| `SKIP_STARTUP_SYNC` | `false` | Skip sync on container start |
| `DISABLE_CRON_SCHEDULE` | `false` | Don't setup cron at all |

**Admin config takes precedence over cron setup**:
- If `DISABLE_CRON_SCHEDULE=true`, cron is never setup
- If cron is setup but `admin_sync_config.cron_enabled=false`, cron exits early

---

## Development Notes

### Adding Admin Users

```bash
# Via database
docker compose -f docker-compose.prod.yml exec postgres \
  psql -U postgres -d dendreo_prod_db -c \
  "UPDATE users SET role='admin' WHERE username='username';"

# Via Python (in backend container)
python3 -c "
from app.models.database import get_db_session
from app.models.models import User
with get_db_session() as db:
    user = db.query(User).filter(User.username=='username').first()
    user.role = 'admin'
    db.commit()
    print(f'User {user.username} is now admin')
"
```

### Testing Admin Endpoints

```bash
# Get JWT token
TOKEN=$(curl -X POST http://localhost/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"your_password"}' \
  | jq -r '.access_token')

# Test admin endpoint
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost/api/admin/sync/status | jq
```

---

## Future Enhancements

Potential features for future versions:
- [ ] WebSocket streaming of sync progress
- [ ] Scheduled sync time configuration via UI
- [ ] Multi-user audit log
- [ ] API quota visualization charts
- [ ] Email notifications for sync failures
- [ ] Sync cancellation (stop running sync)
- [ ] Custom sync schedules per ADF
