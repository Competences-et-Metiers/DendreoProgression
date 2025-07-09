#!/bin/bash

# Dendreo Progression Multi-Environment Deployment Script
# Enhanced version with development and production support

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
DOCKER_COMPOSE_FILES="docker-compose.yml"

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

show_help() {
    cat << EOF
Dendreo Progression Multi-Environment Deployment Script

Usage: $0 [OPTIONS] COMMAND

COMMANDS:
    start       Start the application (default: development)
    stop        Stop the application
    restart     Restart the application
    rebuild     Rebuild and restart the application
    logs        Show application logs
    status      Show running containers status
    clean       Clean up containers and volumes
    backup      Backup database
    restore     Restore database from backup
    switch      Switch between environments
    init        Initialize environment

ENVIRONMENT OPTIONS:
    --dev       Use development environment (default)
    --prod      Use production environment

OTHER OPTIONS:
    --build     Force rebuild containers
    --pull      Pull latest images before starting
    --detach    Run in detached mode (background)
    --follow    Follow logs in real-time
    --help      Show this help message

EXAMPLES:
    $0 start                    # Start development environment
    $0 --prod start             # Start production environment
    $0 --dev restart --build    # Restart dev with rebuild
    $0 logs --follow            # Follow logs in real-time
    $0 backup my-backup         # Create database backup
    $0 clean                    # Clean up everything

ENVIRONMENT VARIABLES:
    Set these in .env.dev (development) or .env.prod (production)
    - POSTGRES_PASSWORD
    - DENDREO_API_KEY
    - HUBSPOT_API_KEY
EOF
}

detect_environment() {
    local env_arg=""
    local compose_files="$DOCKER_COMPOSE_FILES"
    
    # Check for environment flags
    for arg in "$@"; do
        case $arg in
            --dev)
                env_arg="dev"
                compose_files="$DOCKER_COMPOSE_FILES -f docker-compose.dev.yml"
                ;;
            --prod)
                env_arg="prod"
                compose_files="$DOCKER_COMPOSE_FILES -f docker-compose.prod.yml"
                ;;
        esac
    done
    
    # Use default if no environment specified
    if [ -z "$env_arg" ]; then
        env_arg="$DEFAULT_ENV"
        compose_files="$DOCKER_COMPOSE_FILES -f docker-compose.dev.yml"
    fi
    
    echo "$env_arg|$compose_files"
}

check_prerequisites() {
    local env=$1
    
    log_info "Checking prerequisites for $env environment..."
    
    # Check Docker and Docker Compose
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    if ! docker compose version >/dev/null 2>&1; then
        log_error "Docker Compose is not available"
        exit 1
    fi
    
    # Check environment file
    local env_file=".env.$env"
    if [ "$env" = "dev" ]; then
        env_file=".env.dev"
    elif [ "$env" = "prod" ]; then
        env_file=".env.prod"
    fi
    
    if [ ! -f "$env_file" ]; then
        log_warning "Environment file $env_file not found"
        log_info "Please copy ${env_file}.example to $env_file and configure it"
        
        if [ -f "${env_file}.example" ]; then
            log_info "Example file found. Copy it with: cp ${env_file}.example $env_file"
        fi
    fi
    
    log_success "Prerequisites check completed"
}

start_application() {
    local env=$1
    local compose_files=$2
    local build_flag=""
    local pull_flag=""
    local detach_flag="-d"
    
    # Parse additional flags
    for arg in "${@:3}"; do
        case $arg in
            --build)
                build_flag="--build"
                ;;
            --pull)
                pull_flag="--pull always"
                ;;
            --no-detach)
                detach_flag=""
                ;;
        esac
    done
    
    log_info "Starting $env environment..."
    
    # Set environment file
    local env_file=".env.$env"
    export COMPOSE_FILE="$compose_files"
    
    if [ -f "$env_file" ]; then
        export $(cat "$env_file" | grep -v '^#' | xargs)
        log_success "Loaded environment variables from $env_file"
    fi
    
    # Start services
    docker compose $compose_files up $detach_flag $build_flag $pull_flag
    
    if [ -n "$detach_flag" ]; then
        log_success "$env environment started successfully!"
        log_info "Access the application at:"
        if [ "$env" = "dev" ]; then
            log_info "  Frontend: http://localhost:3000"
            log_info "  Backend API: http://localhost:8000"
            log_info "  Database: localhost:5433"
        else
            log_info "  Application: http://localhost"
            log_info "  Database: localhost:5432"
        fi
    fi
}

stop_application() {
    local compose_files=$1
    
    log_info "Stopping application..."
    docker compose $compose_files down
    log_success "Application stopped"
}

restart_application() {
    local env=$1
    local compose_files=$2
    shift 2
    
    log_info "Restarting $env environment..."
    stop_application "$compose_files"
    start_application "$env" "$compose_files" "$@"
}

rebuild_application() {
    local env=$1
    local compose_files=$2
    
    log_info "Rebuilding $env environment..."
    docker compose $compose_files down
    docker compose $compose_files build --no-cache
    start_application "$env" "$compose_files" --no-detach
}

show_logs() {
    local compose_files=$1
    local follow_flag=""
    
    # Check for follow flag
    for arg in "${@:2}"; do
        case $arg in
            --follow)
                follow_flag="-f"
                ;;
        esac
    done
    
    log_info "Showing application logs..."
    docker compose $compose_files logs $follow_flag
}

