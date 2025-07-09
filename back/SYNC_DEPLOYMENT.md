# Dendreo Sync Deployment Guide

This guide covers the best practices for deploying the Dendreo sync process on your remote server.

## 📋 Overview

The sync process has been separated from the main API into standalone scripts for better security and reliability. You have two main options for scheduling the sync:

1. **Cron Jobs** (Traditional Unix scheduling)
2. **Systemd Timer** (Modern Linux service scheduling)

## 🚀 Quick Setup

### 1. Make Scripts Executable

```bash
chmod +x back/scripts/sync_dendreo.py
chmod +x back/scripts/setup_sync_cron.sh
chmod +x back/scripts/sync_health_check.py
```

### 2. Test the Sync Script

```bash
# Test with dry run (no database changes)
python3 back/scripts/sync_dendreo.py --dry-run

# Test actual sync
python3 back/scripts/sync_dendreo.py --force
```

### 3. Set Up Automated Scheduling

Choose one of the following methods:

## 🕐 Option 1: Cron Jobs (Recommended)

### Setup

```bash
# Run the setup script (creates wrapper script and shows instructions)
cd back/scripts
./setup_sync_cron.sh

# Follow the instructions to install the cron job
# Example: Run every 6 hours
echo "0 */6 * * * /home/cm/DendreoProgression/back/scripts/sync_wrapper.sh" | crontab -
```

### Verify Cron Job

```bash
# Check installed cron jobs
crontab -l

# Check cron service status
sudo systemctl status cron
```

## ⚙️ Option 2: Systemd Timer (Advanced)

### Setup

```bash
# Copy service files to systemd directory
sudo cp back/scripts/dendreo-sync.service /etc/systemd/system/
sudo cp back/scripts/dendreo-sync.timer /etc/systemd/system/

# Edit service file to match your paths
sudo nano /etc/systemd/system/dendreo-sync.service
# Update paths to match your installation

# Reload systemd and enable timer
sudo systemctl daemon-reload
sudo systemctl enable dendreo-sync.timer
sudo systemctl start dendreo-sync.timer
```

### Verify Systemd Timer

```bash
# Check timer status
sudo systemctl status dendreo-sync.timer

# List all timers
sudo systemctl list-timers

# View logs
sudo journalctl -u dendreo-sync.service -f
```

## 🔒 Security Configuration

### 1. API Key Protection

Add to your `.env.prod` file:

```bash
# Optional: Protect sync API endpoints
SYNC_API_KEY=your-super-secret-sync-key-here
```

### 2. Firewall Rules

If you want to keep the API endpoints accessible (not recommended for production):

```bash
# Allow access only from specific IP ranges
sudo ufw allow from 192.168.254.0/24 to any port 8000

# Or create a more restrictive rule
sudo ufw allow from 192.168.254.24 to any port 8000
```

### 3. Disable API Endpoints (Recommended)

Comment out or remove the sync endpoints from `back/app/api/routes/sync.py`:

```python
# @router.post("/sync-all")
# async def sync_all(...):
#     ...
```

## 📊 Monitoring and Health Checks

### 1. Manual Health Check

```bash
# Human-readable format
python3 back/scripts/sync_health_check.py

# JSON format
python3 back/scripts/sync_health_check.py --format json

# Nagios/monitoring format
python3 back/scripts/sync_health_check.py --nagios --exit-code
```

### 2. Automated Monitoring

Add to your monitoring system (e.g., Nagios, Zabbix):

```bash
# Check every 30 minutes
*/30 * * * * /usr/bin/python3 /home/cm/DendreoProgression/back/scripts/sync_health_check.py --nagios --exit-code
```

## 📝 Log Management

### Log Files Locations

```bash
# Sync logs (daily rotation)
back/logs/sync_YYYYMMDD.log

# Cron logs
back/logs/cron_sync.log

# Systemd logs
sudo journalctl -u dendreo-sync.service
```

