# Dendreo Systemd Service Setup

This document explains how to set up the Dendreo application as a systemd service on your Debian server, enabling automatic startup and easy management with `systemctl` commands.

## Files Created

1. **`dendreo-service-manager.sh`** - Main service management script
2. **`dendreo.service`** - Systemd service unit file
3. **`setup-dendreo-service.sh`** - Installation and setup script
4. **`SYSTEMD_SERVICE_SETUP.md`** - This documentation file

## Installation Instructions

### Step 1: Copy Files to Your Server

Copy all the new files to your Debian server in the `/home/cm/DendreoProgression` directory:

```bash
# On your Debian server
cd /home/cm/DendreoProgression

# Copy the files from your local machine (use scp, rsync, or any method you prefer)
# Make sure you have these files:
# - dendreo-service-manager.sh
# - dendreo.service
# - setup-dendreo-service.sh
# - SYSTEMD_SERVICE_SETUP.md
```

### Step 2: Run the Setup Script

Execute the setup script to install and configure the service:

```bash
# Make the setup script executable
chmod +x setup-dendreo-service.sh

# Install the service
sudo ./setup-dendreo-service.sh install
```

This will:
- Install the systemd service file
- Make scripts executable
- Enable the service for automatic startup
- Start the service
- Show service status

### Step 3: Verify Installation

Check if the service is running:

```bash
sudo systemctl status dendreo
```

## Usage

### Basic systemctl Commands

```bash
# Start the service
sudo systemctl start dendreo

# Stop the service
sudo systemctl stop dendreo

# Restart the service
sudo systemctl restart dendreo

# Check service status
sudo systemctl status dendreo

# Enable auto-start on boot
sudo systemctl enable dendreo

# Disable auto-start on boot
sudo systemctl disable dendreo
```

### Advanced Management

```bash
# View service logs
sudo journalctl -u dendreo

# Follow service logs in real-time
sudo journalctl -u dendreo -f

# View recent logs
sudo journalctl -u dendreo --since "1 hour ago"

# View service log file
sudo tail -f /var/log/dendreo-service.log
```

### Container Management

The service manager script provides additional commands:

```bash
# Check container status
sudo /home/cm/DendreoProgression/dendreo-service-manager.sh status

# View all container logs
sudo /home/cm/DendreoProgression/dendreo-service-manager.sh logs

# View specific service logs
sudo /home/cm/DendreoProgression/dendreo-service-manager.sh logs nginx
sudo /home/cm/DendreoProgression/dendreo-service-manager.sh logs backend
sudo /home/cm/DendreoProgression/dendreo-service-manager.sh logs frontend

# Follow logs in real-time
sudo /home/cm/DendreoProgression/dendreo-service-manager.sh logs nginx follow
```

## Service Behavior

- **Automatic Startup**: The service is configured to start automatically on boot
- **Dependency Management**: Waits for Docker service and network to be ready
- **Health Monitoring**: Integrates with Docker Compose health checks
- **Logging**: All operations are logged to `/var/log/dendreo-service.log`
- **Lock File**: Prevents multiple instances from running simultaneously

## Troubleshooting

### Service Won't Start

1. Check service logs:
   ```bash
   sudo journalctl -u dendreo -n 50
   ```

2. Check the service manager log:
   ```bash
   sudo tail -f /var/log/dendreo-service.log
   ```

3. Verify environment file exists:
   ```bash
   ls -la /home/cm/DendreoProgression/.env.prod
   ```

4. Check Docker service:
   ```bash
   sudo systemctl status docker
   ```

### Service Fails to Stop

1. Check if containers are running:
   ```bash
   cd /home/cm/DendreoProgression
   sudo docker compose -f docker-compose.prod.yml ps
   ```

2. Manually stop containers:
   ```bash
   cd /home/cm/DendreoProgression
   sudo docker compose -f docker-compose.prod.yml down
   ```

### Permission Issues

1. Ensure scripts are executable:
   ```bash
   chmod +x /home/cm/DendreoProgression/dendreo-service-manager.sh
   chmod +x /home/cm/DendreoProgression/deploy-prod.sh
   ```

2. Check file ownership:
   ```bash
   sudo chown -R cm:cm /home/cm/DendreoProgression
   ```

### Reset Service

If you need to completely reset the service:

```bash
# Stop and disable the service
sudo systemctl stop dendreo
sudo systemctl disable dendreo

# Remove service file
sudo rm /etc/systemd/system/dendreo.service

# Reload systemd
sudo systemctl daemon-reload

# Reinstall
sudo ./setup-dendreo-service.sh install
```

## Uninstallation

To remove the service:

```bash
sudo ./setup-dendreo-service.sh uninstall
```

This will:
- Stop the service
- Disable auto-start
- Remove the service file
- Reload systemd

## Log Files

- **Service logs**: `/var/log/dendreo-service.log`
- **Systemd logs**: `journalctl -u dendreo`
- **Container logs**: `docker compose logs` (in project directory)

## Configuration

The service uses these configuration files:
- **Environment**: `.env.prod`
- **Docker Compose**: `docker-compose.prod.yml`
- **Deployment**: `deploy-prod.sh`

## Security Considerations

- Service runs as root (required for Docker operations)
- Log files are created with appropriate permissions
- Service includes basic security settings in systemd unit file

## Support

For issues or questions:
1. Check the logs first
2. Verify all required files exist
3. Ensure Docker service is running
4. Check environment configuration

The service manager script provides detailed error messages and logging to help diagnose issues. 