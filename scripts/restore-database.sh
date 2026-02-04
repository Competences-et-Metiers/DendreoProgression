#!/bin/bash
#
# Database Restore Script for Dendreo Progression
# Restores a PostgreSQL dump to the production database
#
# Usage: ./restore-database.sh /path/to/backup.dump
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONTAINER_NAME="dendreo_postgres_prod"
SYNC_CONTAINER="dendreo_sync_prod"
DB_NAME="dendreo_prod_db"
DB_USER="postgres"
BACKUP_FILE="${1}"

echo -e "${GREEN}=== Dendreo Progression Database Restore ===${NC}"
echo "Timestamp: $(date)"
echo ""

# Check if backup file argument provided
if [ -z "${BACKUP_FILE}" ]; then
  echo -e "${RED}Error: No backup file specified${NC}"
  echo ""
  echo "Usage: $0 /path/to/backup.dump"
  echo ""
  echo "Example:"
  echo "  $0 ./backups/dendreo_backup_20260204_120000.dump"
  echo "  $0 /tmp/dendreo_backup.dump"
  exit 1
fi

# Check if backup file exists
if [ ! -f "${BACKUP_FILE}" ]; then
  echo -e "${RED}Error: Backup file not found: ${BACKUP_FILE}${NC}"
  echo ""
  echo "Available backups:"
  ls -lh ./backups/*.dump 2>/dev/null || echo "  No backups found in ./backups/"
  exit 1
fi

BACKUP_SIZE=$(ls -lh "${BACKUP_FILE}" | awk '{print $5}')
echo "Backup file: ${BACKUP_FILE}"
echo "File size: ${BACKUP_SIZE}"
echo ""

# Check if container is running
if ! docker ps | grep -q "${CONTAINER_NAME}"; then
  echo -e "${RED}Error: Container ${CONTAINER_NAME} is not running${NC}"
  echo "Start it with: docker start ${CONTAINER_NAME}"
  exit 1
fi

# Warning prompt
echo -e "${YELLOW}WARNING: This will delete the current database and restore from backup!${NC}"
echo -e "${YELLOW}All current data will be lost!${NC}"
echo ""
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "${CONFIRM}" != "yes" ]; then
  echo "Restore cancelled."
  exit 0
fi

echo ""
echo -e "${BLUE}Starting database restore...${NC}"
echo ""

# Stop sync container to prevent syncs during restore
echo -e "${YELLOW}[1/6] Stopping sync container...${NC}"
if docker ps | grep -q "${SYNC_CONTAINER}"; then
  docker stop "${SYNC_CONTAINER}" || true
  echo "  ✓ Sync container stopped"
else
  echo "  ℹ Sync container not running"
fi

# Copy backup to container
echo -e "${YELLOW}[2/6] Copying backup to container...${NC}"
docker cp "${BACKUP_FILE}" "${CONTAINER_NAME}:/tmp/dendreo_backup.dump"
echo "  ✓ Backup copied"

# Drop existing database
echo -e "${YELLOW}[3/6] Dropping existing database...${NC}"
docker exec "${CONTAINER_NAME}" psql -U "${DB_USER}" -c "DROP DATABASE IF EXISTS ${DB_NAME};" 2>&1 | grep -v "NOTICE" || true
echo "  ✓ Database dropped"

# Create new database
echo -e "${YELLOW}[4/6] Creating new database...${NC}"
docker exec "${CONTAINER_NAME}" psql -U "${DB_USER}" -c "CREATE DATABASE ${DB_NAME};"
echo "  ✓ Database created"

# Restore database
echo -e "${YELLOW}[5/6] Restoring database from backup (this may take a few minutes)...${NC}"
docker exec "${CONTAINER_NAME}" pg_restore \
  -U "${DB_USER}" \
  -d "${DB_NAME}" \
  --clean \
  --if-exists \
  --no-owner \
  --no-privileges \
  --verbose \
  /tmp/dendreo_backup.dump 2>&1 | grep -E "processing|creating|setting" || true
echo "  ✓ Database restored"

# Clean up
echo -e "${YELLOW}[6/6] Cleaning up...${NC}"
docker exec "${CONTAINER_NAME}" rm /tmp/dendreo_backup.dump
echo "  ✓ Temporary files removed"

# Verify restoration
echo ""
echo -e "${YELLOW}Verifying restoration...${NC}"

# Check tables exist
TABLES=$(docker exec "${CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}" -t -c "\dt" | grep -c "public" || echo "0")
echo "  Tables found: ${TABLES}"

# Get row counts
ROW_COUNTS=$(docker exec "${CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}" -t -c \
  "SELECT 'Participants: ' || COUNT(*) FROM participants
   UNION ALL SELECT 'Courses: ' || COUNT(*) FROM courses
   UNION ALL SELECT 'Modules: ' || COUNT(*) FROM modules
   UNION ALL SELECT 'Enrollments: ' || COUNT(*) FROM participant_courses;")

# Get last sync info
LAST_SYNC=$(docker exec "${CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}" -t -c \
  "SELECT sync_type || ' at ' || last_sync_at FROM sync_metadata ORDER BY last_sync_at DESC LIMIT 1;" 2>/dev/null || echo "No sync metadata found")

# Success message
echo ""
echo -e "${GREEN}✓ Database restore completed successfully!${NC}"
echo ""
echo "Database Contents:"
echo "${ROW_COUNTS}"
echo ""
echo "Last Sync:"
echo "  ${LAST_SYNC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Verify the application is working:"
echo "     curl http://localhost:8000/api/courses/stats"
echo ""
echo "  2. Check the frontend (if deployed):"
echo "     Open browser to http://your-domain"
echo ""
echo "  3. Restart sync container if needed:"
echo "     docker start ${SYNC_CONTAINER}"
echo ""
echo "  4. Monitor logs for any issues:"
echo "     docker logs dendreoprogression-backend-1 -f"
