# Production Deployment Guide

This guide explains how to deploy the Dendreo Progression application in production mode.

## 🏗️ Production Architecture

The production setup includes:

- **Nginx**: Reverse proxy and load balancer (port 80/443)
- **Backend**: FastAPI application with PostgreSQL
- **Frontend**: React application served by Nginx
- **PostgreSQL**: Production database with optimized settings
- **Redis**: Optional caching layer

## 📋 Prerequisites

1. **Docker & Docker Compose** installed on your production server
2. **Domain name** (optional, for SSL)
3. **SSL certificates** (optional, for HTTPS)

## ⚙️ Quick Setup

### 1. Clone and Configure

```bash
git clone <your-repo-url>
cd DendreoProgression

# Copy environment template
cp env.prod.example .env.prod
```

### 2. Configure Environment

Edit `.env.prod` with your production values:

```bash
# Required - Update these values
POSTGRES_PASSWORD=your_secure_database_password
DENDREO_API_KEY=your_dendreo_api_key
HUBSPOT_API_KEY=your_hubspot_api_key

# Recommended - Generate secure keys
SECRET_KEY=your_very_long_secret_key_here
JWT_SECRET=your_jwt_secret_here
```

### 3. Deploy

**Option A: Using the deployment script (Linux/Mac)**
```bash
chmod +x deploy-prod.sh
./deploy-prod.sh
```

**Option B: Manual deployment (Windows/Linux/Mac)**
```bash
# Create required directories
mkdir -p logs/nginx ssl

# Start production services
docker-compose -f docker-compose.prod.yml up --build -d
```

## 🔧 Manual Configuration Steps

### 1. Environment File Setup

Create `.env.prod` from the template:

```bash
# Production Environment Configuration
APP_ENV=production
NODE_ENV=production
LOG_LEVEL=INFO

# Database Configuration - REQUIRED
POSTGRES_DB=dendreo_prod_db
POSTGRES_USER=dendreo_user
POSTGRES_PASSWORD=CHANGE_ME_TO_SECURE_PASSWORD  # ⚠️ CHANGE THIS
DATABASE_URL=postgresql://dendreo_user:CHANGE_ME_TO_SECURE_PASSWORD@postgres:5432/dendreo_prod_db

# API Configuration - REQUIRED
DENDREO_API_KEY=YOUR_DENDREO_API_KEY_HERE  # ⚠️ CHANGE THIS
DENDREO_BASE_URL=https://pro.dendreo.com/competences_et_metiers/api

# HubSpot Configuration - OPTIONAL
HUBSPOT_API_KEY=YOUR_HUBSPOT_API_KEY_HERE

# Security Configuration - RECOMMENDED
SECRET_KEY=CHANGE_ME_TO_VERY_LONG_SECRET_KEY  # ⚠️ CHANGE THIS
JWT_SECRET=CHANGE_ME_TO_JWT_SECRET            # ⚠️ CHANGE THIS
```

### 2. Create Required Directories

```bash
mkdir -p logs/nginx  # Nginx logs
mkdir -p ssl         # SSL certificates (if using HTTPS)
```

### 3. Deploy Services

```bash
# Stop any existing containers
docker-compose -f docker-compose.prod.yml down --remove-orphans

# Build and start all services
docker-compose -f docker-compose.prod.yml up --build -d

# Check status
docker-compose -f docker-compose.prod.yml ps
```

## 🌐 Service URLs

After deployment, your application will be available at:

- **Frontend**: http://localhost
- **API**: http://localhost/api
- **Health Check**: http://localhost/health

## 🔒 SSL/HTTPS Setup (Optional)

### 1. Obtain SSL Certificates

Place your SSL certificates in the `ssl/` directory:
```
ssl/
├── cert.pem      # Your SSL certificate
└── key.pem       # Your private key
```

### 2. Update Nginx Configuration

Edit `nginx/prod.conf` and uncomment the HTTPS server block:

```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    
    # ... rest of configuration
}
```

### 3. Update Docker Compose

Uncomment the SSL volume mount in `docker-compose.prod.yml`:

```yaml
nginx:
  volumes:
    - ./ssl:/etc/nginx/ssl:ro  # Uncomment this line
```

### 4. Restart Nginx

```bash
docker-compose -f docker-compose.prod.yml restart nginx
```

