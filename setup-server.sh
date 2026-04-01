#!/bin/bash
#
# Server Setup Script for Dendreo Progression
#
# Run ONCE on a new server before the first deploy-prod.sh.
# Installs system dependencies, decrypts secrets, and configures cron jobs.
#
# Prerequisites:
#   - git, curl (standard on most servers)
#   - An age private key (from password manager or secure transfer)
#
# Usage:
#   sudo ./setup-server.sh
#
# What this script does:
#   1. Installs age, sops, rclone
#   2. Imports the age key for secret decryption
#   3. Decrypts .env.prod, rclone config, and Google Drive service account key
#   4. Sets up the DB backup cron job
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# Resolve project directory (where this script lives)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

# The user who will own the config files and cron jobs
TARGET_USER="${SUDO_USER:-$(whoami)}"
TARGET_HOME=$(eval echo "~$TARGET_USER")

# ─── Preflight checks ────────────────────────────────────────────────

if [ "$(id -u)" -ne 0 ]; then
    log_error "This script must be run with sudo"
    echo "Usage: sudo ./setup-server.sh"
    exit 1
fi

echo -e "${GREEN}=== Dendreo Progression - Server Setup ===${NC}"
echo "Project directory: $PROJECT_DIR"
echo "Target user:       $TARGET_USER"
echo

# ─── Step 1: Install system dependencies ─────────────────────────────

log_info "Step 1/4: Installing system dependencies..."

# age
if command -v age &>/dev/null; then
    log_success "age already installed ($(age --version 2>/dev/null || echo 'ok'))"
else
    log_info "Installing age..."
    apt-get update -qq
    apt-get install -y -qq age
    log_success "age installed"
fi

# sops
SOPS_VERSION="3.9.4"
if command -v sops &>/dev/null; then
    log_success "sops already installed ($(sops --version 2>/dev/null || echo 'ok'))"
else
    log_info "Installing sops v${SOPS_VERSION}..."
    curl -sLo /usr/local/bin/sops \
        "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.amd64"
    chmod +x /usr/local/bin/sops
    log_success "sops installed ($(sops --version))"
fi

# rclone
if command -v rclone &>/dev/null; then
    log_success "rclone already installed ($(rclone version --check 2>/dev/null | head -1 || echo 'ok'))"
else
    log_info "Installing rclone..."
    curl https://rclone.org/install.sh | bash
    log_success "rclone installed"
fi

echo

# ─── Step 2: Age key setup ───────────────────────────────────────────

log_info "Step 2/4: Setting up age decryption key..."

AGE_KEY_DIR="${TARGET_HOME}/.config/sops/age"
AGE_KEY_FILE="${AGE_KEY_DIR}/keys.txt"

if [ -f "$AGE_KEY_FILE" ]; then
    log_success "Age key already exists at $AGE_KEY_FILE"
else
    mkdir -p "$AGE_KEY_DIR"
    chown -R "$TARGET_USER:$TARGET_USER" "${TARGET_HOME}/.config/sops"

    echo
    echo -e "${YELLOW}An age private key is required to decrypt secrets.${NC}"
    echo "Paste your age private key (starts with AGE-SECRET-KEY-1...):"
    echo "(Get this from your password manager or the person who set up the project)"
    echo
    read -r -p "Age private key: " AGE_KEY

    if [[ ! "$AGE_KEY" =~ ^AGE-SECRET-KEY- ]]; then
        log_error "Invalid age key format. Must start with AGE-SECRET-KEY-"
        exit 1
    fi

    echo "$AGE_KEY" > "$AGE_KEY_FILE"
    chmod 600 "$AGE_KEY_FILE"
    chown "$TARGET_USER:$TARGET_USER" "$AGE_KEY_FILE"
    log_success "Age key saved to $AGE_KEY_FILE"
fi

echo

# ─── Step 3: Decrypt secrets ─────────────────────────────────────────

log_info "Step 3/4: Decrypting secrets..."

SECRETS_DIR="${PROJECT_DIR}/secrets"
RCLONE_DIR="${TARGET_HOME}/.config/rclone"

# Decrypt .env.prod
if [ -f "${PROJECT_DIR}/.env.prod" ]; then
    log_success ".env.prod already exists (skipping)"
else
    if [ -f "${SECRETS_DIR}/env.prod.enc" ]; then
        log_info "Decrypting .env.prod..."
        sudo -u "$TARGET_USER" \
            SOPS_AGE_KEY_FILE="$AGE_KEY_FILE" \
            sops -d "${SECRETS_DIR}/env.prod.enc" > "${PROJECT_DIR}/.env.prod"
        chown "$TARGET_USER:$TARGET_USER" "${PROJECT_DIR}/.env.prod"
        chmod 600 "${PROJECT_DIR}/.env.prod"
        log_success ".env.prod decrypted"
    else
        log_warning "secrets/env.prod.enc not found - you'll need to create .env.prod manually"
    fi
