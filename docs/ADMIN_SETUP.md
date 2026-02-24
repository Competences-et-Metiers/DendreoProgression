# Quick Setup: Admin Sync Management

## 5-Minute Setup Guide

### Step 1: Run Migration (30 seconds)

```bash
docker compose -f docker-compose.prod.yml exec backend \
  python3 scripts/migrate_add_admin_features.py
```

### Step 2: Restart Services (1 minute)

```bash
docker compose -f docker-compose.prod.yml restart backend sync
```

### Step 3: Access Dashboard (1 minute)

1. Log in to your application
2. Navigate to `/admin/sync` or click **Admin: Sync** in the sidebar
3. Start monitoring and controlling syncs!

---

## That's it! 🎉

You now have:
- ✅ Role-based admin access
- ✅ API usage monitoring (last/today/week/month)
- ✅ Manual sync controls (dry-run, force, specific ADF)
- ✅ Cron schedule toggle (enable/disable scheduled syncs)
- ✅ Cooldown configuration (prevent rapid syncs)
- ✅ Sync history tracking

---

## Quick Reference

### Check Who's Admin

```bash
docker compose -f docker-compose.prod.yml exec postgres \
  psql -U postgres -d dendreo_prod_db -c \
  "SELECT username, role FROM users;"
```

### Make Another User Admin

```bash
docker compose -f docker-compose.prod.yml exec postgres \
  psql -U postgres -d dendreo_prod_db -c \
  "UPDATE users SET role='admin' WHERE username='their_username';"

# They must log out and log back in to get new JWT
```

### Emergency: Disable All Scheduled Syncs

```bash
# Via dashboard: Uncheck "Enable Scheduled Cron Syncs"
# Or via environment variable:
echo "DISABLE_CRON_SCHEDULE=true" >> .env.prod
docker compose -f docker-compose.prod.yml restart sync
```

### View Sync Logs

```bash
# Backend logs
docker compose -f docker-compose.prod.yml logs -f backend

# Sync container logs
docker compose -f docker-compose.prod.yml logs -f sync

# Cron logs
docker compose -f docker-compose.prod.yml exec sync cat /app/logs/cron.log
```

---

## Full Documentation

See [ADMIN_SYNC_MANAGEMENT.md](features/ADMIN_SYNC_MANAGEMENT.md) for complete guide.
