#!/bin/bash
#
# Mirror Dendreo production database to the other machine.
# Dumps the local DB, backs up the remote DB (safety), uploads and restores.
#
# Usage: ./scripts/mirror-database.sh
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
CONTAINER_NAME="dendreo_postgres_prod"
DB_NAME="dendreo_prod_db"
DB_USER="postgres"
LOCAL_PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOCAL_DUMP="${BACKUP_DIR}/dendreo_backup_${TIMESTAMP}.dump"
REMOTE_SAFETY_DUMP="/tmp/dendreo_pre_mirror_backup_${TIMESTAMP}.dump"
REMOTE_RESTORE_DUMP="/tmp/dendreo_backup_${TIMESTAMP}.dump"

# Determine remote host based on local IP
LOCAL_IP=$(hostname -I | awk '{print $1}')
if [ "$LOCAL_IP" = "192.168.254.200" ]; then
  REMOTE_HOST="cm@192.168.254.170"
  REMOTE_PROJECT_DIR="/home/cm-dev/DendreoProgression"
elif [ "$LOCAL_IP" = "192.168.254.170" ]; then
  REMOTE_HOST="cm@192.168.254.200"
  REMOTE_PROJECT_DIR="/home/cm/DendreoProgression"
else
  echo -e "${RED}Error: Unrecognized local IP (${LOCAL_IP}), cannot determine remote target${NC}"
  exit 1
fi

echo -e "${GREEN}=== Dendreo Database Mirror ===${NC}"
echo "Timestamp: $(date)"
echo "Local IP:  ${LOCAL_IP}"
echo "Remote:    ${REMOTE_HOST}"
echo ""

# Check local container is running
if ! docker ps | grep -q "${CONTAINER_NAME}"; then
  echo -e "${RED}Error: Local container ${CONTAINER_NAME} is not running${NC}"
  exit 1
fi

# Check remote is reachable and container is running
echo -e "${YELLOW}Checking remote machine...${NC}"
if ! ssh -o ConnectTimeout=5 "${REMOTE_HOST}" "docker ps | grep -q ${CONTAINER_NAME}"; then
  echo -e "${RED}Error: Cannot reach remote or ${CONTAINER_NAME} is not running on ${REMOTE_HOST}${NC}"
  exit 1
fi
echo -e "${GREEN}Remote OK${NC}"
echo ""

# Compare last successful sync timestamps
SYNC_QUERY="SELECT last_sync_at FROM sync_metadata WHERE status = 'success' ORDER BY last_sync_at DESC LIMIT 1;"
LOCAL_SYNC=$(docker exec "${CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}" -t -A -c "${SYNC_QUERY}" 2>/dev/null || echo "")
REMOTE_SYNC=$(ssh "${REMOTE_HOST}" "docker exec ${CONTAINER_NAME} psql -U ${DB_USER} -d ${DB_NAME} -t -A -c \"${SYNC_QUERY}\"" 2>/dev/null || echo "")

echo "Last successful sync:"
echo "  Local:  ${LOCAL_SYNC:-unknown}"
echo "  Remote: ${REMOTE_SYNC:-unknown}"
echo ""

if [ -n "$LOCAL_SYNC" ] && [ -n "$REMOTE_SYNC" ] && [[ "$LOCAL_SYNC" < "$REMOTE_SYNC" ]]; then
  echo -e "${RED}WARNING: The local database is OLDER than the remote database!${NC}"
  echo -e "${RED}You are about to overwrite a newer database with an older one.${NC}"
  echo ""
  read -p "Are you sure you want to overwrite the newer remote DB? (yes/no): " OVERWRITE_CONFIRM
  if [ "${OVERWRITE_CONFIRM}" != "yes" ]; then
    echo "Cancelled."
    exit 0
  fi
  echo ""
fi

# Confirmation
echo -e "${YELLOW}This will:${NC}"
echo "  1. Dump the LOCAL database"
echo "  2. Back up the REMOTE database (safety)"
echo "  3. Upload and restore the local dump on the remote"
echo ""
echo -e "${YELLOW}The remote machine will have brief downtime during restore.${NC}"
echo ""
read -p "Continue? (yes/no): " CONFIRM
if [ "${CONFIRM}" != "yes" ]; then
  echo "Cancelled."
  exit 0
fi
echo ""

# --- Step 1: Dump local DB ---
echo -e "${BLUE}[1/4] Dumping local database...${NC}"
mkdir -p "${BACKUP_DIR}"
if ! docker exec "${CONTAINER_NAME}" pg_dump \
  -U "${DB_USER}" \
  -d "${DB_NAME}" \
  --format=custom \
  --file=/tmp/dendreo_backup.dump; then
  echo -e "${RED}Error: Local pg_dump failed${NC}"
  exit 1
fi
docker cp "${CONTAINER_NAME}:/tmp/dendreo_backup.dump" "${LOCAL_DUMP}"
docker exec "${CONTAINER_NAME}" rm /tmp/dendreo_backup.dump
LOCAL_SIZE=$(ls -lh "${LOCAL_DUMP}" | awk '{print $5}')
echo -e "${GREEN}  Local dump created: ${LOCAL_DUMP} (${LOCAL_SIZE})${NC}"
echo ""

# --- Step 2: Back up remote DB (safety) ---
echo -e "${BLUE}[2/4] Backing up remote database (safety)...${NC}"
ssh "${REMOTE_HOST}" "\
  docker exec ${CONTAINER_NAME} pg_dump \
    -U ${DB_USER} \
    -d ${DB_NAME} \
    --format=custom \
    --file=/tmp/dendreo_safety_backup.dump && \
  docker cp ${CONTAINER_NAME}:/tmp/dendreo_safety_backup.dump ${REMOTE_SAFETY_DUMP} && \
  docker exec ${CONTAINER_NAME} rm /tmp/dendreo_safety_backup.dump"
REMOTE_SIZE=$(ssh "${REMOTE_HOST}" "ls -lh ${REMOTE_SAFETY_DUMP} | awk '{print \$5}'")
echo -e "${GREEN}  Remote safety backup: ${REMOTE_SAFETY_DUMP} (${REMOTE_SIZE})${NC}"
echo ""

# --- Step 3: Upload local dump to remote ---
echo -e "${BLUE}[3/4] Uploading local dump to remote...${NC}"
scp "${LOCAL_DUMP}" "${REMOTE_HOST}:${REMOTE_RESTORE_DUMP}"
echo -e "${GREEN}  Upload complete${NC}"
echo ""

# --- Step 4: Restore on remote ---
echo -e "${BLUE}[4/4] Restoring database on remote...${NC}"
ssh "${REMOTE_HOST}" "cd ${REMOTE_PROJECT_DIR} && echo yes | ./scripts/restore-database.sh ${REMOTE_RESTORE_DUMP}"
# Clean up the uploaded dump on the remote
ssh "${REMOTE_HOST}" "rm -f ${REMOTE_RESTORE_DUMP}"
echo ""

# Done
echo -e "${GREEN}=== Mirror complete ===${NC}"
echo ""
echo "Local dump:          ${LOCAL_DUMP}"
echo "Remote safety backup: ${REMOTE_HOST}:${REMOTE_SAFETY_DUMP}"
echo ""
echo -e "${BLUE}To rollback the remote, SSH in and run:${NC}"
echo "  cd ${REMOTE_PROJECT_DIR} && ./scripts/restore-database.sh ${REMOTE_SAFETY_DUMP}"
