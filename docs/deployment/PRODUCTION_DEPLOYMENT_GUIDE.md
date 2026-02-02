# Production Deployment Guide for Dendreo Progression

This guide covers the complete production deployment of the Dendreo Progression application, including the automated sync functionality.

## 🎯 Overview

The production deployment includes:
- **Frontend**: React application served via Nginx
- **Backend**: FastAPI server with REST API
- **Database**: PostgreSQL with all required tables
- **Sync Service**: Automated data synchronization from Dendreo API
- **Redis**: Caching layer for improved performance
- **Nginx**: Reverse proxy and load balancer

## 📋 Prerequisites

### System Requirements
- Docker 20.10+ and Docker Compose 2.0+
- At least 4GB RAM and 10GB disk space
- Linux/Unix environment (Ubuntu 20.04+ recommended)

### API Credentials
- **Dendreo API Key**: Valid API key for Dendreo platform
- **HubSpot API Key**: Valid HubSpot private app token (optional)
- **Database Credentials**: Secure PostgreSQL credentials

## 🚀 Quick Start

### 1. Clone and Setup
```bash
git clone <your-repository>
cd DendreoProgression
```

### 2. Configure Environment
```bash
# Copy the example environment file
cp env.prod.example .env.prod

# Edit with your production values
nano .env.prod
```

### 3. Deploy
```bash
# Make the deployment script executable
chmod +x deploy-prod.sh

# Run the deployment
./deploy-prod.sh
```

## ⚙️ Environment Configuration

### Required Variables
```env
# Database Configuration
POSTGRES_DB=dendreo_prod_db
POSTGRES_USER=dendreo_user
POSTGRES_PASSWORD=your_secure_production_password_here
DATABASE_URL=postgresql://dendreo_user:your_secure_production_password_here@postgres:5432/dendreo_prod_db

# API Configuration
DENDREO_API_KEY=your_actual_dendreo_api_key
DENDREO_BASE_URL=https://pro.dendreo.com/competences_et_metiers/api

# Sync Configuration
SYNC_SCHEDULE=0 8 * * *       # Daily at 8AM
SYNC_LOG_LEVEL=INFO           # Logging level
DENDREO_ADF_LIMIT=            # Leave empty for production (no limit)
```

### Optional Variables
```env
# HubSpot Integration
HUBSPOT_API_KEY=your_hubspot_api_key

# Security
SECRET_KEY=your_very_long_secret_key_for_production
JWT_SECRET=your_jwt_secret_for_production

# Performance
REDIS_ENABLED=true
```

## 🔄 Sync Service Features

### Automatic Synchronization
- **Schedule**: Runs daily at 8 AM (configurable)
- **Data Sources**: Dendreo API (ADF, LAP, LMP data)
- **Destinations**: PostgreSQL database + HubSpot updates
- **Monitoring**: Comprehensive logging and status tracking

### Sync Components
1. **Cron Service**: Manages scheduled execution
2. **Sync Scripts**: Handle data processing and API calls
3. **Database Tables**: Store sync metadata and status
4. **Health Checks**: Monitor sync service availability
5. **Diagnostic Tools**: Debug sync issues

### Sync Tables Created
- `sync_metadata`: Tracks sync executions and status
- `participants`: User data from Dendreo
- `courses`: Course information and modules
- `modules`: Individual learning modules
- `participant_courses`: Progress tracking
- `participant_hubspot_data`: HubSpot integration data

## 📊 Monitoring and Management

### Service Status
```bash
# Check all services
docker compose -f docker-compose.prod.yml ps

# View service logs
docker compose -f docker-compose.prod.yml logs -f sync
```

### Sync Management
```bash
# Check sync status
docker compose -f docker-compose.prod.yml exec sync python3 scripts/check_sync_status.py

# Run manual sync
docker compose -f docker-compose.prod.yml exec sync python3 scripts/sync_dendreo.py

# View sync logs
docker compose -f docker-compose.prod.yml exec sync cat /app/logs/cron.log

# Diagnose sync issues
docker compose -f docker-compose.prod.yml exec sync python3 scripts/diagnose_cron.py
```

### Database Monitoring
```bash
# Check sync metadata
docker compose -f docker-compose.prod.yml exec postgres psql -U postgres -d dendreo_prod_db -c "
SELECT sync_type, last_sync_at, status, error_message 
FROM sync_metadata 
ORDER BY last_sync_at DESC 
LIMIT 5;
"

# Check data counts
docker compose -f docker-compose.prod.yml exec postgres psql -U postgres -d dendreo_prod_db -c "
SELECT 
    'participants' as table_name, COUNT(*) as count FROM participants
UNION SELECT 
    'courses', COUNT(*) FROM courses
UNION SELECT 
    'modules', COUNT(*) FROM modules;
"
```

