#!/bin/bash

# Dendreo Service Setup Script
# This script sets up the Dendreo application as a systemd service

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_NAME="dendreo"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
SERVICE_MANAGER="$SCRIPT_DIR/dendreo-service-manager.sh"
DEPLOY_SCRIPT="$SCRIPT_DIR/deploy.sh"
LOG_FILE="/var/log/dendreo-service.log"

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

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root or with sudo"
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check if Docker Compose is available
    if ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not available. Please install Docker Compose."
        exit 1
    fi
    
    # Check if required files exist
    if [ ! -f "$SERVICE_MANAGER" ]; then
        log_error "Service manager script not found: $SERVICE_MANAGER"
        exit 1
    fi
    
    if [ ! -f "$DEPLOY_SCRIPT" ]; then
        log_error "Deploy script not found: $DEPLOY_SCRIPT"
        exit 1
    fi
    
    if [ ! -f "$SCRIPT_DIR/dendreo.service" ]; then
        log_error "Service file not found: $SCRIPT_DIR/dendreo.service"
        exit 1
    fi
    
    if [ ! -f "$SCRIPT_DIR/docker-compose.prod.yml" ]; then
        log_error "Production Docker Compose file not found: $SCRIPT_DIR/docker-compose.prod.yml"
        exit 1
    fi
    
    if [ ! -f "$SCRIPT_DIR/.env.prod" ]; then
        log_warning "Production environment file not found: $SCRIPT_DIR/.env.prod"
        log_info "Please create .env.prod file with your configuration"
    fi
    
    log_success "Prerequisites check completed"
}

# Make scripts executable
make_executable() {
    log_info "Making scripts executable..."
    
    chmod +x "$SERVICE_MANAGER"
    chmod +x "$DEPLOY_SCRIPT"
    
    log_success "Scripts made executable"
}

# Install systemd service
install_service() {
    log_info "Installing systemd service..."
    
    # Stop existing service if running
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        log_info "Stopping existing service..."
        systemctl stop "$SERVICE_NAME"
    fi
    
    # Copy service file
    cp "$SCRIPT_DIR/dendreo.service" "$SERVICE_FILE"
    
    # Create log file with proper permissions
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
    
    # Reload systemd
    systemctl daemon-reload
    
    # Enable service
    systemctl enable "$SERVICE_NAME"
    
    log_success "Service installed and enabled"
}

# Test service installation
test_service() {
    log_info "Testing service installation..."
    
    # Check service file syntax
    if ! systemctl cat "$SERVICE_NAME" &> /dev/null; then
        log_error "Service file has syntax errors"
        return 1
    fi
    
    # Check if service is properly loaded
    if ! systemctl is-enabled "$SERVICE_NAME" &> /dev/null; then
        log_error "Service is not enabled"
        return 1
    fi
    
    # Check if service manager script is executable
    if [ ! -x "$SERVICE_MANAGER" ]; then
        log_error "Service manager script is not executable"
        return 1
    fi
    
    log_success "Service installation test passed"
}

# Show usage instructions
show_usage() {
    cat << EOF

${GREEN}Dendreo Service Setup Complete!${NC}

The Dendreo service has been successfully installed and configured.

${YELLOW}Service Management Commands:${NC}
  sudo systemctl start dendreo     - Start the service
  sudo systemctl stop dendreo      - Stop the service
  sudo systemctl restart dendreo   - Restart the service
  sudo systemctl status dendreo    - Check service status
  sudo systemctl enable dendreo    - Enable auto-start on boot
  sudo systemctl disable dendreo   - Disable auto-start on boot

${YELLOW}Manual Service Management:${NC}
  sudo $SERVICE_MANAGER start      - Start the service manually
  sudo $SERVICE_MANAGER stop       - Stop the service manually
  sudo $SERVICE_MANAGER restart    - Restart the service manually
  sudo $SERVICE_MANAGER status     - Check service status
  sudo $SERVICE_MANAGER health     - Perform health check
  sudo $SERVICE_MANAGER logs       - Show service logs

${YELLOW}Log Files:${NC}
  Service logs: $LOG_FILE
  Container logs: sudo $SERVICE_MANAGER logs
  System logs: sudo journalctl -u dendreo -f

${YELLOW}Configuration Files:${NC}
  Service file: $SERVICE_FILE
  Environment: $SCRIPT_DIR/.env.prod
  Docker Compose: $SCRIPT_DIR/docker-compose.prod.yml

${YELLOW}Next Steps:${NC}
1. Ensure your .env.prod file is properly configured
2. Test the service: sudo systemctl start dendreo
3. Check status: sudo systemctl status dendreo
4. View logs: sudo journalctl -u dendreo -f

${GREEN}Service is ready to use!${NC}

EOF
}

# Uninstall service
uninstall_service() {
    log_info "Uninstalling Dendreo service..."
    
    # Stop service if running
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        log_info "Stopping service..."
        systemctl stop "$SERVICE_NAME"
    fi
    
    # Disable service
    if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        log_info "Disabling service..."
        systemctl disable "$SERVICE_NAME"
    fi
    
    # Remove service file
    if [ -f "$SERVICE_FILE" ]; then
        rm -f "$SERVICE_FILE"
        log_success "Service file removed"
    fi
    
    # Reload systemd
    systemctl daemon-reload
    
    log_success "Service uninstalled successfully"
}

# Main script
main() {
    case "${1:-install}" in
        "install")
            log_info "Installing Dendreo systemd service..."
            check_root
            check_prerequisites
            make_executable
            install_service
            test_service
            show_usage
            ;;
        "uninstall")
            log_info "Uninstalling Dendreo systemd service..."
            check_root
            uninstall_service
            ;;
        "test")
            log_info "Testing Dendreo service..."
            check_root
            test_service
            ;;
        "help"|"--help")
            cat << EOF
Dendreo Service Setup Script

Usage: $0 [COMMAND]

Commands:
  install     - Install and configure the systemd service (default)
  uninstall   - Remove the systemd service
  test        - Test the service installation
  help        - Show this help message

Examples:
  sudo $0 install           # Install the service
  sudo $0 uninstall         # Remove the service
  sudo $0 test              # Test the installation

EOF
            ;;
        *)
            log_error "Unknown command: $1"
            log_info "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 