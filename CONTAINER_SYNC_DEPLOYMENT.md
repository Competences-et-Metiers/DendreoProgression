# Container-Based Sync Deployment Guide

This guide covers deploying the Dendreo sync process using Docker containers - the **recommended approach** for production deployments.

## 🏗️ Architecture Overview

The containerized sync setup includes:

1. **Backend Container** - FastAPI application (no sync process)
2. **Sync Container** - Dedicated container running periodic sync jobs
3. **Database Container** - PostgreSQL
4. **Redis Container** - For caching
5. **Frontend Container** - React application
6. **Nginx Container** - Reverse proxy

## 🚀 Quick Deploy

### 1. Update Environment Configuration

Add sync-specific variables to your `.env.prod`:

```bash
# Sync Configuration
SYNC_SCHEDULE=0 */6 * * *     # Every 6 hours
SYNC_LOG_LEVEL=INFO           # Sync logging level
DENDREO_ADF_LIMIT=            # Optional: limit ADFs for testing

# Redis Configuration (for caching)
REDIS_ENABLED=true
REDIS_URL=redis://redis:6379/0
```

### 2. Build and Deploy

```bash
# Build all containers
docker-compose -f docker-compose.prod.yml build

# Start all services
docker-compose -f docker-compose.prod.yml up -d

# Check sync container status
docker-compose -f docker-compose.prod.yml logs -f sync
```

## 📋 Available Sync Schedules

Set the `SYNC_SCHEDULE` environment variable in `.env.prod`:

```bash
# Every 6 hours (recommended)
SYNC_SCHEDULE=0 */6 * * *

# Every 4 hours
SYNC_SCHEDULE=0 */4 * * *

# Every 2 hours
SYNC_SCHEDULE=0 */2 * * *

# Daily at 2 AM
SYNC_SCHEDULE=0 2 * * *

# Every 30 minutes (development)
SYNC_SCHEDULE=*/30 * * * *
```

## 🔧 Management Commands

### View Sync Logs

```bash
# Follow sync container logs
docker-compose -f docker-compose.prod.yml logs -f sync

# View recent sync logs
docker-compose -f docker-compose.prod.yml logs --tail=100 sync

# Access log files directly
docker exec -it dendreo-sync-1 tail -f /app/logs/sync.log
```

### Manual Sync Execution

```bash
# Run immediate sync
docker exec dendreo-sync-1 python3 scripts/sync_dendreo.py --force

# Dry run (no database changes)
docker exec dendreo-sync-1 python3 scripts/sync_dendreo.py --dry-run

# Debug mode
docker exec dendreo-sync-1 python3 scripts/sync_dendreo.py --force --log-level DEBUG
```

### Health Checks

```bash
# Check sync health
docker exec dendreo-sync-1 python3 scripts/sync_health_check.py

# JSON format
docker exec dendreo-sync-1 python3 scripts/sync_health_check.py --format json

# Check container health
docker-compose -f docker-compose.prod.yml ps
```

### Cron Job Management

```bash
# View current cron jobs
docker exec dendreo-sync-1 crontab -l

# Check cron daemon status
docker exec dendreo-sync-1 pgrep cron

# View cron logs
docker exec dendreo-sync-1 grep CRON /var/log/syslog
```

## 🔄 Updating Sync Schedule

### Method 1: Environment Variable (Recommended)

1. Update `SYNC_SCHEDULE` in `.env.prod`
2. Restart sync container:

```bash
docker-compose -f docker-compose.prod.yml restart sync
```

### Method 2: Runtime Update

```bash
# Update cron job directly
docker exec dendreo-sync-1 bash -c 'echo "0 */4 * * * /app/sync_wrapper.sh" | crontab -'

# Verify update
docker exec dendreo-sync-1 crontab -l
```

## 📊 Monitoring

### Container Health

```bash
# Check all container status
docker-compose -f docker-compose.prod.yml ps

# View container resource usage
docker stats

# Check sync container health
docker inspect dendreo-sync-1 --format='{{.State.Health.Status}}'
```

### Sync Status Monitoring

```bash
# Create monitoring script
cat > monitor_sync.sh << 'EOF'
#!/bin/bash
echo "=== Sync Container Health Check ==="
echo "Container Status: $(docker inspect dendreo-sync-1 --format='{{.State.Status}}')"
echo "Health Status: $(docker inspect dendreo-sync-1 --format='{{.State.Health.Status}}')"
echo ""
echo "=== Last Sync Status ==="
docker exec dendreo-sync-1 python3 scripts/sync_health_check.py
echo ""
echo "=== Recent Logs ==="
docker-compose -f docker-compose.prod.yml logs --tail=10 sync
EOF

chmod +x monitor_sync.sh
```

### Alerting Setup

Add to your monitoring system (e.g., Nagios, Zabbix):

```bash
# Check script for monitoring systems
cat > check_dendreo_sync.sh << 'EOF'
#!/bin/bash
# Exit codes: 0=OK, 1=WARNING, 2=CRITICAL

# Check if container is running
if ! docker inspect dendreo-sync-1 >/dev/null 2>&1; then
    echo "CRITICAL: Sync container not found"
    exit 2
fi

# Check container health
HEALTH=$(docker inspect dendreo-sync-1 --format='{{.State.Health.Status}}')
if [ "$HEALTH" != "healthy" ]; then
    echo "CRITICAL: Sync container unhealthy ($HEALTH)"
    exit 2
fi

# Check sync status
if docker exec dendreo-sync-1 python3 scripts/sync_health_check.py --nagios --exit-code; then
    echo "OK: Sync process healthy"
    exit 0
else
    echo "WARNING: Sync process issues detected"
    exit 1
fi
EOF

chmod +x check_dendreo_sync.sh
```

