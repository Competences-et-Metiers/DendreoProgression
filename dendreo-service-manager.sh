#!/bin/bash

# Dendreo Production Service Manager
# This script manages the Dendreo application as a systemd service

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SCRIPT="$SCRIPT_DIR/deploy-prod.sh"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.prod.yml"
ENV_FILE="$SCRIPT_DIR/.env.prod"
LOCK_FILE="/tmp/dendreo-service.lock"
LOG_FILE="/var/log/dendreo-service.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local color=""
    
    case "$level" in
        "INFO") color="$BLUE" ;;
        "SUCCESS") color="$GREEN" ;;
        "WARNING") color="$YELLOW" ;;
        "ERROR") color="$RED" ;;
    esac
    
    echo -e "${color}[$timestamp] [$level]${NC} $message" | tee -a "$LOG_FILE"
}

# Check if running as root or with sudo
check_permissions() {
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "This script must be run as root or with sudo"
        exit 1
    fi
}

# Check if Docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        log "ERROR" "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker compose version &> /dev/null; then
        log "ERROR" "Docker Compose is not available"
        exit 1
    fi
}

# Check if required files exist
check_files() {
    if [ ! -f "$DEPLOY_SCRIPT" ]; then
        log "ERROR" "Deploy script not found: $DEPLOY_SCRIPT"
        exit 1
    fi
    
    if [ ! -f "$COMPOSE_FILE" ]; then
        log "ERROR" "Docker Compose file not found: $COMPOSE_FILE"
        exit 1
    fi
    
    if [ ! -f "$ENV_FILE" ]; then
        log "ERROR" "Environment file not found: $ENV_FILE"
        exit 1
    fi
}

# Create lock file
create_lock() {
    if [ -f "$LOCK_FILE" ]; then
        log "ERROR" "Service is already running (lock file exists: $LOCK_FILE)"
        exit 1
    fi
    echo $$ > "$LOCK_FILE"
}

# Remove lock file
remove_lock() {
    rm -f "$LOCK_FILE"
}

# Trap to clean up on exit
trap remove_lock EXIT

# Start the service
start_service() {
    log "INFO" "Starting Dendreo production service..."
    
    check_permissions
    check_docker
    check_files
    create_lock
    
    # Change to script directory
    cd "$SCRIPT_DIR"
    
    # Run the deployment script
    log "INFO" "Running deployment script..."
    if bash "$DEPLOY_SCRIPT" >> "$LOG_FILE" 2>&1; then
        log "SUCCESS" "Dendreo service started successfully"
        return 0
    else
        log "ERROR" "Failed to start Dendreo service"
        return 1
    fi
}

# Stop the service
stop_service() {
    log "INFO" "Stopping Dendreo production service..."
    
    check_permissions
    check_docker
    
    # Change to script directory
    cd "$SCRIPT_DIR"
    
    # Stop Docker Compose services
    log "INFO" "Stopping Docker containers..."
    if docker compose -f "$COMPOSE_FILE" down --remove-orphans >> "$LOG_FILE" 2>&1; then
        log "SUCCESS" "Dendreo service stopped successfully"
        return 0
    else
        log "ERROR" "Failed to stop Dendreo service"
        return 1
    fi
}

# Restart the service
restart_service() {
    log "INFO" "Restarting Dendreo production service..."
    
    stop_service
    sleep 5
    start_service
}

# Check service status
check_status() {
    log "INFO" "Checking Dendreo service status..."
    
    check_docker
    
    # Change to script directory
    cd "$SCRIPT_DIR"
    
    # Check if containers are running
    if docker compose -f "$COMPOSE_FILE" ps --services --filter "status=running" | grep -q "."; then
        log "SUCCESS" "Dendreo service is running"
        echo
        echo "Running containers:"
        docker compose -f "$COMPOSE_FILE" ps
        return 0
    else
        log "WARNING" "Dendreo service is not running"
        echo
        echo "Container status:"
        docker compose -f "$COMPOSE_FILE" ps
        return 1
    fi
}

# Show service logs
show_logs() {
    local service="$1"
    local follow="$2"
    
    log "INFO" "Showing logs for Dendreo service..."
    
    check_docker
    
    # Change to script directory
    cd "$SCRIPT_DIR"
    
    if [ "$follow" = "follow" ]; then
        if [ -n "$service" ]; then
            docker compose -f "$COMPOSE_FILE" logs -f "$service"
        else
            docker compose -f "$COMPOSE_FILE" logs -f
        fi
    else
        if [ -n "$service" ]; then
            docker compose -f "$COMPOSE_FILE" logs "$service"
        else
            docker compose -f "$COMPOSE_FILE" logs
        fi
    fi
}

# Main function
main() {
    # Create log file if it doesn't exist
    touch "$LOG_FILE"
    
    case "$1" in
        "start")
            start_service
            ;;
        "stop")
            stop_service
            ;;
        "restart")
            restart_service
            ;;
        "status")
            check_status
            ;;
        "logs")
            show_logs "$2" "$3"
            ;;
        *)
            echo "Usage: $0 {start|stop|restart|status|logs [service] [follow]}"
            echo ""
            echo "Commands:"
            echo "  start     - Start the Dendreo service"
            echo "  stop      - Stop the Dendreo service"
            echo "  restart   - Restart the Dendreo service"
            echo "  status    - Check service status"
            echo "  logs      - Show service logs"
            echo ""
            echo "Examples:"
            echo "  $0 start"
            echo "  $0 status"
            echo "  $0 logs backend"
            echo "  $0 logs nginx follow"
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 