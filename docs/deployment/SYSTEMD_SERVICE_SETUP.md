# Dendreo Systemd Service Setup

This document describes how to set up and manage the Dendreo Progression application as a systemd service on your Debian server.

## Overview

The Dendreo service system consists of:
- **`dendreo.service`** - The systemd service unit file
- **`dendreo-service-manager.sh`** - Service management script
- **`deploy.sh`** - Main deployment script (with production mode support)
- **`setup-dendreo-service.sh`** - Installation and configuration script

## Quick Setup

### 1. Install the Service

```bash
# Run the setup script as root
sudo ./setup-dendreo-service.sh install
```

This will:
- ✅ Check prerequisites (Docker, Docker Compose)
- ✅ Make scripts executable
- ✅ Install the systemd service
- ✅ Enable auto-start on boot
- ✅ Perform installation tests

### 2. Start the Service

```bash
# Start the service
sudo systemctl start dendreo

# Check status
sudo systemctl status dendreo

# Follow logs
sudo journalctl -u dendreo -f
```

## Service Management Commands

### Systemctl Commands (Recommended)

```bash
# Service lifecycle
sudo systemctl start dendreo      # Start the service
sudo systemctl stop dendreo       # Stop the service
sudo systemctl restart dendreo    # Restart the service
sudo systemctl reload dendreo     # Reload the service

# Service status
sudo systemctl status dendreo     # Check service status
sudo systemctl is-active dendreo  # Check if running
sudo systemctl is-enabled dendreo # Check if enabled

# Boot management
sudo systemctl enable dendreo     # Enable auto-start on boot
sudo systemctl disable dendreo    # Disable auto-start on boot
```

### Manual Service Management

```bash
# Direct service manager commands
sudo ./dendreo-service-manager.sh start    # Start manually
sudo ./dendreo-service-manager.sh stop     # Stop manually
sudo ./dendreo-service-manager.sh restart  # Restart manually
sudo ./dendreo-service-manager.sh status   # Check status
sudo ./dendreo-service-manager.sh health   # Health check
sudo ./dendreo-service-manager.sh logs     # Show logs
```

## Logging and Monitoring

### View Logs

```bash
# System logs (recommended)
sudo journalctl -u dendreo -f          # Follow service logs
sudo journalctl -u dendreo --since "1 hour ago"  # Recent logs
sudo journalctl -u dendreo --no-pager  # All logs without pager

# Service log file
sudo tail -f /var/log/dendreo-service.log

# Container logs
sudo ./dendreo-service-manager.sh logs
sudo ./dendreo-service-manager.sh logs nginx follow
```

### Health Monitoring

```bash
# Check service health
sudo ./dendreo-service-manager.sh health

# Check individual container status
sudo docker compose -f docker-compose.prod.yml ps

# Check resource usage
sudo docker stats
```

## Configuration Files

### Service Configuration
- **Service unit**: `/etc/systemd/system/dendreo.service`
- **Environment**: `.env.prod`
- **Docker Compose**: `docker-compose.prod.yml`

### Log Files
- **Service logs**: `/var/log/dendreo-service.log`
- **System logs**: `journalctl -u dendreo`
- **Container logs**: `docker compose logs`

## Service Features

### Auto-Recovery
- ✅ Automatic restart on failure
- ✅ Restart limit protection (3 attempts in 5 minutes)
- ✅ Health checks after startup
- ✅ Graceful shutdown handling

### Resource Management
- ✅ Proper timeouts (10min start, 2min stop)
- ✅ Resource limits (file descriptors, processes)
- ✅ Docker system cleanup on startup

### Logging
- ✅ Structured logging with timestamps
- ✅ Systemd journal integration
- ✅ Separate log files for debugging

## Troubleshooting

### Common Issues

#### Service Won't Start
```bash
# Check service status
sudo systemctl status dendreo

# Check logs
sudo journalctl -u dendreo --no-pager

# Check file permissions
ls -la dendreo-service-manager.sh
ls -la deploy.sh

# Manual test
sudo ./dendreo-service-manager.sh start
```

#### Service Fails to Stop
```bash
# Check what's running
sudo ./dendreo-service-manager.sh status

# Force stop containers
sudo docker compose -f docker-compose.prod.yml down

# Check for stuck processes
sudo ps aux | grep dendreo
```

#### Configuration Issues
```bash
# Check environment file
cat .env.prod

# Check Docker Compose syntax
sudo docker compose -f docker-compose.prod.yml config

# Test deployment script
sudo ./deploy.sh --prod status
```

### Log Analysis

```bash
# Service startup issues
sudo journalctl -u dendreo --since "10 minutes ago"

# Container issues
sudo docker compose -f docker-compose.prod.yml logs

# System resource issues
sudo dmesg | tail -20
sudo df -h
sudo free -h
```

## Advanced Configuration

### Custom Service Timeouts

Edit `/etc/systemd/system/dendreo.service`:

```ini
[Service]
TimeoutStartSec=600    # 10 minutes
TimeoutStopSec=120     # 2 minutes
TimeoutReloadSec=300   # 5 minutes
```

### Resource Limits

```ini
[Service]
LimitNOFILE=65536      # File descriptors
LimitNPROC=32768       # Processes
```

### Custom Environment Variables

Add to the service file:

```ini
[Service]
Environment=CUSTOM_VAR=value
Environment=ANOTHER_VAR=value
```

## Uninstallation

```bash
# Remove the service
sudo ./setup-dendreo-service.sh uninstall

# Optional: Clean up containers and volumes
sudo docker compose -f docker-compose.prod.yml down -v
sudo docker system prune -a
```

## Integration with Deploy Script

The service uses the main `deploy.sh` script in production mode:

```bash
# What the service runs internally:
./deploy.sh --prod start    # Start production environment
./deploy.sh --prod stop     # Stop production environment
./deploy.sh --prod status   # Check status
```

This ensures consistency between manual deployments and service management.

## Best Practices

1. **Always use systemctl commands** for production management
2. **Monitor logs regularly** with `journalctl -u dendreo -f`
3. **Test configuration changes** before applying to production
4. **Keep backups** of your `.env.prod` and service configuration
5. **Use health checks** to verify service status
6. **Set up monitoring** for production environments

## Support

For issues or questions:
1. Check the logs first: `sudo journalctl -u dendreo -f`
2. Test manual operation: `sudo ./dendreo-service-manager.sh status`
3. Verify configuration: `sudo ./deploy.sh --prod status`
4. Check Docker resources: `sudo docker system df`

The service is designed to be robust and self-healing, but manual intervention may be needed for configuration or resource issues. 