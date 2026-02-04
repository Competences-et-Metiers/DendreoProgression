# Database Migration Guide

This guide explains how to migrate the Dendreo Progression database from one production deployment to another without re-syncing from the Dendreo API.

## Overview

When deploying to a new machine, you can avoid consuming your Dendreo API quota by:
1. Creating a database backup on the source machine
2. Transferring the backup to the target machine
3. Restoring the backup on the target machine

This preserves all participant data, progression history, and sync metadata.

---

## Prerequisites

- SSH access to both source and target machines
- Docker installed and running on both machines
- Sufficient disk space for the database dump (~100MB-1GB depending on data size)
- Source database running and accessible

---

## Migration Process

### Step 1: Create Database Backup on Source Machine

SSH into your **source machine** (current production):

```bash
ssh user@source-machine
cd /path/to/DendreoProgression
```

**Option A: Backup using Docker exec (Recommended)**

```bash
# Create backup directory
mkdir -p backups

# Create database dump
docker exec dendreo-postgres pg_dump -U postgres -d dendreo_progression \
  --format=custom \
  --file=/tmp/dendreo_backup.dump

# Copy dump from container to host
docker cp dendreo-postgres:/tmp/dendreo_backup.dump ./backups/dendreo_backup_$(date +%Y%m%d_%H%M%S).dump

# Verify backup was created
ls -lh backups/
```

**Option B: Backup using pg_dump from host**

```bash
# If you have PostgreSQL client installed on the host
mkdir -p backups

pg_dump -h localhost -p 5432 -U postgres -d dendreo_progression \
  --format=custom \
  --file=./backups/dendreo_backup_$(date +%Y%m%d_%H%M%S).dump

# Enter password when prompted (from .env file)
```

**What the backup includes:**
- All tables (participants, courses, modules, participant_courses, etc.)
- All data and relationships
- Sequences and indexes
- Database schema

---

### Step 2: Transfer Backup to Target Machine

**Option A: Direct SCP Transfer**

```bash
# From source machine, transfer to target
scp ./backups/dendreo_backup_*.dump user@target-machine:/tmp/

# OR from your local machine
scp user@source-machine:/path/to/DendreoProgression/backups/dendreo_backup_*.dump \
    user@target-machine:/tmp/
```

**Option B: Via Intermediate Machine**

```bash
# Download from source to local machine
scp user@source-machine:/path/to/DendreoProgression/backups/dendreo_backup_*.dump ~/Downloads/

# Upload from local machine to target
scp ~/Downloads/dendreo_backup_*.dump user@target-machine:/tmp/
```

**Option C: Using rsync (for large files)**

```bash
rsync -avz --progress \
  ./backups/dendreo_backup_*.dump \
  user@target-machine:/tmp/
```

---

### Step 3: Prepare Target Machine

SSH into your **target machine** (new deployment):

```bash
ssh user@target-machine
cd /path/to/DendreoProgression
```

**Clone the repository** (if not already done):

```bash
git clone https://github.com/your-org/DendreoProgression.git
cd DendreoProgression
```

**Set up environment variables**:

```bash
# Copy example env file
cp .env.example .env

# Edit with your credentials (use same DB password for easier migration)
nano .env
```

**Important:** Make sure `POSTGRES_PASSWORD` matches the source database password, or you'll need to reset it after restore.

---

### Step 4: Deploy and Stop Sync

**Deploy the application** (this creates the database container):

```bash
./deploy-prod.sh
```

**Stop the sync cron job** (to prevent it from running during migration):

```bash
docker exec -it dendreo-sync crontab -r
# Or temporarily stop the container
docker stop dendreo-sync
```

---

### Step 5: Restore Database on Target Machine

#### Option A: Using the Automated Restore Script (Recommended)

The `restore-database.sh` script handles everything, including overwriting existing data:

```bash
./scripts/restore-database.sh /tmp/dendreo_backup_*.dump
```

The script will:
1. Ask for confirmation before overwriting
2. Stop sync container automatically
3. Drop the existing database completely
4. Create a fresh database
5. Restore all data from backup
6. Verify the restoration

**This works even if:**
- The database already has data from a previous sync
- The database was partially populated
- There are active connections to the database

#### Option B: Manual Restoration (Advanced)

If you prefer to do it manually or the script fails:

**1. Stop all connections to the database**:

