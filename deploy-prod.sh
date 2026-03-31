#!/bin/bash

# Production Deployment Script for Dendreo Progression
# This script sets up and deploys the application in production mode

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker and Docker Compose are installed
check_dependencies() {
    log_info "Checking dependencies..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not available. Please ensure Docker Compose is installed."
        exit 1
    fi
    
    log_success "Dependencies check passed"
}

# Create necessary directories
create_directories() {
    log_info "Creating necessary directories..."

    mkdir -p logs/nginx
    mkdir -p ssl

    log_success "Directories created"
}

# Auto-detect SSL certificates and select the appropriate nginx config
configure_nginx_ssl() {
    log_info "Detecting SSL configuration..."

    if [ -f "./ssl/fullchain.pem" ] && [ -f "./ssl/privkey.pem" ]; then
        log_success "SSL certificates found - enabling HTTPS"
        cp ./nginx/prod.conf ./nginx/prod.active.conf
        NGINX_SSL_ENABLED=true
    else
        log_warning "SSL certificates not found in ./ssl/ - using HTTP-only mode"
        cp ./nginx/prod.http-only.conf ./nginx/prod.active.conf
        NGINX_SSL_ENABLED=false
    fi
}

# Check if .env.prod exists
check_env_file() {
    log_info "Checking environment configuration..."
    
    if [ ! -f ".env.prod" ]; then
        log_warning ".env.prod file not found. Creating from template..."
        
        if [ -f "env.prod.example" ]; then
            cp env.prod.example .env.prod
            log_warning "Please edit .env.prod with your production values:"
            log_warning "  - POSTGRES_PASSWORD: Set a secure database password"
            log_warning "  - DENDREO_API_KEY: Your Dendreo API key"
            log_warning "  - HUBSPOT_API_KEY: Your HubSpot API key"
            log_warning "  - SECRET_KEY: Generate a secure secret key"
            log_warning "  - JWT_SECRET: Generate a secure JWT secret"
            
            read -p "Press Enter after updating .env.prod to continue..."
        else
            log_error "env.prod.example not found. Cannot create .env.prod"
            exit 1
        fi
    else
        log_success "Environment file found"
    fi
}

