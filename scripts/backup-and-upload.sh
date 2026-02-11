#!/bin/bash
#
# Backup Dendreo production database and SCP to remote machine
#
# Usage: ./scripts/backup-and-upload.sh
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
CONTAINER_NAME="dendreo_postgres_prod"
DB_NAME="dendreo_prod_db"
DB_USER="postgres"
REMOTE_HOST="cm@dendreo.cm"
REMOTE_DIR="/tmp"
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/dendreo_backup_${TIMESTAMP}.dump"

echo -e "${GREEN}=== Dendreo Database Backup & Upload ===${NC}"
echo "Timestamp: $(date)"
echo "Container: ${CONTAINER_NAME}"
echo "Database: ${DB_NAME}"
echo "Remote: ${REMOTE_HOST}:${REMOTE_DIR}"
echo ""

# Check if container is running
if ! docker ps | grep -q "${CONTAINER_NAME}"; then
  echo -e "${RED}Error: Container ${CONTAINER_NAME} is not running${NC}"
  exit 1
fi

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Create database backup
echo -e "${YELLOW}Creating database backup...${NC}"
if ! docker exec "${CONTAINER_NAME}" pg_dump \
  -U "${DB_USER}" \
  -d "${DB_NAME}" \
  --format=custom \
  --file=/tmp/dendreo_backup.dump; then
  echo -e "${RED}Error: pg_dump failed${NC}"
  exit 1
fi

# Copy backup from container to host
echo -e "${YELLOW}Copying backup from container...${NC}"
docker cp "${CONTAINER_NAME}:/tmp/dendreo_backup.dump" "${BACKUP_FILE}"

# Clean up container
docker exec "${CONTAINER_NAME}" rm /tmp/dendreo_backup.dump

BACKUP_SIZE=$(ls -lh "${BACKUP_FILE}" | awk '{print $5}')
echo -e "${GREEN}Backup created: ${BACKUP_FILE} (${BACKUP_SIZE})${NC}"

# Upload to remote
echo -e "${YELLOW}Uploading to ${REMOTE_HOST}:${REMOTE_DIR}...${NC}"
scp "${BACKUP_FILE}" "${REMOTE_HOST}:${REMOTE_DIR}/"

echo ""
echo -e "${GREEN}Done. Backup uploaded to ${REMOTE_HOST}:${REMOTE_DIR}/$(basename "${BACKUP_FILE}")${NC}"
