# Dendreo Progression Docker Deployment Guide

This guide covers deploying the Dendreo Progression application using Docker with PostgreSQL database, FastAPI backend, and React frontend.

## 🏗️ Architecture Overview

The deployment consists of 3 Docker containers:
- **PostgreSQL Database** (port 5432) - Data persistence
- **FastAPI Backend** (port 8000) - API and business logic
- **React Frontend** (port 3000) - User interface

All containers communicate through a dedicated Docker network for security and isolation.

## 📋 Prerequisites

### System Requirements
- Docker Engine 20.10+ 
- Docker Compose 2.0+ (or docker-compose 1.29+)
- 4GB+ RAM recommended
- 10GB+ disk space

### Network Requirements
- Ports 3000, 8000, 5432 available on the host
- Internet access for building containers

## 🚀 Quick Start

### 1. Clone and Setup
```bash
# Navigate to project root
cd /path/to/DendreoProgression

# Copy environment template
cp docker.env.example .env

# Edit .env with your API keys
nano .env  # or your preferred editor
```

### 2. Configure Environment
Edit `.env` file with your actual values:
```bash
DENDREO_API_KEY=your_actual_api_key_here
DENDREO_BASE_URL=https://pro.dendreo.com/competences_et_metiers/api
HUBSPOT_API_KEY=your_hubspot_key_here  # Optional
```

### 3. Deploy
```bash
# Make deploy script executable
chmod +x deploy.sh

# Start deployment
./deploy.sh start
```

### 4. Verify Deployment
After deployment completes, verify services:
- Frontend: http://localhost:3000
- Backend: http://localhost:8000
- API Docs: http://localhost:8000/docs
- Health Check: http://localhost:8000/health

## 🗄️ Database Schema Consistency

### Automatic Schema Creation
The deployment ensures schema consistency through multiple layers:

1. **PostgreSQL Initialization**: Basic database setup via `database/init/01-init.sql`
2. **SQLAlchemy Models**: Automatic table creation from Python models
3. **Health Checks**: Verify database connectivity before app startup

### Schema Management Strategy

#### Initial Setup
- Database container runs initialization scripts on first startup
- Backend waits for database to be ready before starting
- SQLAlchemy `create_tables()` creates all tables from models
- Foreign key constraints and indexes are automatically applied

#### Schema Updates
For production deployments, consider using Alembic migrations:
```bash
# Inside backend container
docker-compose exec backend bash
pip install alembic
alembic init alembic
alembic revision --autogenerate -m "Initial migration"
alembic upgrade head
```

#### Schema Validation
```bash
# Check current schema
docker-compose exec postgres psql -U postgres -d dendreo_db -c "\dt"

# Compare with models
docker-compose exec backend python -c "
from app.models.database import engine
from sqlalchemy import inspect
inspector = inspect(engine)
print('Tables:', inspector.get_table_names())
"
```

### Data Persistence
- Database data persists in Docker volume `postgres_data`
- Survives container restarts and updates
- Backed up using built-in tools

## 🔧 Configuration Management

### Environment Variables
| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://postgres:admin@postgres:5432/dendreo_db` |
| `DENDREO_API_KEY` | Dendreo API authentication | Required |
| `DENDREO_BASE_URL` | Dendreo API endpoint | Required |
| `HUBSPOT_API_KEY` | HubSpot integration | Optional |

### Docker Network
- Custom bridge network: `dendreo_network`
- Internal DNS resolution between containers
- Isolated from other Docker applications

### Volume Mounts
- `postgres_data`: Database persistence
- `./back/logs`: Application logs (host-mounted)
- `./database/init`: DB initialization scripts

## 📊 Monitoring and Health Checks

### Container Health
Each container has health check endpoints:
```bash
# Check all container status
docker-compose ps

# View container health
docker-compose exec backend curl -f http://localhost:8000/health
docker-compose exec postgres pg_isready -U postgres -d dendreo_db
```

### Application Logs
```bash
# View all logs
./deploy.sh logs

# View specific service logs
./deploy.sh logs backend
./deploy.sh logs postgres
./deploy.sh logs frontend

# Follow logs in real-time
docker-compose logs -f backend
```

### Database Monitoring
```bash
# Database connection count
docker-compose exec postgres psql -U postgres -d dendreo_db -c "
SELECT count(*) as connections, usename, application_name 
FROM pg_stat_activity 
GROUP BY usename, application_name;"

# Table sizes
docker-compose exec postgres psql -U postgres -d dendreo_db -c "
SELECT schemaname,tablename,pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size 
FROM pg_tables 
WHERE schemaname='public';"
```

## 🔄 Management Operations

### Starting/Stopping
```bash
# Start all services
./deploy.sh start

# Stop all services
./deploy.sh stop

# Restart all services
./deploy.sh restart

# View status
./deploy.sh status
```

### Database Operations
```bash
# Create backup
./deploy.sh backup

# Restore from backup
./deploy.sh restore backup_dendreo_db_20231201_120000.sql

# Access database directly
docker-compose exec postgres psql -U postgres dendreo_db
```

### Container Management
```bash
# Rebuild containers (after code changes)
docker-compose build --no-cache
docker-compose up -d

# Scale services (if needed)
docker-compose up -d --scale backend=2

# View resource usage
docker stats
```

