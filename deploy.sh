#!/bin/bash

# Dendreo Progression Docker Deployment Script
# This script helps deploy the application using Docker Compose for dev and prod environments

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Default environment
ENVIRONMENT="dev"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_env() {
    if [[ $ENVIRONMENT == "prod" ]]; then
        echo -e "${PURPLE}[PRODUCTION]${NC} $1"
    else
        echo -e "${YELLOW}[DEVELOPMENT]${NC} $1"
    fi
}

# Function to parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --env|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            --prod|--production)
                ENVIRONMENT="prod"
                shift
                ;;
            --dev|--development)
                ENVIRONMENT="dev"
                shift
                ;;
            *)
                COMMAND="$1"
                shift
                ;;
        esac
    done

    # Validate environment
    if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
        print_error "Invalid environment: $ENVIRONMENT. Use 'dev' or 'prod'"
        exit 1
    fi
}

# Function to set environment-specific variables
setup_environment() {
    print_env "Setting up $ENVIRONMENT environment"
    
    if [[ $ENVIRONMENT == "prod" ]]; then
        COMPOSE_FILES="-f docker-compose.yml -f docker-compose.prod.yml"
        ENV_FILE="env.prod.example"
        ENV_TARGET=".env.prod"
        NETWORK_NAME="dendreo_prod_network"
        DB_PORT="5432"
        FRONTEND_PORT="80"  # nginx in production
        BACKEND_PORT="8000"
    else
        COMPOSE_FILES="-f docker-compose.yml -f docker-compose.dev.yml"
        ENV_FILE="env.dev.example"
        ENV_TARGET=".env.dev"
        NETWORK_NAME="dendreo_dev_network"
        DB_PORT="5433"
        FRONTEND_PORT="3000"
        BACKEND_PORT="8000"
    fi

    DOCKER_COMPOSE="docker-compose $COMPOSE_FILES"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Function to check if docker-compose is available
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        if ! docker compose version &> /dev/null; then
            print_error "Neither docker-compose nor 'docker compose' is available. Please install Docker Compose."
            exit 1
        else
            DOCKER_COMPOSE="docker compose $COMPOSE_FILES"
        fi
    else
        DOCKER_COMPOSE="docker-compose $COMPOSE_FILES"
    fi
    print_success "Docker Compose is available"
}

# Function to setup environment file
setup_env() {
    if [[ ! -f $ENV_TARGET ]]; then
        if [[ -f $ENV_FILE ]]; then
            print_warning "$ENV_TARGET file not found. Creating from $ENV_FILE..."
            cp $ENV_FILE $ENV_TARGET
            print_warning "Please edit $ENV_TARGET file with your actual configuration before continuing."
            
            if [[ $ENVIRONMENT == "prod" ]]; then
                print_warning "IMPORTANT: Update GitHub repository URL in $ENV_TARGET"
                print_warning "IMPORTANT: Use secure passwords and API keys for production"
            fi
            
            read -p "Press Enter after you've updated the $ENV_TARGET file..."
        else
            print_error "$ENV_TARGET file not found and no example file available."
            exit 1
        fi
    else
        print_success "$ENV_TARGET file found"
    fi
    
    # Export environment variables
    export $(grep -v '^#' $ENV_TARGET | xargs)
}

# Function to create necessary directories
create_directories() {
    print_status "Creating necessary directories for $ENVIRONMENT..."
    mkdir -p database/init
    mkdir -p database/dev-data
    mkdir -p nginx/ssl
    
    if [[ $ENVIRONMENT == "dev" ]]; then
        mkdir -p dev-logs
    fi
    
    print_success "Directories created"
}

# Function to validate GitHub repository URL
validate_github_repo() {
    if [[ $ENVIRONMENT == "dev" || $ENVIRONMENT == "prod" ]]; then
        print_status "Validating GitHub repository access..."
        
        # Check if the repository URL contains placeholder
        if grep -q "YOUR_USERNAME" $ENV_TARGET; then
            print_error "Please update the GitHub repository URL in $ENV_TARGET"
            print_error "Replace YOUR_USERNAME with your actual GitHub username"
            exit 1
        fi
        
        print_success "GitHub repository configuration validated"
    fi
}