```bash
# Terminate all active connections
docker exec -it dendreo-postgres psql -U postgres -c \
  "SELECT pg_terminate_backend(pid) FROM pg_stat_activity
   WHERE datname = 'dendreo_progression' AND pid <> pg_backend_pid();"
```

**2. Drop and recreate the database**:

```bash
# Access PostgreSQL container
docker exec -it dendreo-postgres psql -U postgres

# Inside psql
DROP DATABASE IF EXISTS dendreo_progression;
CREATE DATABASE dendreo_progression;
\q
```

**3. Copy backup into container**:

```bash
docker cp /tmp/dendreo_backup_*.dump dendreo-postgres:/tmp/dendreo_backup.dump
```

**4. Restore the database**:

```bash
docker exec -it dendreo-postgres pg_restore \
  -U postgres \
  -d dendreo_progression \
  --clean \
  --if-exists \
  --no-owner \
  --no-privileges \
  /tmp/dendreo_backup.dump
```

**Explanation of flags:**
- `--clean`: Drop database objects before recreating them
- `--if-exists`: Use IF EXISTS when dropping objects (prevents errors)
- `--no-owner`: Don't set ownership of objects
- `--no-privileges`: Don't restore access privileges

**If you see warnings about existing objects**, that's normal. The `--clean` flag ensures old data is removed first.

---

### Step 6: Verify Migration

**Check database size and tables**:

```bash
docker exec -it dendreo-postgres psql -U postgres -d dendreo_progression

-- Inside psql, run:
\dt  -- List all tables

-- Check row counts
SELECT 'participants' as table_name, COUNT(*) as rows FROM participants
UNION ALL
SELECT 'courses', COUNT(*) FROM courses
UNION ALL
SELECT 'modules', COUNT(*) FROM modules
UNION ALL
SELECT 'participant_courses', COUNT(*) FROM participant_courses
UNION ALL
SELECT 'sync_metadata', COUNT(*) FROM sync_metadata;

-- Check last sync time
SELECT sync_type, last_sync_at, status
FROM sync_metadata
ORDER BY last_sync_at DESC
LIMIT 5;

\q
```

**Verify the frontend and API**:

```bash
# Check API health
curl http://localhost:8000/api/courses/stats

# Check frontend (if deployed)
curl http://localhost:3000
```

**Test the application**:
1. Open the frontend in a browser
2. Navigate to Dashboard - should show statistics
3. Navigate to Participants - should show imported data
4. Navigate to Inactive Management - should show inactive participants
5. Check that no sync is running automatically

---

### Step 7: Re-enable Sync (Optional)

If you want to enable scheduled syncs on the new machine:

```bash
# Start sync container
docker start dendreo-sync

# Verify cron job is configured
docker exec -it dendreo-sync crontab -l

# Manually trigger a sync to test
docker exec -it dendreo-sync python /app/scripts/sync_dendreo.py

# Check sync logs
docker logs dendreo-sync -f
```

---

## Overwriting an Existing Database

If the target machine already has a database with data (from a previous sync or deployment), you have two options:

### Option 1: Complete Overwrite (Recommended)

Use the restore script - it automatically handles existing data:

```bash
./scripts/restore-database.sh /tmp/dendreo_backup_*.dump
```

**What it does:**
1. Stops sync to prevent conflicts
2. Terminates all database connections
3. **Drops the entire database** (all existing data is deleted)
4. Creates a fresh empty database
5. Restores your backup data

**This is safe because:**
- You're explicitly confirming the overwrite
- The old database is completely removed first
- No risk of data mixing or corruption
- Clean slate for the restored data

### Option 2: Force Overwrite Without Script

If you need to manually force an overwrite:

```bash
# 1. Stop all services using the database
docker stop dendreo-backend dendreo-sync

# 2. Force terminate all connections
docker exec -it dendreo-postgres psql -U postgres -c \
  "SELECT pg_terminate_backend(pid) FROM pg_stat_activity
   WHERE datname = 'dendreo_progression' AND pid <> pg_backend_pid();"

# 3. Drop database (force)
docker exec -it dendreo-postgres psql -U postgres -c \
  "DROP DATABASE IF EXISTS dendreo_progression WITH (FORCE);"

# 4. Create fresh database
docker exec -it dendreo-postgres psql -U postgres -c \
  "CREATE DATABASE dendreo_progression;"

# 5. Restore backup
docker cp /tmp/dendreo_backup_*.dump dendreo-postgres:/tmp/dendreo_backup.dump
docker exec -it dendreo-postgres pg_restore \
  -U postgres \
  -d dendreo_progression \
  --clean \
  --if-exists \
  --no-owner \
  --no-privileges \
  /tmp/dendreo_backup.dump

# 6. Restart services
docker start dendreo-backend
# Start sync later after verification
```

