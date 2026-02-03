# Dendreo Progression Multi-Environment Docker Deployment

This guide covers deploying the Dendreo Progression application with separate development and production environments using Docker Compose.

## 🏗️ Architecture Overview

The deployment supports two distinct environments:

### **Development Environment**
- **Source**: Builds from `dev` branch on GitHub
- **Frontend**: React development server with hot reload
- **Backend**: FastAPI with debug mode and hot reload
- **Database**: PostgreSQL on port 5433 with development data
- **Network**: `dendreo_dev_network`

### **Production Environment**
- **Source**: Builds from `main` branch on GitHub
- **Frontend**: Nginx serving optimized React build
- **Backend**: FastAPI with production optimizations
- **Database**: PostgreSQL with production tuning
- **Reverse Proxy**: Nginx with security headers and rate limiting
- **Network**: `dendreo_prod_network`

## 📋 Prerequisites

### System Requirements
- Docker Engine 20.10+
- Docker Compose 2.0+ (or docker-compose 1.29+)
- 4GB+ RAM recommended
- 10GB+ disk space
- Internet access for GitHub repository cloning

### GitHub Repository Setup
1. **Push your code to GitHub** with two branches:
   - `main` branch for production releases
   - `dev` branch for development work

2. **Update repository URL** in environment files:
   - Replace `YOUR_USERNAME` with your actual GitHub username
   - Ensure the repository is public or configure access credentials

## 🚀 Quick Start

### 1. Clone and Setup

```bash
git clone <your-repo-url>
cd DendreoProgression
chmod +x deploy.sh
```

### 2. Development Environment

```bash
# Start development environment
./deploy.sh --dev start

# Or using the longer form
./deploy.sh --environment dev start
```

**Development URLs:**
- Frontend: http://localhost:3000
- Backend: http://localhost:8000
- API Docs: http://localhost:8000/docs
- Database: localhost:5433

### 3. Production Environment

```bash
# Start production environment
./deploy.sh --prod start

# Or using the longer form
./deploy.sh --environment prod start
```

**Production URLs:**
- Frontend: http://localhost (port 80)
- Backend: http://localhost/api
- API Docs: http://localhost/api/docs
- Database: Internal only

## 📁 File Structure

```
DendreoProgression/
├── docker-compose.yml          # Base configuration
├── docker-compose.dev.yml      # Development overrides
├── docker-compose.prod.yml     # Production overrides
├── deploy.sh                   # Multi-environment deployment script
├── env.dev.example             # Development environment template
├── env.prod.example            # Production environment template
├── back/
│   ├── Dockerfile              # Production backend Dockerfile
│   └── Dockerfile.dev          # Development backend Dockerfile
├── frontend/
│   ├── Dockerfile              # Production frontend Dockerfile
│   └── Dockerfile.dev          # Development frontend Dockerfile
├── nginx/
│   └── prod.conf               # Production Nginx configuration
└── database/
    ├── init/                   # Database initialization scripts
    └── dev-data/               # Development sample data
```

## ⚙️ Configuration

### Environment Files

#### Development (.env.dev)
```bash
# Copy and customize the development environment
cp env.dev.example .env.dev
```

**Key development settings:**
- `APP_ENV=development`
- `LOG_LEVEL=DEBUG`
- `POSTGRES_PORT=5433` (to avoid conflicts)
- GitHub branch: `dev`

#### Production (.env.prod)
```bash
# Copy and customize the production environment
cp env.prod.example .env.prod
```

**Important production settings:**
- `APP_ENV=production`
- `LOG_LEVEL=INFO`
- Secure passwords and API keys
- GitHub branch: `main`

### Required Configuration

1. **Update GitHub Repository URL** in both environment files:
   ```bash
   GITHUB_REPO=https://github.com/YOUR_USERNAME/DendreoProgression.git
   ```

2. **Set API Keys**:
   ```bash
   DENDREO_API_KEY=your_actual_api_key
   HUBSPOT_API_KEY=your_actual_api_key
   ```

3. **Production Security** (for .env.prod):
   ```bash
   POSTGRES_PASSWORD=your_secure_production_password
   SECRET_KEY=your_very_long_secret_key
   ```

## 🛠️ Deployment Commands

### Basic Operations

```bash
# Start development environment
./deploy.sh --dev start

# Start production environment
./deploy.sh --prod start

# Check status
./deploy.sh --dev status
./deploy.sh --prod status

# View logs
./deploy.sh --dev logs
./deploy.sh --prod logs backend

# Stop environment
./deploy.sh --dev stop
./deploy.sh --prod stop
```

### Advanced Operations

```bash
# Switch between environments
./deploy.sh switch                    # Toggle current environment
./deploy.sh switch prod              # Switch to production

# Rebuild specific services
./deploy.sh --dev rebuild backend    # Rebuild dev backend
./deploy.sh --prod rebuild frontend  # Rebuild prod frontend

# Database operations
./deploy.sh --dev backup             # Backup dev database
./deploy.sh --prod backup            # Backup prod database
./deploy.sh --dev restore backup.sql # Restore dev database

# Complete cleanup
./deploy.sh --dev cleanup            # Remove dev containers/images
./deploy.sh --prod cleanup           # Remove prod containers/images
```

