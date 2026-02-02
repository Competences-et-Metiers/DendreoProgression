#!/bin/bash

# Build and Push Script with Rate Limit Avoidance
# Usage: ./scripts/build-and-push.sh [registry] [tag]

set -e

# Configuration
REGISTRY=${1:-"localhost:5000"}
TAG=${2:-"latest"}
PROJECT_NAME="dendreo"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

# Function to check if registry is available
check_registry() {
    local registry=$1
    if [[ $registry == "localhost:5000" ]]; then
        if ! docker ps --format "table {{.Names}}" | grep -q "local_registry"; then
            warning "Local registry not running. Starting it..."
            docker-compose -f docker-compose.local-registry.yml up -d registry
            sleep 5
        fi
    fi
}

# Function to build and tag image
build_and_tag() {
    local service=$1
    local dockerfile=$2
    local context=$3
    
    log "Building ${service} image..."
    
    # Build with cache
    docker build \
        --cache-from=${REGISTRY}/${PROJECT_NAME}-${service}:${TAG} \
        --cache-from=${REGISTRY}/${PROJECT_NAME}-${service}:latest \
        -t ${REGISTRY}/${PROJECT_NAME}-${service}:${TAG} \
        -t ${REGISTRY}/${PROJECT_NAME}-${service}:latest \
        -f ${dockerfile} \
        ${context}
    
    success "Built ${service} image"
}

# Function to push image with retry logic
push_with_retry() {
    local image=$1
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log "Pushing ${image} (attempt ${attempt}/${max_attempts})..."
        
        if docker push ${image}; then
            success "Pushed ${image}"
            return 0
        else
            error "Failed to push ${image} (attempt ${attempt}/${max_attempts})"
            
            if [ $attempt -lt $max_attempts ]; then
                warning "Retrying in 10 seconds..."
                sleep 10
            fi
        fi
        
        ((attempt++))
    done
    
    error "Failed to push ${image} after ${max_attempts} attempts"
    return 1
}

# Function to clean up old images
cleanup_images() {
    log "Cleaning up old images..."
    
    # Remove dangling images
    docker image prune -f
    
    # Remove old tagged images (keep last 3)
    for service in backend frontend; do
        old_images=$(docker images ${REGISTRY}/${PROJECT_NAME}-${service} --format "table {{.Repository}}:{{.Tag}}" | tail -n +2 | tail -n +4)
        if [ ! -z "$old_images" ]; then
            echo "$old_images" | xargs -r docker rmi || true
        fi
    done
    
    success "Cleanup completed"
}

# Main execution
main() {
    log "Starting build and push process..."
    log "Registry: ${REGISTRY}"
    log "Tag: ${TAG}"
    
    # Check if registry is available
    check_registry ${REGISTRY}
    
    # Build images
    build_and_tag "backend" "./back/Dockerfile" "./back"
    build_and_tag "frontend" "./frontend/Dockerfile" "./frontend"
    
    # Push images
    push_with_retry "${REGISTRY}/${PROJECT_NAME}-backend:${TAG}"
    push_with_retry "${REGISTRY}/${PROJECT_NAME}-backend:latest"
    push_with_retry "${REGISTRY}/${PROJECT_NAME}-frontend:${TAG}"
    push_with_retry "${REGISTRY}/${PROJECT_NAME}-frontend:latest"
    
    # Cleanup
    cleanup_images
    
    success "Build and push process completed!"
    
    # Show image sizes
    log "Image sizes:"
    docker images ${REGISTRY}/${PROJECT_NAME}-* --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"
}

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Run main function
main "$@" 