### What Gets Overwritten

When you restore over an existing database, **everything is replaced**:

| Data Type | Action |
|-----------|--------|
| Participants | ✅ Completely replaced with source data |
| Courses | ✅ Completely replaced with source data |
| Modules | ✅ Completely replaced with source data |
| Progression history | ✅ Completely replaced with source data |
| Sync metadata | ✅ Completely replaced (preserves source sync times) |
| User accounts | ✅ Completely replaced with source data |
| All other tables | ✅ Completely replaced with source data |

**Nothing from the old database is kept** - it's a complete replacement.

### Common Scenarios

**Scenario 1: Target has test data, you want production data**
```bash
# Simple - just restore. Test data will be completely removed.
./scripts/restore-database.sh /tmp/production_backup.dump
```

**Scenario 2: Target ran a sync, you want to replace it**
```bash
# Stops sync automatically, replaces all synced data
./scripts/restore-database.sh /tmp/source_backup.dump
```

**Scenario 3: Target has old data, you want fresh data**
```bash
# Complete replacement, no mixing of old and new
./scripts/restore-database.sh /tmp/latest_backup.dump
```

**Scenario 4: You want to reset to a known good state**
```bash
# Restore from a backup taken at a specific point in time
./scripts/restore-database.sh /tmp/dendreo_backup_20260204_100000.dump
```

---

## Troubleshooting

### Issue: "Database is being accessed by other users" error

This happens when trying to drop a database that has active connections.

**Solution A: Force disconnect and drop (PostgreSQL 13+)**

```bash
docker exec -it dendreo-postgres psql -U postgres -c \
  "DROP DATABASE dendreo_progression WITH (FORCE);"
```

**Solution B: Terminate connections manually (any version)**

```bash
# Stop services first
docker stop dendreo-backend dendreo-sync

# Terminate all connections
docker exec -it dendreo-postgres psql -U postgres -c \
  "SELECT pg_terminate_backend(pid) FROM pg_stat_activity
   WHERE datname = 'dendreo_progression' AND pid <> pg_backend_pid();"

# Now drop database
docker exec -it dendreo-postgres psql -U postgres -c \
  "DROP DATABASE dendreo_progression;"

# Recreate and restore
docker exec -it dendreo-postgres psql -U postgres -c \
  "CREATE DATABASE dendreo_progression;"
```

**Solution C: Use the restore script (handles this automatically)**

```bash
./scripts/restore-database.sh /tmp/backup.dump
```

### Issue: "Database does not exist" error

```bash
# Recreate database
docker exec -it dendreo-postgres createdb -U postgres dendreo_progression

# Then retry restore
```

### Issue: Permission errors during restore

```bash
# Grant all privileges to postgres user
docker exec -it dendreo-postgres psql -U postgres -d dendreo_progression -c \
  "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;"
```

### Issue: Different PostgreSQL versions

```bash
# Check PostgreSQL version on source
docker exec dendreo-postgres psql -U postgres -c "SELECT version();"

# If versions differ significantly, use plain SQL format instead:
# On source machine:
docker exec dendreo-postgres pg_dump -U postgres -d dendreo_progression \
  --format=plain \
  --file=/tmp/dendreo_backup.sql

# Then restore with:
docker exec -it dendreo-postgres psql -U postgres -d dendreo_progression \
  -f /tmp/dendreo_backup.sql
```

### Issue: Connection refused to database

```bash
# Ensure PostgreSQL container is running
docker ps | grep postgres

# Check PostgreSQL logs
docker logs dendreo-postgres

# Restart if needed
docker restart dendreo-postgres
sleep 5  # Wait for PostgreSQL to start
```

### Issue: Backup file not found

```bash
# List files in container
docker exec dendreo-postgres ls -la /tmp/

# Verify backup file on host
ls -lh /tmp/dendreo_backup*.dump

# Re-copy if needed
docker cp /tmp/dendreo_backup_*.dump dendreo-postgres:/tmp/dendreo_backup.dump
```

