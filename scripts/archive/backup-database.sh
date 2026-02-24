#!/bin/bash
#
# Database Backup Script for Dendreo Progression
# Creates a PostgreSQL dump of the production database
#
# Usage: ./backup-database.sh [backup_directory]
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
CONTAINER_NAME="dendreo-postgres"
DB_NAME="dendreo_progression"
DB_USER="postgres"
BACKUP_DIR="${1:-./backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/dendreo_backup_${TIMESTAMP}.dump"

echo -e "${GREEN}=== Dendreo Progression Database Backup ===${NC}"
echo "Timestamp: $(date)"
echo "Container: ${CONTAINER_NAME}"
echo "Database: ${DB_NAME}"
echo "Backup file: ${BACKUP_FILE}"
echo ""

# Check if container is running
if ! docker ps | grep -q "${CONTAINER_NAME}"; then
  echo -e "${RED}Error: Container ${CONTAINER_NAME} is not running${NC}"
  echo "Start it with: docker start ${CONTAINER_NAME}"
  exit 1
fi

# Create backup directory
echo -e "${YELLOW}Creating backup directory...${NC}"
mkdir -p "${BACKUP_DIR}"

# Create database backup
echo -e "${YELLOW}Creating database backup (this may take a few minutes)...${NC}"
docker exec "${CONTAINER_NAME}" pg_dump \
  -U "${DB_USER}" \
  -d "${DB_NAME}" \
  --format=custom \
  --verbose \
  --file=/tmp/dendreo_backup.dump 2>&1 | grep -E "processing|creating|setting"

# Copy backup from container to host
echo -e "${YELLOW}Copying backup from container...${NC}"
docker cp "${CONTAINER_NAME}:/tmp/dendreo_backup.dump" "${BACKUP_FILE}"

# Clean up container
echo -e "${YELLOW}Cleaning up container...${NC}"
docker exec "${CONTAINER_NAME}" rm /tmp/dendreo_backup.dump

# Get backup file size
BACKUP_SIZE=$(ls -lh "${BACKUP_FILE}" | awk '{print $5}')

# Get database statistics
echo -e "${YELLOW}Gathering database statistics...${NC}"
DB_SIZE=$(docker exec "${CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}" -t -c \
  "SELECT pg_size_pretty(pg_database_size('${DB_NAME}'));")

ROW_COUNTS=$(docker exec "${CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}" -t -c \
  "SELECT 'Participants: ' || COUNT(*) FROM participants
   UNION ALL SELECT 'Courses: ' || COUNT(*) FROM courses
   UNION ALL SELECT 'Modules: ' || COUNT(*) FROM modules
   UNION ALL SELECT 'Enrollments: ' || COUNT(*) FROM participant_courses;")

# Success message
echo ""
echo -e "${GREEN}✓ Backup completed successfully!${NC}"
echo ""
echo "Backup Details:"
echo "  File: ${BACKUP_FILE}"
echo "  Size: ${BACKUP_SIZE}"
echo "  Database Size: ${DB_SIZE}"
echo ""
echo "Database Contents:"
echo "${ROW_COUNTS}"
echo ""
echo "To transfer this backup to another machine:"
echo "  scp ${BACKUP_FILE} user@target-machine:/tmp/"
echo ""
echo "To restore this backup:"
echo "  ./scripts/restore-database.sh ${BACKUP_FILE}"