show_status() {
    local compose_files=$1
    
    log_info "Application status:"
    docker compose $compose_files ps -a
    
    log_info "Resource usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
}

backup_database() {
    local env=$1
    local backup_name=${2:-"backup-$(date +%Y%m%d-%H%M%S)"}
    local compose_files=$3
    
    log_info "Creating database backup: $backup_name"
    
    # Create backups directory
    mkdir -p ./backups
    
    # Get database connection details based on environment
    local db_container="dendreo_postgres"
    local db_name="dendreo_db"
    if [ "$env" = "dev" ]; then
        db_name="dendreo_dev_db"
    elif [ "$env" = "prod" ]; then
        db_name="dendreo_prod_db"
    fi
    
    # Create backup
    docker compose $compose_files exec postgres pg_dump -U postgres -d $db_name | gzip > "./backups/${backup_name}.sql.gz"
    
    log_success "Database backup created: ./backups/${backup_name}.sql.gz"
}

restore_database() {
    local env=$1
    local backup_file=$2
    local compose_files=$3
    
    if [ -z "$backup_file" ]; then
        log_error "Please specify backup file to restore"
        exit 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        log_error "Backup file not found: $backup_file"
        exit 1
    fi
    
    log_warning "This will overwrite the current database!"
    read -p "Are you sure you want to continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Database restore cancelled"
        exit 0
    fi
    
    log_info "Restoring database from: $backup_file"
    
    # Get database connection details
    local db_name="dendreo_db"
    if [ "$env" = "dev" ]; then
        db_name="dendreo_dev_db"
    elif [ "$env" = "prod" ]; then
        db_name="dendreo_prod_db"
    fi
    
    # Restore database
    if [[ "$backup_file" == *.gz ]]; then
        zcat "$backup_file" | docker compose $compose_files exec -T postgres psql -U postgres -d $db_name
    else
        cat "$backup_file" | docker compose $compose_files exec -T postgres psql -U postgres -d $db_name
    fi
    
    log_success "Database restored successfully"
}

clean_application() {
    local compose_files=$1
    
    log_warning "This will remove all containers, volumes, and data!"
    read -p "Are you sure you want to continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cleanup cancelled"
        exit 0
    fi
    
    log_info "Cleaning up application..."
    
    # Stop and remove containers
    docker compose $compose_files down -v --remove-orphans
    
    # Remove project-specific volumes
    docker volume ls -q | grep "${PROJECT_NAME}" | xargs -r docker volume rm
    
    # Prune unused Docker resources
    docker system prune -f
    
    log_success "Application cleaned up"
}

switch_environment() {
    local target_env=$1
    
    if [ -z "$target_env" ]; then
        log_error "Please specify target environment (dev/prod)"
        exit 1
    fi
    
    log_info "Switching to $target_env environment..."
    
    # Stop current environment
    docker compose down 2>/dev/null || true
    
    # Start target environment
    if [ "$target_env" = "dev" ]; then
        start_application "dev" "$DOCKER_COMPOSE_FILES -f docker-compose.dev.yml"
    elif [ "$target_env" = "prod" ]; then
        start_application "prod" "$DOCKER_COMPOSE_FILES -f docker-compose.prod.yml"
    else
        log_error "Invalid environment: $target_env (use dev or prod)"
        exit 1
    fi
}

init_environment() {
    local env=$1
    
    log_info "Initializing $env environment..."
    
    # Create environment file if it doesn't exist
    local env_file=".env.$env"
    local example_file="${env_file}.example"
    
    if [ ! -f "$env_file" ] && [ -f "$example_file" ]; then
        cp "$example_file" "$env_file"
        log_success "Created $env_file from template"
        log_info "Please edit $env_file to configure your environment"
    fi
    
    # Create necessary directories
    mkdir -p backups logs dev-logs nginx/ssl database/dev-data
    
    log_success "Environment initialized"
}

# Main script logic
main() {
    # Parse environment and get compose files
    local env_info=$(detect_environment "$@")
    local env=$(echo "$env_info" | cut -d'|' -f1)
    local compose_files=$(echo "$env_info" | cut -d'|' -f2)
    
    # Remove environment flags from arguments
    local args=()
    for arg in "$@"; do
        case $arg in
            --dev|--prod) ;;
            *) args+=("$arg") ;;
        esac
    done
    
    # Get command
    local command=${args[0]:-"help"}
    
    case $command in
        start)
            check_prerequisites "$env"
            start_application "$env" "$compose_files" "${args[@]:1}"
            ;;
        stop)
            stop_application "$compose_files"
            ;;
        restart)
            check_prerequisites "$env"
            restart_application "$env" "$compose_files" "${args[@]:1}"
            ;;
        rebuild)
            check_prerequisites "$env"
            rebuild_application "$env" "$compose_files"
            ;;
        logs)
            show_logs "$compose_files" "${args[@]:1}"
            ;;
        status)
            show_status "$compose_files"
            ;;
        clean)
            clean_application "$compose_files"
            ;;
        backup)
            backup_database "$env" "${args[1]}" "$compose_files"
            ;;
        restore)
            restore_database "$env" "${args[1]}" "$compose_files"
            ;;
        switch)
            switch_environment "${args[1]}"
            ;;
        init)
            init_environment "$env"
            ;;
        help|--help)
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"