fi

# Decrypt rclone config
mkdir -p "$RCLONE_DIR"
chown "$TARGET_USER:$TARGET_USER" "$RCLONE_DIR"

if [ -f "${RCLONE_DIR}/rclone.conf" ]; then
    log_success "rclone.conf already exists (skipping)"
else
    if [ -f "${SECRETS_DIR}/rclone.conf.enc" ]; then
        log_info "Decrypting rclone.conf..."
        sudo -u "$TARGET_USER" \
            SOPS_AGE_KEY_FILE="$AGE_KEY_FILE" \
            sops -d "${SECRETS_DIR}/rclone.conf.enc" > "${RCLONE_DIR}/rclone.conf"
        chown "$TARGET_USER:$TARGET_USER" "${RCLONE_DIR}/rclone.conf"
        chmod 600 "${RCLONE_DIR}/rclone.conf"
        log_success "rclone.conf decrypted"
    else
        log_warning "secrets/rclone.conf.enc not found - you'll need to configure rclone manually"
    fi
fi

# Decrypt Google Drive service account key
if [ -f "${RCLONE_DIR}/gdrive-sa.json" ]; then
    log_success "gdrive-sa.json already exists (skipping)"
else
    if [ -f "${SECRETS_DIR}/gdrive-sa.json.enc" ]; then
        log_info "Decrypting gdrive-sa.json..."
        sudo -u "$TARGET_USER" \
            SOPS_AGE_KEY_FILE="$AGE_KEY_FILE" \
            sops -d "${SECRETS_DIR}/gdrive-sa.json.enc" > "${RCLONE_DIR}/gdrive-sa.json"
        chown "$TARGET_USER:$TARGET_USER" "${RCLONE_DIR}/gdrive-sa.json"
        chmod 600 "${RCLONE_DIR}/gdrive-sa.json"
        log_success "gdrive-sa.json decrypted"
    else
        log_warning "secrets/gdrive-sa.json.enc not found - rclone Google Drive backup won't work"
    fi
fi

echo

# ─── Step 4: Set up cron jobs ────────────────────────────────────────

log_info "Step 4/4: Setting up cron jobs..."

BACKUP_SCRIPT="${PROJECT_DIR}/scripts/backup_db.sh"
BACKUP_LOG="${PROJECT_DIR}/logs/backup.log"
CRON_ENTRY="0 2 * * * ${BACKUP_SCRIPT} >> ${BACKUP_LOG} 2>&1"

# Check if cron job already exists
if sudo -u "$TARGET_USER" crontab -l 2>/dev/null | grep -qF "$BACKUP_SCRIPT"; then
    log_success "Backup cron job already configured"
else
    mkdir -p "${PROJECT_DIR}/logs"
    chown "$TARGET_USER:$TARGET_USER" "${PROJECT_DIR}/logs"
    chmod +x "$BACKUP_SCRIPT"

    # Append to existing crontab (or create new one)
    (sudo -u "$TARGET_USER" crontab -l 2>/dev/null || true; echo "$CRON_ENTRY") \
        | sudo -u "$TARGET_USER" crontab -
    log_success "Backup cron job added (daily at 2 AM)"
fi

echo

# ─── Done ─────────────────────────────────────────────────────────────

echo -e "${GREEN}=== Server setup complete ===${NC}"
echo
echo "Next steps:"
echo "  1. Run ./deploy-prod.sh to deploy the application"
echo
echo "Installed tools:"
command -v age   && echo "  age:    $(age --version 2>/dev/null || echo 'installed')"
command -v sops  && echo "  sops:   $(sops --version 2>/dev/null || echo 'installed')"
command -v rclone && echo "  rclone: $(rclone version 2>/dev/null | head -1 || echo 'installed')"
echo
echo "Secrets:"
[ -f "${PROJECT_DIR}/.env.prod" ]     && echo "  .env.prod:     OK" || echo "  .env.prod:     MISSING"
[ -f "${RCLONE_DIR}/rclone.conf" ]    && echo "  rclone.conf:   OK" || echo "  rclone.conf:   MISSING"
[ -f "${RCLONE_DIR}/gdrive-sa.json" ] && echo "  gdrive-sa.json: OK" || echo "  gdrive-sa.json: MISSING"
echo
echo "Cron jobs:"
sudo -u "$TARGET_USER" crontab -l 2>/dev/null | grep -v "^#" || echo "  (none)"
