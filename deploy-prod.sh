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
    
    # Check required variables
    required_vars=("POSTGRES_PASSWORD" "DENDREO_API_KEY")
    missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ] || [ "${!var}" = "CHANGE_ME_TO_SECURE_PASSWORD" ] || [ "${!var}" = "YOUR_DENDREO_API_KEY_HERE" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -ne 0 ]; then
        log_error "The following required environment variables are not set or still have placeholder values:"
        printf '  - %s\n' "${missing_vars[@]}"
        log_error "Please update .env.prod with actual values"
        exit 1
    fi
    
    log_success "Environment validation passed"
}

# Build and start services
deploy() {
    log_info "Starting production deployment..."
    
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
    
    # Build and start services
    log_info "Building and starting services..."
    docker compose -f docker-compose.prod.yml up --build -d
    
    # Wait for services to be healthy
    log_info "Waiting for services to be healthy..."
    sleep 10
    
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
    
    # Check frontend
    if docker compose -f docker-compose.prod.yml ps frontend | grep -q "Up"; then
        log_success "Frontend is running"
    else
        log_error "Frontend failed to start"
        docker compose -f docker-compose.prod.yml logs frontend
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
    
    log_success "All services are running successfully!"
}

# Show status and URLs
show_status() {
    log_info "Deployment completed successfully!"
    echo
    echo "📊 Service Status:"
    docker compose -f docker-compose.prod.yml ps
    echo
    echo "🌐 Application URLs:"
    echo "   Frontend: http://localhost"
    echo "   API: http://localhost/api"
    echo "   Health Check: http://localhost/health"
    echo
    echo "📝 Useful Commands:"
    echo "   View logs: docker compose -f docker-compose.prod.yml logs -f [service]"
    echo "   Stop services: docker compose -f docker-compose.prod.yml down"
    echo "   Restart services: docker compose -f docker-compose.prod.yml restart"
    echo "   Update services: docker compose -f docker-compose.prod.yml up --build -d"
    echo
    echo "🔧 For SSL setup:"
    echo "   1. Place SSL certificates in ./ssl/ directory"
    echo "   2. Update nginx/prod.conf to enable HTTPS server block"
    echo "   3. Restart nginx: docker compose -f docker-compose.prod.yml restart nginx"
}

# Usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  DEBUG=true    Enable debug mode to show loaded environment variables"
    echo ""
    echo "Examples:"
    echo "  ./deploy-prod.sh                    # Normal deployment"
    echo "  DEBUG=true ./deploy-prod.sh         # Debug deployment"
    echo ""
}

# Main execution
main() {
    # Check for help flag
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        show_usage
        exit 0
    fi
    
    echo "🚀 Dendreo Progression - Production Deployment"
    echo "=============================================="
    echo
    
    check_dependencies
    create_directories
    check_env_file
    source_env_variables
    validate_env
    deploy
    show_status
}

# Run main function
main "$@" 