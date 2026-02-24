#!/bin/bash

# Dendreo Progression Language Feature Deployment Script
# This script deploys the application with the new internationalization feature

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="dendreo-progression"
DEFAULT_ENV="dev"

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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_warning "Docker Compose not found, attempting to install..."
        # Try to install docker-compose
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y docker-compose-plugin
        elif command -v yum &> /dev/null; then
            sudo yum install -y docker-compose-plugin
        else
            log_error "Cannot install Docker Compose automatically. Please install it manually."
            exit 1
        fi
    fi
    
    log_success "Prerequisites check completed"
}

# Clean up Docker system to free space
clean_docker_system() {
    log_info "Cleaning Docker system to free space..."
    
    # Remove unused containers
    docker container prune -f
    
    # Remove unused images
    docker image prune -a -f
    
    # Remove unused volumes
    docker volume prune -f
    
    # Remove unused networks
    docker network prune -f
    
    # Clean build cache
    docker builder prune -a -f
    
    log_success "Docker system cleaned"
}

# Deploy with HTTP-only configuration
deploy_http_only() {
    log_info "Deploying with HTTP-only configuration..."
    
    # Copy HTTP-only nginx config
    if [ -f "nginx/prod.http-only.conf" ]; then
        cp nginx/prod.http-only.conf nginx/prod.conf
        log_info "Using HTTP-only nginx configuration"
    else
        log_error "HTTP-only nginx configuration not found"
        exit 1
    fi
    
    # Use optimized sync Dockerfile
    if [ -f "back/Dockerfile.sync.optimized" ]; then
        cp back/Dockerfile.sync.optimized back/Dockerfile.sync
        log_info "Using optimized sync Dockerfile"
    fi
    
    # Deploy using docker-compose
    if command -v docker-compose &> /dev/null; then
        docker-compose up --build -d
    else
        docker compose up --build -d
    fi
    
    log_success "Deployment completed"
}

# Test the deployment
test_deployment() {
    log_info "Testing deployment..."
    
    # Wait for services to start
    sleep 30
    
    # Test frontend
    if curl -f http://localhost:3000 > /dev/null 2>&1; then
        log_success "Frontend is accessible at http://localhost:3000"
    else
        log_warning "Frontend not accessible yet, may still be starting..."
    fi
    
    # Test backend
    if curl -f http://localhost:8000/health > /dev/null 2>&1; then
        log_success "Backend is accessible at http://localhost:8000"
    else
        log_warning "Backend not accessible yet, may still be starting..."
    fi
    
    # Test API
    if curl -f http://localhost:8000/api/courses/stats > /dev/null 2>&1; then
        log_success "API is working correctly"
    else
        log_warning "API not accessible yet, may still be starting..."
    fi
}

# Show deployment status
show_status() {
    log_info "Deployment Status:"
    
    echo ""
    echo "🌐 Frontend (with Language Feature):"
    echo "   URL: http://localhost:3000"
    echo "   Language Selector: Globe icon (🌐) in top-right corner"
    echo "   Default Language: French"
    echo "   Available Languages: French, English"
    echo ""
    
    echo "🔧 Backend API:"
    echo "   URL: http://localhost:8000"
    echo "   Health Check: http://localhost:8000/health"
    echo "   API Docs: http://localhost:8000/docs"
    echo ""
    
    echo "🗄️ Database:"
    echo "   Type: PostgreSQL"
    echo "   Port: 5432 (internal)"
    echo ""
    
    echo "📊 Sync Service:"
    echo "   Status: Running in background"
    echo "   Schedule: Daily at 8 AM (configurable)"
    echo ""
    
    echo "🔍 Troubleshooting:"
    echo "   - Check logs: docker-compose logs -f"
    echo "   - Restart services: docker-compose restart"
    echo "   - View containers: docker-compose ps"
    echo ""
}

# Main deployment function
main() {
    log_info "Starting Dendreo Progression Language Feature Deployment"
    log_info "========================================================"
    
    # Check prerequisites
    check_prerequisites
    
    # Clean Docker system to free space
    clean_docker_system
    
    # Deploy with HTTP-only configuration
    deploy_http_only
    
    # Test the deployment
    test_deployment
    
    # Show status
    show_status
    
    log_success "Deployment completed successfully!"
    log_info "Access your application at: http://localhost:3000"
    log_info "Language selector is available in the top-right corner"
}

# Run main function
main "$@" 