## 🔧 Troubleshooting

### Common Issues

#### Database Connection Failed
```bash
# Check database status
docker-compose exec postgres pg_isready -U postgres -d dendreo_db

# View database logs
docker-compose logs postgres

# Restart database
docker-compose restart postgres
```

#### Backend Not Starting
```bash
# Check backend logs
docker-compose logs backend

# Check database connectivity from backend
docker-compose exec backend python -c "
from app.models.database import engine
try:
    with engine.connect() as conn:
        result = conn.execute('SELECT 1')
        print('Database connection: OK')
except Exception as e:
    print(f'Database connection failed: {e}')
"
```

#### Frontend Build Errors
```bash
# Rebuild frontend with verbose output
docker-compose build --no-cache frontend

# Check nginx configuration
docker-compose exec frontend nginx -t
```

#### Port Conflicts
```bash
# Check port usage
netstat -tulpn | grep -E ":(3000|8000|5432)"

# Kill processes using ports
sudo lsof -ti:3000 | xargs kill -9
```

### Performance Issues

#### Database Performance
```bash
# Check slow queries
docker-compose exec postgres psql -U postgres -d dendreo_db -c "
SELECT query, mean_time, calls 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;"

# Vacuum and analyze
docker-compose exec postgres psql -U postgres -d dendreo_db -c "VACUUM ANALYZE;"
```

#### Memory Usage
```bash
# Check container memory usage
docker stats --no-stream

# Limit container memory (in docker-compose.yml)
# services:
#   postgres:
#     mem_limit: 1g
#   backend:
#     mem_limit: 512m
```

### Log Analysis
```bash
# Backend errors
docker-compose logs backend | grep ERROR

# Database connection issues
docker-compose logs backend | grep -i "database\|connection"

# Frontend 404s
docker-compose logs frontend | grep " 404 "
```

## 🔒 Security Considerations

### Network Security
- Use custom Docker network for container isolation
- Don't expose database port externally in production
- Implement reverse proxy with SSL termination

### Database Security
```bash
# Change default passwords (in .env file)
POSTGRES_PASSWORD=your_secure_password_here

# Create application-specific database user
docker-compose exec postgres psql -U postgres -c "
CREATE USER dendreo_app WITH PASSWORD 'secure_app_password';
GRANT CONNECT ON DATABASE dendreo_db TO dendreo_app;
GRANT USAGE ON SCHEMA public TO dendreo_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO dendreo_app;
"
```

### API Security
- Keep API keys in environment variables, never in code
- Use HTTPS in production
- Implement rate limiting
- Monitor API access logs

## 📦 Production Deployment

### Environment Preparation
```bash
# Production environment file
cp docker.env.example .env.production

# Edit for production
nano .env.production
```

### Production docker-compose
Create `docker-compose.prod.yml`:
```yaml
version: '3.8'
services:
  postgres:
    restart: always
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
  
  backend:
    restart: always
    environment:
      - APP_ENV=production
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
  
  frontend:
    restart: always
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### Deploy to Production
```bash
# Deploy with production config
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## 🔄 Updates and Maintenance

### Application Updates
```bash
# Pull latest code
git pull origin main

# Rebuild containers
docker-compose build --no-cache

# Rolling update (zero downtime)
docker-compose up -d --no-deps backend
docker-compose up -d --no-deps frontend
```

### Database Maintenance
```bash
# Regular backup (add to cron)
./deploy.sh backup

# Monthly maintenance
docker-compose exec postgres psql -U postgres -d dendreo_db -c "
VACUUM ANALYZE;
REINDEX DATABASE dendreo_db;
"
```

### Log Rotation
```bash
# Clear old logs
docker-compose exec backend sh -c "find /app/logs -name '*.log' -mtime +30 -delete"

# Rotate Docker logs
docker system prune -f --volumes
```

## 📋 Checklist

### Pre-Deployment
- [ ] Docker and Docker Compose installed
- [ ] Environment variables configured in `.env`
- [ ] Required ports (3000, 8000, 5432) available
- [ ] API keys validated
- [ ] Network connectivity verified

### Post-Deployment
- [ ] All containers running and healthy
- [ ] Database schema created successfully
- [ ] Frontend accessible and loading
- [ ] Backend API responding
- [ ] Health checks passing
- [ ] Logs showing no errors

### Regular Maintenance
- [ ] Weekly database backups
- [ ] Monthly log cleanup
- [ ] Quarterly security updates
- [ ] Monitor disk space usage
- [ ] Review application logs

## 🆘 Support

### Logs and Debugging
Always collect these when reporting issues:
```bash
# Full deployment status
./deploy.sh status

# All container logs
./deploy.sh logs > deployment_logs.txt

# System information
docker version > system_info.txt
docker-compose version >> system_info.txt
```

### Useful Commands
```bash
# Complete reset (WARNING: destroys all data)
./deploy.sh cleanup

# Emergency database backup
docker-compose exec postgres pg_dump -U postgres dendreo_db > emergency_backup.sql

# Container shell access
docker-compose exec backend bash
docker-compose exec postgres bash
docker-compose exec frontend sh
```