## 🛠️ Troubleshooting

### Common Issues

**Sync Container Won't Start**
```bash
# Check logs for errors
docker-compose -f docker-compose.prod.yml logs sync

# Check environment variables
docker exec dendreo-sync-1 env | grep -E "(DATABASE_URL|DENDREO_|SYNC_)"

# Verify database connectivity
docker exec dendreo-sync-1 python3 -c "from app.models.database import engine; from sqlalchemy import text; engine.connect().execute(text('SELECT 1'))"
```

**Cron Jobs Not Running**
```bash
# Check if cron daemon is running
docker exec dendreo-sync-1 pgrep cron

# Restart cron daemon
docker exec dendreo-sync-1 service cron restart

# Check cron configuration
docker exec dendreo-sync-1 crontab -l
```

**Sync Process Failing**
```bash
# Run sync manually with debug logging
docker exec dendreo-sync-1 python3 scripts/sync_dendreo.py --force --log-level DEBUG

# Check database sync metadata
docker exec dendreo-postgres-prod-1 psql -U dendreo_user -d dendreo_prod_db -c "SELECT * FROM sync_metadata ORDER BY last_sync_at DESC LIMIT 5;"
```

**Permission Issues**
```bash
# Check log directory permissions
docker exec dendreo-sync-1 ls -la /app/logs/

# Fix permissions if needed
docker exec dendreo-sync-1 chmod 755 /app/logs/
```

### Reset Sync State

```bash
# Clear stuck "in_progress" status
docker exec dendreo-postgres-prod-1 psql -U dendreo_user -d dendreo_prod_db -c "UPDATE sync_metadata SET status = 'error', error_message = 'Manually reset' WHERE status = 'in_progress';"

# Force immediate sync
docker exec dendreo-sync-1 python3 scripts/sync_dendreo.py --force
```

## 🔒 Security Considerations

### API Endpoint Security

The sync process runs independently, so you can:

1. **Remove sync API endpoints** (recommended):
   ```bash
   # Comment out sync routes in back/app/main.py
   # app.include_router(sync.router, prefix="/api/sync", tags=["sync"])
   ```

2. **Or secure them** with API key:
   ```bash
   # Add to .env.prod
   SYNC_API_KEY=your-super-secret-key-here
   ```

### Container Security

```bash
# Run security scan
docker scan dendreo-sync-1

# Check for vulnerabilities
docker exec dendreo-sync-1 apt list --upgradable
```

## 🚀 Production Optimizations

### Resource Limits

Add to docker-compose.prod.yml:

```yaml
sync:
  # ... existing configuration ...
  deploy:
    resources:
      limits:
        cpus: '0.5'
        memory: 512M
      reservations:
        cpus: '0.25'
        memory: 256M
```

### Log Rotation

```bash
# Configure Docker log rotation
cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

sudo systemctl restart docker
```

### Backup Sync Logs

```bash
# Create backup script
cat > backup_sync_logs.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d)
docker run --rm -v dendreo_sync_logs:/data -v $(pwd):/backup alpine tar czf /backup/sync_logs_$DATE.tar.gz -C /data .
EOF

# Add to crontab
echo "0 2 * * 0 /path/to/backup_sync_logs.sh" | crontab -
```

## 📈 Performance Monitoring

### Resource Usage

```bash
# Monitor sync container resources
docker stats dendreo-sync-1

# Check memory usage
docker exec dendreo-sync-1 free -h

# Check disk usage
docker exec dendreo-sync-1 df -h
```

### Sync Performance

```bash
# Analyze sync times
docker exec dendreo-sync-1 grep "Sync completed" /app/logs/sync.log | tail -10

# Check database performance
docker exec dendreo-postgres-prod-1 psql -U dendreo_user -d dendreo_prod_db -c "SELECT * FROM pg_stat_activity WHERE state = 'active';"
```

## 🔄 Updating the Sync Container

```bash
# Pull latest changes
git pull origin main

# Rebuild sync container
docker-compose -f docker-compose.prod.yml build sync

# Update with zero downtime
docker-compose -f docker-compose.prod.yml up -d sync

# Verify update
docker-compose -f docker-compose.prod.yml logs -f sync
```

## 📋 Deployment Checklist

- [ ] `.env.prod` configured with sync variables
- [ ] Docker Compose file updated
- [ ] Sync container builds successfully
- [ ] Database connectivity tested
- [ ] Cron schedule configured correctly
- [ ] Health checks passing
- [ ] Logs are being generated
- [ ] Monitoring/alerting configured
- [ ] Backup strategy implemented
- [ ] Security measures in place

## 🎯 Next Steps

1. **Deploy and test** the containerized setup
2. **Monitor the first few sync cycles** 
3. **Set up alerting** for failed syncs
4. **Optimize resource allocation** based on usage
5. **Document your specific configuration**

This containerized approach provides better isolation, easier scaling, and follows Docker best practices for production deployments. 