## 🛠️ Deployment Process

The `deploy-prod.sh` script performs these steps:

1. **Prerequisites Check**: Verifies Docker and dependencies
2. **Environment Setup**: Validates configuration and API keys
3. **Script Preparation**: Makes sync scripts executable
4. **Backup Creation**: Backs up existing data and configuration
5. **Service Deployment**: Builds and starts all containers
6. **Database Initialization**: Creates tables and sync metadata
7. **Sync Testing**: Validates sync functionality
8. **Status Display**: Shows deployment summary and commands

## 🔧 Customization

### Sync Schedule
Modify the `SYNC_SCHEDULE` variable using cron format:
```env
SYNC_SCHEDULE=0 8 * * *     # Daily at 8 AM
SYNC_SCHEDULE=0 */6 * * *   # Every 6 hours
SYNC_SCHEDULE=0 8 * * 1     # Weekly on Monday at 8 AM
```

### API Limits
For testing or quota management:
```env
DENDREO_ADF_LIMIT=10        # Limit to 10 ADFs per sync
DENDREO_ADF_LIMIT=          # No limit (production)
```

### Logging Levels
```env
SYNC_LOG_LEVEL=DEBUG        # Detailed logging
SYNC_LOG_LEVEL=INFO         # Standard logging
SYNC_LOG_LEVEL=WARNING      # Errors and warnings only
```

## 🚨 Troubleshooting

### Common Issues

1. **Sync Service Not Starting**
   ```bash
   # Check sync logs
   docker compose -f docker-compose.prod.yml logs sync
   
   # Verify environment variables
   docker compose -f docker-compose.prod.yml exec sync env | grep DENDREO
   ```

2. **Database Connection Issues**
   ```bash
   # Test database connection
   docker compose -f docker-compose.prod.yml exec postgres pg_isready -U postgres
   ```

3. **API Authentication Errors**
   ```bash
   # Verify API key format and validity
   docker compose -f docker-compose.prod.yml exec sync python3 -c "
   import os
   print('DENDREO_API_KEY length:', len(os.getenv('DENDREO_API_KEY', '')))
   "
   ```

4. **Cron Not Running**
   ```bash
   # Check cron service
   docker compose -f docker-compose.prod.yml exec sync pgrep -f cron
   
   # View cron jobs
   docker compose -f docker-compose.prod.yml exec sync crontab -l
   ```

### Debug Mode
Run deployment with debug information:
```bash
DEBUG=true ./deploy-prod.sh
```

## 🔐 Security Considerations

### Production Checklist
- [ ] Change all default passwords
- [ ] Use strong, unique API keys
- [ ] Enable SSL/HTTPS for public deployment
- [ ] Restrict database access to application only
- [ ] Regular backup strategy in place
- [ ] Monitor logs for security issues

### SSL Setup
1. Place SSL certificates in `./ssl/` directory
2. Update `nginx/prod.conf` to enable HTTPS
3. Restart nginx: `docker compose -f docker-compose.prod.yml restart nginx`

## 📈 Performance Optimization

### Resource Allocation
Adjust Docker resource limits in docker-compose.prod.yml:
```yaml
services:
  postgres:
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
```

### Caching
Enable Redis caching for improved performance:
```env
REDIS_ENABLED=true
REDIS_URL=redis://redis:6379/0
```

## 🔄 Updates and Maintenance

### Update Application
```bash
# Pull latest changes
git pull

# Redeploy with updates
./deploy-prod.sh
```

### Backup Strategy
```bash
# Manual backup
docker compose -f docker-compose.prod.yml exec postgres pg_dump -U postgres dendreo_prod_db > backup_$(date +%Y%m%d).sql

# Automated backups (add to crontab)
0 2 * * * cd /path/to/project && docker compose -f docker-compose.prod.yml exec -T postgres pg_dump -U postgres dendreo_prod_db > backups/backup_$(date +\%Y\%m\%d).sql
```

## 📞 Support

### Log Locations
- Application logs: `./logs/`
- Sync logs: Container `/app/logs/`
- Nginx logs: `./logs/nginx/`

### Key Commands Reference
```bash
# Service management
docker compose -f docker-compose.prod.yml up -d    # Start
docker compose -f docker-compose.prod.yml down     # Stop
docker compose -f docker-compose.prod.yml restart  # Restart

# Monitoring
docker compose -f docker-compose.prod.yml ps       # Service status
docker compose -f docker-compose.prod.yml logs -f  # Follow logs

# Sync management
docker compose -f docker-compose.prod.yml exec sync python3 scripts/check_sync_status.py
docker compose -f docker-compose.prod.yml exec sync python3 scripts/sync_dendreo.py
```

---

🎉 **Congratulations!** Your Dendreo Progression application with automated sync functionality is now running in production. 