### Log Rotation

Create `/etc/logrotate.d/dendreo-sync`:

```bash
/home/cm/DendreoProgression/back/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 cm cm
}
```

## 🛠️ Troubleshooting

### 1. Check Sync Status

```bash
# Check last sync status
python3 back/scripts/sync_health_check.py

# Check database directly
psql -h localhost -U your_user -d your_db -c "SELECT * FROM sync_metadata ORDER BY last_sync_at DESC LIMIT 1;"
```

### 2. Debug Mode

```bash
# Run sync with debug logging
python3 back/scripts/sync_dendreo.py --log-level DEBUG

# Force sync (ignore recent syncs)
python3 back/scripts/sync_dendreo.py --force
```

### 3. Common Issues

**Environment Variables Not Loaded**
```bash
# Check if environment file exists
ls -la /home/cm/DendreoProgression/.env.prod

# Test environment loading
cd /home/cm/DendreoProgression/back
python3 -c "from app.config.settings import settings; print(settings.database_url)"
```

**Permission Issues**
```bash
# Fix log directory permissions
sudo chown -R cm:cm /home/cm/DendreoProgression/back/logs
chmod 755 /home/cm/DendreoProgression/back/logs
```

**Database Connection Issues**
```bash
# Test database connectivity
python3 -c "from app.models.database import engine; from sqlalchemy import text; engine.connect().execute(text('SELECT 1'))"
```

## 🔄 Sync Schedule Recommendations

### Production Environment

- **Every 6 hours**: `0 */6 * * *` (00:00, 06:00, 12:00, 18:00)
- **Every 4 hours**: `0 */4 * * *` (00:00, 04:00, 08:00, 12:00, 16:00, 20:00)

### Development Environment

- **Every 2 hours**: `0 */2 * * *`
- **Every 30 minutes**: `*/30 * * * *`

## 📈 Performance Optimization

### 1. Database Optimization

```sql
-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_sync_metadata_type_date ON sync_metadata(sync_type, last_sync_at);
CREATE INDEX IF NOT EXISTS idx_participant_courses_participant ON participant_courses(participant_id);
CREATE INDEX IF NOT EXISTS idx_modules_participant_lam ON modules(participant_id, id_lam);
```

### 2. Environment Variables

Add to `.env.prod`:

```bash
# Limit number of ADFs processed (for testing)
DENDREO_ADF_LIMIT=50

# Redis configuration
REDIS_ENABLED=true
REDIS_URL=redis://localhost:6379/0
```

## 🚨 Emergency Procedures

### 1. Stop Sync Process

```bash
# If using cron
crontab -r  # Remove all cron jobs (or edit with crontab -e)

# If using systemd
sudo systemctl stop dendreo-sync.timer
sudo systemctl disable dendreo-sync.timer
```

### 2. Reset Stuck Sync

```bash
# Update database to clear stuck "in_progress" status
psql -h localhost -U your_user -d your_db -c "UPDATE sync_metadata SET status = 'error', error_message = 'Manually reset' WHERE status = 'in_progress';"
```

### 3. Manual Sync

```bash
# Force immediate sync
python3 back/scripts/sync_dendreo.py --force --log-level DEBUG
```

## 📋 Deployment Checklist

- [ ] Scripts are executable
- [ ] Environment variables configured
- [ ] Database connectivity tested
- [ ] Sync script tested with `--dry-run`
- [ ] Cron job or systemd timer configured
- [ ] Log rotation configured
- [ ] Monitoring/health checks set up
- [ ] API endpoints secured or disabled
- [ ] Firewall rules configured
- [ ] Documentation updated

## 🎯 Next Steps

1. **Test the setup** with a dry run
2. **Monitor the first few sync cycles** to ensure everything works
3. **Set up alerting** for failed syncs
4. **Document your specific configuration** for your team

For questions or issues, check the logs first, then refer to the troubleshooting section above. 