# Source and export environment variables
source_env_variables() {
    log_info "Loading environment variables from .env.prod..."
    
    if [ -f ".env.prod" ]; then
        # Export all variables from .env.prod (skip comments and empty lines)
        set -a  # Enable auto-export of variables
        source .env.prod
        set +a  # Disable auto-export
        
        log_success "Environment variables loaded and exported"
        
        # Count and show loaded variables
        var_count=$(grep -v '^#\|^$' .env.prod | wc -l)
        log_info "Loaded ${var_count} environment variables"
        
        # Show debug info if DEBUG=true
        if [ "${DEBUG:-false}" = "true" ]; then
            log_info "Environment variables loaded:"
            while IFS='=' read -r key value; do
                if [[ ! $key =~ ^#.*$ ]] && [[ ! -z $key ]]; then
                    # Mask sensitive values
                    if [[ $key =~ (PASSWORD|KEY|SECRET|TOKEN) ]]; then
                        masked_value="${value:0:4}****"
                    else
                        masked_value="$value"
                    fi
                    echo "  $key=$masked_value"
                fi
            done < .env.prod
        fi
    else
        log_error ".env.prod file not found"
        exit 1
    fi
}

# Validate required environment variables
validate_env() {
    log_info "Validating environment variables..."
    
    # Check required variables (including sync-related ones)
    required_vars=("POSTGRES_PASSWORD" "DENDREO_API_KEY" "DENDREO_BASE_URL" "DATABASE_URL")
    missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ] || [ "${!var}" = "CHANGE_ME_TO_SECURE_PASSWORD" ] || [ "${!var}" = "YOUR_DENDREO_API_KEY_HERE" ] || [ "${!var}" = "your_dendreo_api_key_here" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -ne 0 ]; then
        log_error "The following required environment variables are not set or still have placeholder values:"
        printf '  - %s\n' "${missing_vars[@]}"
        log_error "Please update .env.prod with actual values"
        exit 1
    fi
    
    # Check if API keys are not placeholder values
    if [[ "$DENDREO_API_KEY" == "your_dendreo_api_key_here" ]]; then
        log_error "DENDREO_API_KEY is still set to placeholder value"
        exit 1
    fi
    
    log_success "Environment validation passed"
}

# Prepare sync scripts
prepare_sync_scripts() {
    log_info "Preparing sync scripts..."
    
    # Make sync scripts executable
    chmod +x ./back/scripts/sync_wrapper_prod.sh 2>/dev/null || log_warning "sync_wrapper_prod.sh not found"
    chmod +x ./back/scripts/sync_wrapper_fixed.sh 2>/dev/null || log_warning "sync_wrapper_fixed.sh not found"
    chmod +x ./back/scripts/diagnose_cron.py 2>/dev/null || log_warning "diagnose_cron.py not found"
    chmod +x ./back/scripts/check_sync_status.py 2>/dev/null || log_warning "check_sync_status.py not found"
    chmod +x ./back/scripts/setup_sync_table.py 2>/dev/null || log_warning "setup_sync_table.py not found"
    chmod +x ./back/scripts/test_sync_cron.py 2>/dev/null || log_warning "test_sync_cron.py not found"
    
    log_success "Sync scripts prepared"
}

# Build and start services
deploy() {
    log_info "Starting production deployment with optimized frontend architecture..."
    
    # Check for force rebuild flag
    local build_args=""
    if [[ "$FORCE_REBUILD" == "true" ]] || [[ "$1" == "--force-rebuild" ]]; then
        build_args="--no-cache"
        log_info "Force rebuild requested - building without cache"
    fi
    
    # Ensure environment variables are available to docker-compose
    log_info "Verifying environment variables for Docker Compose..."
    if [ -z "$DATABASE_URL" ]; then
        log_error "DATABASE_URL not found in environment. Re-sourcing .env.prod..."
        set -a
        source .env.prod
        set +a
    fi
    
    # Debug: Show some key variables (masked)
    log_info "Key variables check:"
    log_info "  DATABASE_URL: ${DATABASE_URL:0:20}..."
    log_info "  DENDREO_API_KEY: ${DENDREO_API_KEY:0:10}..."
    
    # Stop any running containers
    log_info "Stopping any existing containers..."
    docker compose -f docker-compose.prod.yml down --remove-orphans
    
    # Set cache-busting environment variables
    export BUILD_DATE=$(date)
    export BUILD_VERSION=$(git rev-parse HEAD 2>/dev/null || echo 'no-git')
    log_info "Build date: $BUILD_DATE"
    log_info "Build version: $BUILD_VERSION"
    
    # Build services in parallel (NODE_OPTIONS caps webpack heap to prevent OOM)
    if [[ -n "$build_args" ]]; then
        log_info "Building services with $build_args..."
        docker compose -f docker-compose.prod.yml build $build_args
    else
        log_info "Building services (using cache for performance)..."
        docker compose -f docker-compose.prod.yml build
    fi
    
    # Start all services (dependencies will handle order)
    log_info "Starting all services..."
    docker compose -f docker-compose.prod.yml up -d
    
    # Brief wait for containers to initialise
    log_info "Waiting for services to start..."
    sleep 5
    
    # Check service health
    log_info "Checking service health..."
    
    # Check nginx
    if docker compose -f docker-compose.prod.yml ps nginx | grep -q "Up"; then
        log_success "Nginx is running"
    else
        log_error "Nginx failed to start"
        docker compose -f docker-compose.prod.yml logs nginx
        exit 1
    fi
    
    # Check backend
    if docker compose -f docker-compose.prod.yml ps backend | grep -q "Up"; then
        log_success "Backend is running"
    else
        log_error "Backend failed to start"
        docker compose -f docker-compose.prod.yml logs backend
        exit 1
    fi
    
    # Check frontend build (verify files are available to nginx)
    if docker compose -f docker-compose.prod.yml exec nginx ls /usr/share/nginx/html/index.html >/dev/null 2>&1; then
        log_success "Frontend build is available to nginx"
    else
        log_error "Frontend build files not found in nginx"
        docker compose -f docker-compose.prod.yml logs frontend
        docker compose -f docker-compose.prod.yml logs nginx
        exit 1
    fi
    
    # Check database
    if docker compose -f docker-compose.prod.yml ps postgres | grep -q "Up"; then
        log_success "Database is running"
    else
        log_error "Database failed to start"
        docker compose -f docker-compose.prod.yml logs postgres
        exit 1
    fi
    
    # Check sync service
    if docker compose -f docker-compose.prod.yml ps sync | grep -q "Up"; then
        log_success "Sync service is running"
    else
        log_error "Sync service failed to start"
        docker compose -f docker-compose.prod.yml logs sync
        exit 1
    fi
    
    log_success "All services are running successfully!"
    
    # Test the new frontend architecture
    log_info "Testing frontend architecture..."

    # Use the right protocol based on SSL detection
    if [ "$NGINX_SSL_ENABLED" = true ]; then
        local test_url="https://localhost"
        local curl_opts="-fk"  # -k to accept self-signed/local certs
    else
        local test_url="http://localhost"
        local curl_opts="-f"
    fi

    # Test frontend serving
    if curl $curl_opts "$test_url" >/dev/null 2>&1; then
        log_success "Frontend is accessible via nginx"
    else
        log_warning "Frontend not accessible via nginx (may take a moment to start)"
    fi

    # Test API routing through nginx
    if curl $curl_opts "$test_url/api/courses/stats" >/dev/null 2>&1; then
        log_success "API routing through nginx is working"
    else
        log_warning "API routing may still be starting (check logs if issues persist)"
    fi
}

# Initialize database and sync tables
initialize_database() {
    log_info "Initializing database and sync tables..."
    
    # Wait for database to be fully ready
    log_info "Waiting for database to be ready..."
    local timeout=60
    local counter=0
    
    while ! docker compose -f docker-compose.prod.yml exec -T postgres pg_isready -U postgres > /dev/null 2>&1; do
        if [ $counter -ge $timeout ]; then
            log_error "Database failed to be ready within $timeout seconds"
            exit 1
        fi
        sleep 2
        counter=$((counter + 2))
        echo -n "."
    done
    echo
    
    # Run database setup script for sync tables
    log_info "Setting up sync metadata tables..."
    if docker compose -f docker-compose.prod.yml exec -T sync python3 scripts/setup_sync_table.py 2>/dev/null; then
        log_success "Database and sync tables initialized successfully"
    else
        log_warning "Database initialization had issues (may already be initialized)"
    fi
}

# Test sync functionality
test_sync() {
    log_info "Testing sync functionality..."
    
    # Run sync diagnostic
    log_info "Running sync diagnostic..."
    if docker compose -f docker-compose.prod.yml exec -T sync python3 scripts/diagnose_cron.py 2>/dev/null; then
        log_success "Sync diagnostic passed"
    else
        log_warning "Sync diagnostic found issues - check logs for details"
    fi
    
    # Check sync status
    log_info "Checking sync status..."
    if docker compose -f docker-compose.prod.yml exec -T sync python3 scripts/check_sync_status.py 2>/dev/null; then
        log_success "Sync status check passed"
    else
        log_warning "Sync status check found issues - run manual checks"
    fi
    
    # Test new sync deployment logic
    log_info "Testing sync deployment logic..."
    if docker compose -f docker-compose.prod.yml exec -T sync python3 test_sync_deployment_logic.py 2>/dev/null; then
        log_success "Sync deployment logic test passed"
    else
        log_warning "Sync deployment logic test found issues - check logs for details"
    fi
}

# Show status and URLs
show_status() {
    log_info "Deployment completed successfully!"
    echo
    echo "📊 Service Status:"
    docker compose -f docker-compose.prod.yml ps
    echo
    echo "🌐 Application URLs:"
    if [ "$NGINX_SSL_ENABLED" = true ]; then
        echo "   Frontend: https://localhost (nginx serves React app with HTTPS)"
        echo "   API: https://localhost/api (nginx proxy to backend)"
        echo "   Health Check: https://localhost/health"
    else
        echo "   Frontend: http://localhost (nginx serves React app directly)"
        echo "   API: http://localhost/api (nginx proxy to backend)"
        echo "   Health Check: http://localhost/health"
    fi
    echo
    echo "📁 Frontend Architecture:"
    echo "   ✅ Optimized: Nginx serves static files directly"
    echo "   ✅ API Routing: /api/* requests proxied to backend"
    echo "   ✅ Universal: Works on any domain (localhost, IP, custom domain)"
    echo
    echo "🔄 Sync Configuration:"
    if [ -f ".env.prod" ]; then
        echo "   Schedule: $(grep SYNC_SCHEDULE .env.prod | cut -d'=' -f2 || echo '0 8 * * *')"
        echo "   Log Level: $(grep SYNC_LOG_LEVEL .env.prod | cut -d'=' -f2 || echo 'INFO')"
        echo "   ADF Limit: $(grep DENDREO_ADF_LIMIT .env.prod | cut -d'=' -f2 || echo 'unlimited')"
    fi
    echo
    echo "📝 Useful Commands:"
    echo "   View logs: docker compose -f docker-compose.prod.yml logs -f [service]"
    echo "   Stop services: docker compose -f docker-compose.prod.yml down"
    echo "   Restart services: docker compose -f docker-compose.prod.yml restart"
    echo "   Update services: docker compose -f docker-compose.prod.yml up --build -d"
    echo
    echo "🔄 Sync Management:"
    echo "   Check sync status: docker compose -f docker-compose.prod.yml exec sync python3 scripts/check_sync_status.py"
    echo "   Manual sync test: docker compose -f docker-compose.prod.yml exec sync python3 scripts/sync_dendreo.py"
    echo "   Test sync logic: docker compose -f docker-compose.prod.yml exec sync python3 test_sync_deployment_logic.py"
    echo "   View sync logs: docker compose -f docker-compose.prod.yml exec sync cat /app/logs/cron.log"
    echo "   Sync diagnostic: docker compose -f docker-compose.prod.yml exec sync python3 scripts/diagnose_cron.py"
    echo "   Monitor database: docker compose -f docker-compose.prod.yml exec postgres psql -U postgres -d dendreo_prod_db -c \"SELECT * FROM sync_metadata ORDER BY last_sync_at DESC LIMIT 5;\""
    echo
    echo "🧠 Smart Sync Logic:"
    echo "   • Sync only runs on deployment if no sync in last 24 hours"
    echo "   • Database persistence prevents unnecessary syncs"
    echo "   • Daily scheduled syncs at 8 AM continue as normal"
    echo "   • Manual syncs can still be forced with --force flag"
    echo
    echo "🔒 SSL Configuration:"
    if [ "$NGINX_SSL_ENABLED" = true ]; then
        echo "   ✅ HTTPS enabled (certificates found in ./ssl/)"
    else
        echo "   ⚠️  HTTP-only mode (no certificates in ./ssl/)"
        echo "   To enable HTTPS: place fullchain.pem and privkey.pem in ./ssl/ and redeploy"
    fi
}

# Usage information
show_usage() {
    echo "Production Deployment Script for Dendreo Progression"
    echo "===================================================="
    echo ""
    echo "This script deploys the complete production environment including:"
    echo "  • Frontend (React application - optimized static build)"
    echo "  • Backend (FastAPI server)"
    echo "  • Database (PostgreSQL)"
    echo "  • Sync Service (Automated data synchronization)"
    echo "  • Nginx (Serves frontend + API proxy)"
    echo "  • Redis (Caching layer)"
    echo ""
    echo "🏗️  Optimized Frontend Architecture:"
    echo "  • Nginx serves React static files directly (no separate frontend server)"
    echo "  • API calls routed through nginx proxy to backend"
    echo "  • Works universally across domains and IP addresses"
    echo "  • Eliminates CORS and CSP issues"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  DEBUG=true    Enable debug mode to show loaded environment variables"
    echo "  -h, --help    Show this help message"
    echo ""
    echo "Prerequisites:"
    echo "  • Docker and Docker Compose installed"
    echo "  • .env.prod file configured with production values"
    echo "  • Required API keys set in environment file"
    echo ""
    echo "Examples:"
    echo "  ./deploy-prod.sh                    # Normal production deployment (with cache)"
    echo "  ./deploy-prod.sh --force-rebuild    # Force complete rebuild (no cache)"
    echo "  DEBUG=true ./deploy-prod.sh         # Debug deployment"
    echo "  FORCE_REBUILD=true ./deploy-prod.sh # Force rebuild via environment"
    echo ""
    echo "After deployment, the sync service will automatically:"
    echo "  • Run daily at 8 AM (configurable via SYNC_SCHEDULE)"
    echo "  • Synchronize data from Dendreo API"
    echo "  • Update HubSpot progression data"
    echo "  • Log all activities for monitoring"
    echo ""
}

# Create backup
create_backup() {
    log_info "Creating backup of current deployment..."
    
    local backup_dir="./backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup database if it exists
    if docker compose -f docker-compose.prod.yml ps postgres | grep -q "Up" 2>/dev/null; then
        log_info "Backing up database..."
        if docker compose -f docker-compose.prod.yml exec -T postgres pg_dump -U postgres dendreo_prod_db > "$backup_dir/database_backup.sql" 2>/dev/null; then
            log_success "Database backup created: $backup_dir/database_backup.sql"
        else
            log_warning "Database backup failed (database may not be running)"
        fi
    fi
    
    # Backup logs
    if [ -d "./logs" ]; then
        cp -r ./logs "$backup_dir/logs_backup"
        log_success "Logs backup created: $backup_dir/logs_backup"
    fi
    
    # Backup environment file
    if [ -f ".env.prod" ]; then
        cp .env.prod "$backup_dir/env_backup"
        log_success "Environment backup created: $backup_dir/env_backup"
    fi
}

# Clean Docker cache and volumes
clean_docker_cache() {
    log_info "Cleaning Docker cache and volumes for fresh build..."
    
    # Remove frontend build volume if it exists
    if docker volume ls | grep -q "frontend_build"; then
        log_info "Removing frontend build volume..."
        docker volume rm dendreoprogression_frontend_build 2>/dev/null || log_warning "Frontend build volume not found"
    fi
    
    # Clean Docker builder cache
    log_info "Cleaning Docker builder cache..."
    docker builder prune -f
    
    # Clean unused Docker resources
    log_info "Cleaning unused Docker resources..."
    docker system prune -f
    
    log_success "Docker cache cleaned"
}

# Main execution
main() {
    # Check for help flag
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        show_usage
        exit 0
    fi
    
    echo "🚀 Dendreo Progression - Production Deployment with Sync"
    echo "========================================================"
    echo
    
    check_dependencies
    create_directories
    check_env_file
    source_env_variables
    validate_env
    prepare_sync_scripts
    configure_nginx_ssl
    create_backup

    # Only clean Docker cache when explicitly requested (preserves layer cache for faster, lighter builds)
    if [[ "$FORCE_REBUILD" == "true" ]] || [[ "$1" == "--force-rebuild" ]]; then
        clean_docker_cache
    fi

    deploy "$@"
    show_status
}

# Run main function
main "$@" 