## 📊 Monitoring & Management

### View Logs

```bash
# All services
docker-compose -f docker-compose.prod.yml logs -f

# Specific service
docker-compose -f docker-compose.prod.yml logs -f nginx
docker-compose -f docker-compose.prod.yml logs -f backend
docker-compose -f docker-compose.prod.yml logs -f frontend
docker-compose -f docker-compose.prod.yml logs -f postgres
```

### Service Management

```bash
# Check status
docker-compose -f docker-compose.prod.yml ps

# Restart services
docker-compose -f docker-compose.prod.yml restart

# Stop services
docker-compose -f docker-compose.prod.yml down

# Update and restart
docker-compose -f docker-compose.prod.yml up --build -d
```

### Health Checks

All services include health checks. Check their status:

```bash
# View health status
docker-compose -f docker-compose.prod.yml ps

# Test API health
curl http://localhost/health
```

## 🔧 Database Management

### Backup Database

```bash
docker-compose -f docker-compose.prod.yml exec postgres pg_dump -U dendreo_user dendreo_prod_db > backup.sql
```

### Restore Database

```bash
docker-compose -f docker-compose.prod.yml exec -T postgres psql -U dendreo_user dendreo_prod_db < backup.sql
```

### Access Database

```bash
docker-compose -f docker-compose.prod.yml exec postgres psql -U dendreo_user dendreo_prod_db
```

## 🚀 Performance Optimization

### PostgreSQL Tuning

The production setup includes optimized PostgreSQL settings:

- `POSTGRES_SHARED_BUFFERS=256MB`
- `POSTGRES_EFFECTIVE_CACHE_SIZE=1GB`
- `POSTGRES_MAX_CONNECTIONS=200`

### Nginx Optimization

The production Nginx configuration includes:

- Gzip compression
- Static file caching
- Rate limiting
- Security headers

### Redis (Optional)

To enable Redis caching, uncomment the Redis service in `docker-compose.prod.yml` and set:

```bash
REDIS_ENABLED=true
```

## 🛠️ Troubleshooting

### Common Issues

1. **Service fails to start**
   ```bash
   # Check logs for specific service
   docker-compose -f docker-compose.prod.yml logs [service-name]
   ```

2. **Database connection issues**
   ```bash
   # Check database health
   docker-compose -f docker-compose.prod.yml exec postgres pg_isready -U dendreo_user
   ```

3. **Environment variables not loaded**
   - Ensure `.env.prod` exists and has correct values
   - Check for syntax errors in the environment file

4. **Nginx fails to start**
   ```bash
   # Test nginx configuration
   docker-compose -f docker-compose.prod.yml exec nginx nginx -t
   ```

### Reset Everything

```bash
# Stop and remove all containers, networks, and volumes
docker-compose -f docker-compose.prod.yml down --volumes --remove-orphans

# Remove all images
docker-compose -f docker-compose.prod.yml down --rmi all

# Start fresh
docker-compose -f docker-compose.prod.yml up --build -d
```

## 📋 Production Checklist

Before going live, ensure:

- [ ] `.env.prod` has been configured with secure, production values
- [ ] Database password is strong and unique
- [ ] API keys are correctly set
- [ ] SSL certificates are configured (if using HTTPS)
- [ ] Domain DNS is pointing to your server
- [ ] Firewall allows traffic on ports 80 and 443
- [ ] Regular backups are scheduled
- [ ] Monitoring is in place
- [ ] Log rotation is configured

## 🔄 Updates and Maintenance

### Update Application

```bash
# Pull latest code
git pull origin main

# Rebuild and restart services
docker-compose -f docker-compose.prod.yml up --build -d
```

### Update Dependencies

```bash
# Update Docker images
docker-compose -f docker-compose.prod.yml pull

# Restart with updated images
docker-compose -f docker-compose.prod.yml up -d
```

## 📞 Support

For issues with the production deployment:

1. Check the logs: `docker-compose -f docker-compose.prod.yml logs -f`
2. Verify configuration: Ensure all required environment variables are set
3. Check service health: `docker-compose -f docker-compose.prod.yml ps`
4. Review this guide for common solutions

---

**Security Note**: Always use strong, unique passwords and API keys in production. Regularly update your dependencies and monitor your application for security vulnerabilities. 