# Function to build and start containers
deploy() {
    print_env "Building and starting containers for $ENVIRONMENT environment..."
    
    # Pull latest base images
    print_status "Pulling latest base images..."
    $DOCKER_COMPOSE pull postgres nginx 2>/dev/null || true
    
    # Build custom images
    print_status "Building custom images from GitHub repositories..."
    $DOCKER_COMPOSE build --no-cache
    
    # Start containers
    print_status "Starting containers..."
    $DOCKER_COMPOSE up -d
    
    # Wait for services to be healthy
    print_status "Waiting for services to be healthy..."
    
    # Wait for PostgreSQL
    print_status "Waiting for PostgreSQL to be ready..."
    timeout=60
    while ! $DOCKER_COMPOSE exec postgres pg_isready -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-dendreo_db} > /dev/null 2>&1; do
        if [[ $timeout -le 0 ]]; then
            print_error "PostgreSQL failed to start within timeout"
            $DOCKER_COMPOSE logs postgres
            exit 1
        fi
        print_status "PostgreSQL not ready yet, waiting..."
        sleep 2
        ((timeout-=2))
    done
    print_success "PostgreSQL is ready"
    
    # Wait for backend
    print_status "Waiting for backend to be ready..."
    timeout=60
    while ! curl -f http://localhost:$BACKEND_PORT/health > /dev/null 2>&1; do
        if [[ $timeout -le 0 ]]; then
            print_error "Backend failed to start within timeout"
            $DOCKER_COMPOSE logs backend
            exit 1
        fi
        print_status "Backend not ready yet, waiting..."
        sleep 2
        ((timeout-=2))
    done
    print_success "Backend is ready"
    
    # Wait for frontend (different ports for dev/prod)
    print_status "Waiting for frontend to be ready..."
    timeout=60
    while ! curl -f http://localhost:$FRONTEND_PORT > /dev/null 2>&1; do
        if [[ $timeout -le 0 ]]; then
            print_error "Frontend failed to start within timeout"
            $DOCKER_COMPOSE logs frontend
            exit 1
        fi
        print_status "Frontend not ready yet, waiting..."
        sleep 2
        ((timeout-=2))
    done
    print_success "Frontend is ready"
}

# Function to show status
show_status() {
    print_env "Container status for $ENVIRONMENT environment:"
    $DOCKER_COMPOSE ps
    
    echo ""
    print_env "Service URLs for $ENVIRONMENT:"
    if [[ $ENVIRONMENT == "prod" ]]; then
        echo "  Frontend:  http://localhost (port 80)"
        echo "  Backend:   http://localhost/api"
        echo "  API Docs:  http://localhost/api/docs"
        echo "  Database:  Internal only (port 5432)"
    else
        echo "  Frontend:  http://localhost:$FRONTEND_PORT"
        echo "  Backend:   http://localhost:$BACKEND_PORT"
        echo "  API Docs:  http://localhost:$BACKEND_PORT/docs"
        echo "  Database:  localhost:$DB_PORT"
    fi
}

# Function to show logs
show_logs() {
    if [[ $1 ]]; then
        $DOCKER_COMPOSE logs -f $1
    else
        $DOCKER_COMPOSE logs -f
    fi
}

# Function to stop containers
stop() {
    print_env "Stopping $ENVIRONMENT containers..."
    $DOCKER_COMPOSE down
    print_success "Containers stopped"
}

# Function to clean up
cleanup() {
    print_warning "This will remove all $ENVIRONMENT containers, images, and volumes. Data will be lost!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleaning up $ENVIRONMENT environment..."
        $DOCKER_COMPOSE down -v --rmi all
        docker system prune -f
        print_success "Cleanup completed"
    else
        print_status "Cleanup cancelled"
    fi
}

# Function to backup database
backup_db() {
    print_env "Creating database backup for $ENVIRONMENT environment..."
    timestamp=$(date +%Y%m%d_%H%M%S)
    backup_file="backup_${ENVIRONMENT}_${timestamp}.sql"
    
    $DOCKER_COMPOSE exec postgres pg_dump -U ${POSTGRES_USER:-postgres} ${POSTGRES_DB:-dendreo_db} > $backup_file
    print_success "Database backup created: $backup_file"
}

