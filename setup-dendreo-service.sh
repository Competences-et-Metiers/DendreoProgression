#!/bin/bash

# Setup script for Dendreo Production Service
# This script installs and configures the Dendreo service on Debian/Ubuntu

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
SERVICE_MANAGER_SCRIPT="$SCRIPT_DIR/dendreo-service-manager.sh"
DEPLOY_SCRIPT="$SCRIPT_DIR/deploy-prod.sh"
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

# Check if required files exist
check_files() {
    log_info "Checking required files..."
    
    local missing_files=()
    
    if [ ! -f "$SERVICE_MANAGER_SCRIPT" ]; then
        missing_files+=("dendreo-service-manager.sh")
    fi
    
    if [ ! -f "$DEPLOY_SCRIPT" ]; then
        missing_files+=("deploy-prod.sh")
    fi
    
    if [ ! -f "$SCRIPT_DIR/dendreo.service" ]; then
        missing_files+=("dendreo.service")
    fi
    
    if [ ! -f "$SCRIPT_DIR/docker-compose.prod.yml" ]; then
        missing_files+=("docker-compose.prod.yml")
    fi
    
    if [ ${#missing_files[@]} -ne 0 ]; then
        log_error "Missing required files:"
        printf '  - %s\n' "${missing_files[@]}"
        exit 1
    fi
    
    log_success "All required files found"
}

# Install the service
install_service() {
    log_info "Installing Dendreo systemd service..."
    
    # Stop existing service if it exists
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log_info "Stopping existing service..."
        systemctl stop "$SERVICE_NAME"
    fi
    
    # Disable existing service if it exists
    if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        log_info "Disabling existing service..."
        systemctl disable "$SERVICE_NAME"
    fi
    
    # Copy service file
    log_info "Installing service file..."
    cp "$SCRIPT_DIR/dendreo.service" "$SERVICE_FILE"
    
    # Make service manager script executable
    chmod +x "$SERVICE_MANAGER_SCRIPT"
    chmod +x "$DEPLOY_SCRIPT"
    
    # Create log file
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
    
    # Reload systemd
    systemctl daemon-reload
    
    log_success "Service installed successfully"
}

# Enable and start the service
enable_service() {
    log_info "Enabling and starting Dendreo service..."
    
    # Enable service
    systemctl enable "$SERVICE_NAME"
    
    # Start service
    if systemctl start "$SERVICE_NAME"; then
        log_success "Service started successfully"
    else
        log_error "Failed to start service"
        log_info "Check logs with: journalctl -xeu $SERVICE_NAME"
        exit 1
    fi
}

# Show service status
show_status() {
    log_info "Service Status:"
    echo "=============="
    systemctl status "$SERVICE_NAME" --no-pager
    echo
    
    log_info "Available Commands:"
    echo "=================="
    echo "  sudo systemctl start $SERVICE_NAME     # Start the service"
    echo "  sudo systemctl stop $SERVICE_NAME      # Stop the service"
    echo "  sudo systemctl restart $SERVICE_NAME   # Restart the service"
    echo "  sudo systemctl status $SERVICE_NAME    # Check service status"
    echo "  sudo systemctl enable $SERVICE_NAME    # Enable auto-start on boot"
    echo "  sudo systemctl disable $SERVICE_NAME   # Disable auto-start on boot"
    echo
    echo "  sudo journalctl -u $SERVICE_NAME -f    # Follow service logs"
    echo "  sudo journalctl -u $SERVICE_NAME       # View service logs"
    echo
    echo "  $SERVICE_MANAGER_SCRIPT status         # Check container status"
    echo "  $SERVICE_MANAGER_SCRIPT logs           # View container logs"
    echo "  $SERVICE_MANAGER_SCRIPT logs nginx     # View specific service logs"
}

# Uninstall service
uninstall_service() {
    log_info "Uninstalling Dendreo service..."
    
    # Stop service
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        systemctl stop "$SERVICE_NAME"
    fi
    
    # Disable service
    if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        systemctl disable "$SERVICE_NAME"
    fi
    
    # Remove service file
    if [ -f "$SERVICE_FILE" ]; then
        rm "$SERVICE_FILE"
    fi
    
    # Reload systemd
    systemctl daemon-reload
    
    log_success "Service uninstalled successfully"
}

# Main function
main() {
    case "$1" in
        "install")
            echo "🚀 Dendreo Service Installation"
            echo "==============================="
            echo
            
            check_root
            check_files
            install_service
            enable_service
            show_status
            ;;
        "uninstall")
            echo "🗑️  Dendreo Service Uninstallation"
            echo "==================================="
            echo
            
            check_root
            uninstall_service
            ;;
        "status")
            show_status
            ;;
        *)
            echo "Usage: $0 {install|uninstall|status}"
            echo ""
            echo "Commands:"
            echo "  install     - Install and start the Dendreo service"
            echo "  uninstall   - Stop and remove the Dendreo service"
            echo "  status      - Show service status and available commands"
            echo ""
            echo "Examples:"
            echo "  sudo $0 install"
            echo "  sudo $0 uninstall"
            echo "  $0 status"
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 