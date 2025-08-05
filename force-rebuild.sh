#!/bin/bash

# Force Rebuild Script for Dendreo Progression
# This script forces a complete rebuild of the frontend with cache clearing

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

echo "🔄 Force Rebuild - Dendreo Progression Frontend"
echo "================================================"
echo

# Stop all services
log_info "Stopping all services..."
docker compose -f docker-compose.prod.yml down --remove-orphans

# Remove frontend build volume
log_info "Removing frontend build volume..."
docker volume rm dendreoprogression_frontend_build 2>/dev/null || log_warning "Frontend build volume not found"

# Clean Docker cache
log_info "Cleaning Docker cache..."
docker builder prune -f
docker system prune -f

# Set cache-busting environment variables
export BUILD_DATE=$(date)
export BUILD_VERSION=$(git rev-parse HEAD 2>/dev/null || echo 'no-git')
log_info "Build date: $BUILD_DATE"
log_info "Build version: $BUILD_VERSION"

# Build frontend with no cache
log_info "Building frontend with no cache..."
docker compose -f docker-compose.prod.yml build --no-cache frontend

# Start all services
log_info "Starting all services..."
docker compose -f docker-compose.prod.yml up -d

# Wait for services to start
log_info "Waiting for services to start..."
sleep 15

# Check frontend build
log_info "Checking frontend build..."
if docker compose -f docker-compose.prod.yml exec nginx ls /usr/share/nginx/html/index.html >/dev/null 2>&1; then
    log_success "Frontend build is available to nginx"
else
    log_error "Frontend build files not found in nginx"
    docker compose -f docker-compose.prod.yml logs frontend
    exit 1
fi

# Test frontend
log_info "Testing frontend..."
if curl -f http://localhost >/dev/null 2>&1; then
    log_success "Frontend is accessible"
else
    log_warning "Frontend not accessible (may take a moment to start)"
fi

log_success "Force rebuild completed!"
echo
echo "📊 Service Status:"
docker compose -f docker-compose.prod.yml ps
echo
echo "🔍 To check frontend logs:"
echo "   docker compose -f docker-compose.prod.yml logs frontend"
echo
echo "🌐 Frontend URL: http://localhost" 