# Function to restore database
restore_db() {
    if [[ ! $1 ]]; then
        print_error "Please provide backup file path"
        exit 1
    fi
    
    if [[ ! -f $1 ]]; then
        print_error "Backup file not found: $1"
        exit 1
    fi
    
    print_warning "This will overwrite the current $ENVIRONMENT database!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_env "Restoring $ENVIRONMENT database from $1..."
        $DOCKER_COMPOSE exec -T postgres psql -U ${POSTGRES_USER:-postgres} ${POSTGRES_DB:-dendreo_db} < $1
        print_success "Database restored"
    else
        print_status "Database restore cancelled"
    fi
}

# Function to switch environments
switch_env() {
    if [[ $1 ]]; then
        target_env=$1
    else
        if [[ $ENVIRONMENT == "dev" ]]; then
            target_env="prod"
        else
            target_env="dev"
        fi
    fi
    
    print_warning "Switching from $ENVIRONMENT to $target_env environment"
    
    # Stop current environment
    stop
    
    # Switch environment
    ENVIRONMENT=$target_env
    setup_environment
    
    # Start new environment
    deploy
    show_status
}

# Function to rebuild specific service
rebuild() {
    if [[ ! $1 ]]; then
        print_error "Please specify service to rebuild (backend, frontend, or postgres)"
        exit 1
    fi
    
    service=$1
    print_env "Rebuilding $service in $ENVIRONMENT environment..."
    
    $DOCKER_COMPOSE build --no-cache $service
    $DOCKER_COMPOSE up -d $service
    
    print_success "$service rebuilt and restarted"
}

# Usage function
show_usage() {
    echo "Dendreo Progression Docker Deployment"
    echo ""
    echo "Usage: $0 [--env dev|prod] {command} [options]"
    echo ""
    echo "Environment Options:"
    echo "  --env dev|prod    Specify environment (default: dev)"
    echo "  --dev             Use development environment"
    echo "  --prod            Use production environment"
    echo ""
    echo "Commands:"
    echo "  start/deploy      Build and start all containers"
    echo "  stop              Stop all containers"
    echo "  restart           Restart all containers"
    echo "  status            Show container status and service URLs"
    echo "  logs [service]    Show logs (all services or specific service)"
    echo "  backup            Create database backup"
    echo "  restore <file>    Restore database from backup"
    echo "  cleanup           Remove all containers, images, and volumes"
    echo "  switch [env]      Switch between dev and prod environments"
    echo "  rebuild <service> Rebuild specific service (backend, frontend, postgres)"
    echo ""
    echo "Examples:"
    echo "  $0 --dev start                    # Start development environment"
    echo "  $0 --prod start                   # Start production environment"
    echo "  $0 --env dev logs backend         # Show dev backend logs"
    echo "  $0 --prod backup                  # Backup production database"
    echo "  $0 switch                         # Switch between current and other env"
    echo "  $0 --dev rebuild backend          # Rebuild dev backend service"
}

# Main script logic
parse_args "$@"
setup_environment

case "$COMMAND" in
    "start"|"deploy")
        print_env "Starting Dendreo Progression deployment in $ENVIRONMENT environment..."
        check_docker
        check_docker_compose
        setup_env
        create_directories
        validate_github_repo
        deploy
        show_status
        print_success "Deployment completed successfully!"
        ;;
    "stop")
        check_docker
        check_docker_compose
        setup_env
        stop
        ;;
    "restart")
        check_docker
        check_docker_compose
        setup_env
        stop
        sleep 2
        deploy
        show_status
        ;;
    "status")
        check_docker
        check_docker_compose
        setup_env
        show_status
        ;;
    "logs")
        check_docker
        check_docker_compose
        setup_env
        show_logs $2
        ;;
    "backup")
        check_docker
        check_docker_compose
        setup_env
        backup_db
        ;;
    "restore")
        check_docker
        check_docker_compose
        setup_env
        restore_db $2
        ;;
    "cleanup")
        check_docker
        check_docker_compose
        setup_env
        cleanup
        ;;
    "switch")
        check_docker
        check_docker_compose
        switch_env $2
        ;;
    "rebuild")
        check_docker
        check_docker_compose
        setup_env
        rebuild $2
        ;;
    *)
        show_usage
        ;;
esac