## 🔧 Development Workflow

### 1. Daily Development
```bash
# Start development environment
./deploy.sh --dev start

# Make code changes, push to dev branch
git add .
git commit -m "Your changes"
git push origin dev

# Rebuild to get latest changes
./deploy.sh --dev rebuild backend
./deploy.sh --dev rebuild frontend
```

### 2. Testing Production Build
```bash
# Switch to production environment for testing
./deploy.sh switch prod

# Test the production build
# Switch back to development
./deploy.sh switch dev
```

### 3. Production Deployment
```bash
# Merge dev to main
git checkout main
git merge dev
git push origin main

# Deploy production with latest main branch
./deploy.sh --prod stop
./deploy.sh --prod start
```

## 🛡️ Security Considerations

### Development Environment
- Exposed database port (5433)
- Debug mode enabled
- Less restrictive security headers
- Development dependencies included

### Production Environment
- Database not exposed to host
- Security headers enabled
- Rate limiting configured
- Optimized builds only
- Nginx reverse proxy with SSL support

### SSL Configuration (Production)

1. **Obtain SSL certificates** and place them in `nginx/ssl/`:
   ```
   nginx/ssl/cert.pem
   nginx/ssl/key.pem
   ```

2. **Update nginx configuration** to enable HTTPS block in `nginx/prod.conf`

3. **Update environment variables**:
   ```bash
   SSL_CERT_PATH=/etc/nginx/ssl/cert.pem
   SSL_KEY_PATH=/etc/nginx/ssl/key.pem
   ```

## 🔍 Monitoring and Debugging

### Viewing Logs
```bash
# All services
./deploy.sh --dev logs
./deploy.sh --prod logs

# Specific service
./deploy.sh --dev logs backend
./deploy.sh --prod logs frontend
./deploy.sh --prod logs nginx
```

### Health Checks
```bash
# Check container health
./deploy.sh --dev status
./deploy.sh --prod status

# Manual health check
curl http://localhost:8000/health      # Dev backend
curl http://localhost/health           # Prod backend
```

### Database Access
```bash
# Development (external access)
psql -h localhost -p 5433 -U postgres -d dendreo_dev_db

# Production (through container)
./deploy.sh --prod exec postgres psql -U dendreo_user -d dendreo_prod_db
```

## 🚨 Troubleshooting

### Common Issues

1. **Port Conflicts**
   ```bash
   # Check what's using the port
   netstat -tulpn | grep :3000
   
   # Kill process or change port in environment file
   ```

2. **GitHub Access Issues**
   ```bash
   # Verify repository URL in environment file
   grep GITHUB_REPO .env.dev
   
   # Test repository access
   git ls-remote https://github.com/YOUR_USERNAME/DendreoProgression.git
   ```

3. **Database Connection Issues**
   ```bash
   # Check database logs
   ./deploy.sh --dev logs postgres
   
   # Verify environment variables
   ./deploy.sh --dev exec postgres env | grep POSTGRES
   ```

4. **Build Failures**
   ```bash
   # Clean build cache
   docker system prune -af
   
   # Rebuild without cache
   ./deploy.sh --dev rebuild backend
   ```

### Performance Issues

1. **Frontend Build Slow**
   - Increase Docker memory allocation
   - Use `.dockerignore` to exclude unnecessary files

2. **Database Performance**
   - Production includes PostgreSQL tuning
   - Monitor with `./deploy.sh --prod logs postgres`

## 📈 Scaling Considerations

### Resource Limits (Production)
- **Backend**: 1 CPU, 1GB RAM
- **Frontend**: 0.5 CPU, 512MB RAM
- **Database**: 1 CPU, 2GB RAM
- **Nginx**: 0.25 CPU, 128MB RAM

### Horizontal Scaling
To scale beyond single server:
1. Extract database to external service
2. Use container orchestration (Kubernetes, Docker Swarm)
3. Implement load balancing
4. Add shared storage for logs and data

## 🔄 CI/CD Integration

### GitHub Actions Example
```yaml
# .github/workflows/deploy.yml
name: Deploy to Production
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy to Production
        run: |
          ssh user@your-server "cd /path/to/DendreoProgression && ./deploy.sh --prod start"
```

## 📚 Additional Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Nginx Configuration Reference](https://nginx.org/en/docs/)
- [PostgreSQL Performance Tuning](https://www.postgresql.org/docs/current/runtime-config.html)
- [React Production Build](https://create-react-app.dev/docs/production-build/)
- [FastAPI Deployment](https://fastapi.tiangolo.com/deployment/)

## 💡 Best Practices

1. **Environment Separation**: Never use production data in development
2. **Secrets Management**: Use environment variables for sensitive data
3. **Regular Backups**: Schedule automated database backups for production
4. **Monitoring**: Implement health checks and monitoring for production
5. **Testing**: Test production builds before deploying to live environment
6. **Documentation**: Keep environment configurations documented and up-to-date

## 🤝 Contributing

When contributing to this project:
1. Work on the `dev` branch
2. Test changes in development environment
3. Create pull requests to merge into `main`
4. Production deployments should only use the `main` branch