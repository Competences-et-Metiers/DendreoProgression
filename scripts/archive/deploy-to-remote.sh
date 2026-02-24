#!/bin/bash

# SCP Deployment Script for Dendreo Progression
# Copies project files to remote server: cm@192.168.254.82:/home/cm/DendreoProgression

set -e

# Configuration
REMOTE_USER="cm"
REMOTE_HOST="192.168.254.82"
REMOTE_PATH="/home/cm/DendreoProgression"
LOCAL_PATH="."

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

# Check if SSH key is available
check_ssh_connection() {
    log_info "Testing SSH connection to ${REMOTE_USER}@${REMOTE_HOST}..."
    
    if ssh -o ConnectTimeout=10 -o BatchMode=yes ${REMOTE_USER}@${REMOTE_HOST} exit 2>/dev/null; then
        log_success "SSH connection successful"
        return 0
    else
        log_error "SSH connection failed. Please ensure:"
        echo "  1. SSH key is set up for ${REMOTE_USER}@${REMOTE_HOST}"
        echo "  2. SSH key is added to ssh-agent: ssh-add ~/.ssh/id_rsa"
        echo "  3. Remote server is accessible"
        return 1
    fi
}

# Create backup of remote directory
create_backup() {
    log_info "Creating backup of remote directory..."
    
    ssh ${REMOTE_USER}@${REMOTE_HOST} << 'EOF'
        if [ -d "/home/cm/DendreoProgression" ]; then
            BACKUP_DIR="/home/cm/DendreoProgression.backup.$(date +%Y%m%d_%H%M%S)"
            echo "Creating backup: $BACKUP_DIR"
            cp -r /home/cm/DendreoProgression "$BACKUP_DIR"
            echo "Backup created: $BACKUP_DIR"
        else
            echo "No existing directory to backup"
        fi
EOF
    
    log_success "Backup completed"
}

# Copy project files to remote server
copy_files() {
    log_info "Copying project files to remote server..."
    
    # Files and directories to copy
    FILES_TO_COPY=(
        "frontend/"
        "back/"
        "database/"
        "nginx/"
        "docker-compose.dev.yml"
        "docker-compose.prod.yml"
        "deploy-language-feature.sh"
        "deploy-to-remote.sh"
        "README.md"
        "DEPLOYMENT_MULTI_ENV.md"
        "PRODUCTION_DEPLOYMENT.md"
        "DOCKER_DEPLOYMENT.md"
        "SYSTEMD_SERVICE_SETUP.md"
        "CONTAINER_SYNC_DEPLOYMENT.md"
        "DEPLOY_TO_REMOTE.md"
        "Note.md"
        "TODO.md"
        "Tables.md"
    )
    
    # Create remote directory if it doesn't exist
    ssh ${REMOTE_USER}@${REMOTE_HOST} "mkdir -p ${REMOTE_PATH}"
    
    # Copy each file/directory
    for item in "${FILES_TO_COPY[@]}"; do
        if [ -e "$item" ]; then
            log_info "Copying $item..."
            scp -r "$item" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/"
            log_success "Copied $item"
        else
            log_warning "File/directory $item not found, skipping..."
        fi
    done
    
    log_success "All files copied successfully"
}

# Set permissions on remote server
set_permissions() {
    log_info "Setting permissions on remote server..."
    
    ssh ${REMOTE_USER}@${REMOTE_HOST} << 'EOF'
        cd /home/cm/DendreoProgression
        
        # Make scripts executable
        chmod +x deploy-language-feature.sh
        chmod +x deploy-to-remote.sh
        chmod +x frontend/test-build.sh
        
        # Set permissions for Docker files
        chmod 644 docker-compose.dev.yml
        chmod 644 docker-compose.prod.yml
        
        # Set permissions for nginx config
        chmod 644 nginx/prod.conf
        chmod 644 nginx/prod.http-only.conf
        
        echo "Permissions set successfully"
EOF
    
    log_success "Permissions set"
}

# Test the deployment
test_deployment() {
    log_info "Testing deployment on remote server..."
    
    ssh ${REMOTE_USER}@${REMOTE_HOST} << 'EOF'
        cd /home/cm/DendreoProgression
        
        echo "=== Testing Frontend Build ==="
        if [ -d "frontend" ]; then
            cd frontend
            echo "Testing frontend build with i18n..."
            if [ -f "test-build.sh" ]; then
                chmod +x test-build.sh
                ./test-build.sh
            else
                echo "test-build.sh not found, testing manual build..."
                npm install --legacy-peer-deps
                npm run build
            fi
            cd ..
        else
            echo "Frontend directory not found"
        fi
        
        echo "=== Checking Docker Compose ==="
        if command -v docker-compose &> /dev/null; then
            echo "Docker Compose is available"
        elif docker compose version &> /dev/null; then
            echo "Docker Compose (new version) is available"
        else
            echo "Docker Compose not found"
        fi
        
        echo "=== Checking Docker ==="
        if command -v docker &> /dev/null; then
            echo "Docker is available"
            docker --version
        else
            echo "Docker not found"
        fi
        
        echo "=== Checking Disk Space ==="
        df -h /home/cm
        
        echo "=== Deployment Test Complete ==="
EOF
    
    log_success "Deployment test completed"
}

# Show deployment instructions
show_instructions() {
    log_info "Deployment Instructions:"
    echo ""
    echo "📁 Files copied to: ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}"
    echo ""
    echo "🚀 To deploy the application:"
    echo "   1. SSH to the server: ssh ${REMOTE_USER}@${REMOTE_HOST}"
    echo "   2. Navigate to project: cd ${REMOTE_PATH}"
    echo "   3. Run deployment: ./deploy-language-feature.sh"
    echo ""
    echo "🔧 Alternative manual deployment:"
    echo "   1. SSH to server: ssh ${REMOTE_USER}@${REMOTE_HOST}"
    echo "   2. cd ${REMOTE_PATH}"
    echo "   3. docker-compose up --build -d"
    echo ""
    echo "📊 Check status:"
    echo "   - docker-compose ps"
    echo "   - docker-compose logs -f"
    echo ""
    echo "🌐 Access the application:"
    echo "   - Frontend: http://192.168.254.82:3000"
    echo "   - Backend API: http://192.168.254.82:8000"
    echo ""
    echo "🔍 Language Feature:"
    echo "   - Look for the globe icon (🌐) in the top-right corner"
    echo "   - Default language: French"
    echo "   - Available languages: French, English"
}

# Main function
main() {
    log_info "Starting SCP deployment to ${REMOTE_USER}@${REMOTE_HOST}"
    log_info "=================================================="
    
    # Check SSH connection
    if ! check_ssh_connection; then
        exit 1
    fi
    
    # Create backup
    create_backup
    
    # Copy files
    copy_files
    
    # Set permissions
    set_permissions
    
    # Test deployment
    test_deployment
    
    # Show instructions
    show_instructions
    
    log_success "SCP deployment completed successfully!"
    log_info "Next step: SSH to the server and run ./deploy-language-feature.sh"
}

# Run main function
main "$@" 