---

## Data Validation Checklist

After migration, verify:

- [ ] All tables exist: `participants`, `courses`, `modules`, `participant_courses`, etc.
- [ ] Row counts match between source and target
- [ ] Last sync timestamp is preserved
- [ ] Dashboard statistics load correctly
- [ ] Participant list loads with correct data
- [ ] Course details show correct progression
- [ ] Inactive management page shows correct data
- [ ] No error messages in application logs

---

## Rollback Plan

If migration fails, you can:

1. **Keep source database running** - Don't shut down source machine until migration is verified
2. **Create fresh database** on target and re-sync from API (uses quota)
3. **Retry migration** with a new backup

---

## Automated Migration Script

For convenience, here's an automated script:

**On source machine** (`backup-database.sh`):

```bash
#!/bin/bash
set -e

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/dendreo_backup_${TIMESTAMP}.dump"

echo "Creating backup directory..."
mkdir -p "${BACKUP_DIR}"

echo "Creating database backup..."
docker exec dendreo-postgres pg_dump -U postgres -d dendreo_progression \
  --format=custom \
  --file=/tmp/dendreo_backup.dump

echo "Copying backup from container..."
docker cp dendreo-postgres:/tmp/dendreo_backup.dump "${BACKUP_FILE}"

echo "Cleaning up container..."
docker exec dendreo-postgres rm /tmp/dendreo_backup.dump

echo "Backup created: ${BACKUP_FILE}"
ls -lh "${BACKUP_FILE}"
```

**On target machine** (`restore-database.sh`):

```bash
#!/bin/bash
set -e

BACKUP_FILE="${1}"

if [ -z "${BACKUP_FILE}" ]; then
  echo "Usage: ./restore-database.sh /path/to/backup.dump"
  exit 1
fi

if [ ! -f "${BACKUP_FILE}" ]; then
  echo "Backup file not found: ${BACKUP_FILE}"
  exit 1
fi

echo "Stopping sync container..."
docker stop dendreo-sync || true

echo "Copying backup to container..."
docker cp "${BACKUP_FILE}" dendreo-postgres:/tmp/dendreo_backup.dump

echo "Dropping and recreating database..."
docker exec dendreo-postgres psql -U postgres -c "DROP DATABASE IF EXISTS dendreo_progression;"
docker exec dendreo-postgres psql -U postgres -c "CREATE DATABASE dendreo_progression;"

echo "Restoring database..."
docker exec dendreo-postgres pg_restore \
  -U postgres \
  -d dendreo_progression \
  --clean \
  --if-exists \
  --no-owner \
  --no-privileges \
  /tmp/dendreo_backup.dump

echo "Cleaning up..."
docker exec dendreo-postgres rm /tmp/dendreo_backup.dump

echo "Verifying restoration..."
docker exec dendreo-postgres psql -U postgres -d dendreo_progression -c "\dt"

echo "Database restored successfully!"
echo "You can now start the sync container: docker start dendreo-sync"
```

Make scripts executable:

```bash
chmod +x backup-database.sh restore-database.sh
```

---

## Best Practices

1. **Test migration in staging first** - Never migrate directly to production without testing
2. **Create backups before migration** - Always have a rollback option
3. **Verify data integrity** - Check row counts and critical data
4. **Document credentials** - Keep database passwords consistent or documented
5. **Monitor after migration** - Watch logs for any issues
6. **Keep source running** - Don't decommission source until target is verified
7. **Schedule during low traffic** - Minimize user impact

---

## Quick Reference Commands

```bash
# Backup
docker exec dendreo-postgres pg_dump -U postgres -d dendreo_progression --format=custom > backup.dump

# Restore
docker exec -i dendreo-postgres pg_restore -U postgres -d dendreo_progression --clean < backup.dump

# Check size
docker exec dendreo-postgres psql -U postgres -c "SELECT pg_size_pretty(pg_database_size('dendreo_progression'));"

# Verify tables
docker exec dendreo-postgres psql -U postgres -d dendreo_progression -c "\dt"

# Check row counts
docker exec dendreo-postgres psql -U postgres -d dendreo_progression -c "SELECT relname, n_live_tup FROM pg_stat_user_tables;"
```

---

**Last Updated:** 2026-02-04
