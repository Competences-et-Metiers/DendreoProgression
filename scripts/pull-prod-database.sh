#!/bin/bash
#
# Pull the Scaleway production database down to the local dev database.
# Dumps prod, backs up local (safety), downloads and restores into dev.
#
# Usage: ./scripts/pull-prod-database.sh
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Remote (prod) configuration
REMOTE_HOST="deploy@163.172.153.172"
REMOTE_KEY="${HOME}/.ssh/deploy_key"
PROD_CONTAINER="dendreo_postgres_prod"
PROD_DB="dendreo_prod_db"
PROD_USER="postgres"

# Local (dev) configuration
DEV_CONTAINER="dendreo_postgres_prod"
DEV_DB="dendreo_prod_db"
DEV_USER="postgres"

# Paths
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PROD_DUMP="${BACKUP_DIR}/prod_pull_${TIMESTAMP}.dump"
LOCAL_SAFETY_DUMP="${BACKUP_DIR}/dev_safety_${TIMESTAMP}.dump"

SSH="ssh -i ${REMOTE_KEY} -o ConnectTimeout=10"
SCP="scp -i ${REMOTE_KEY}"

echo -e "${GREEN}=== Pull Production Database ===${NC}"
echo "Timestamp: $(date)"
echo "Remote:    ${REMOTE_HOST}"
echo "Prod DB:   ${PROD_DB} (${PROD_CONTAINER})"
echo "Dev DB:    ${DEV_DB} (${DEV_CONTAINER})"
echo ""

# --- Checks ---
if [ ! -f "${REMOTE_KEY}" ]; then
  echo -e "${RED}Error: SSH key not found at ${REMOTE_KEY}${NC}"
  exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -q "^${DEV_CONTAINER}$"; then
  echo -e "${RED}Error: Local container ${DEV_CONTAINER} is not running${NC}"
  exit 1
fi

echo -e "${YELLOW}Checking remote...${NC}"
if ! ${SSH} "${REMOTE_HOST}" "docker ps --format '{{.Names}}' | grep -q '^${PROD_CONTAINER}$'"; then
  echo -e "${RED}Error: Cannot reach remote or ${PROD_CONTAINER} is not running${NC}"
  exit 1
fi
echo -e "${GREEN}Remote OK${NC}"
echo ""

# --- Confirmation ---
echo -e "${YELLOW}This will:${NC}"
echo "  1. Dump the REMOTE prod database"
echo "  2. Back up the LOCAL dev database (safety)"
echo "  3. Download the prod dump"
echo "  4. Restore prod dump into local dev database (overwrites dev data)"
echo ""
read -p "Continue? (yes/no): " CONFIRM
if [ "${CONFIRM}" != "yes" ]; then
  echo "Cancelled."
  exit 0
fi
echo ""

mkdir -p "${BACKUP_DIR}"

# --- Step 1: Dump prod ---
echo -e "${BLUE}[1/4] Dumping remote prod database...${NC}"
${SSH} "${REMOTE_HOST}" "docker exec ${PROD_CONTAINER} pg_dump \
  -U ${PROD_USER} \
  -d ${PROD_DB} \
  --format=custom \
  --file=/tmp/prod_pull.dump"
${SSH} "${REMOTE_HOST}" "docker cp ${PROD_CONTAINER}:/tmp/prod_pull.dump /tmp/prod_pull.dump && \
  docker exec ${PROD_CONTAINER} rm /tmp/prod_pull.dump"
REMOTE_SIZE=$(${SSH} "${REMOTE_HOST}" "ls -lh /tmp/prod_pull.dump | awk '{print \$5}'")
echo -e "${GREEN}  Remote dump created (${REMOTE_SIZE})${NC}"
echo ""

# --- Step 2: Back up local dev DB (safety) ---
echo -e "${BLUE}[2/4] Backing up local dev database (safety)...${NC}"
docker exec "${DEV_CONTAINER}" pg_dump \
  -U "${DEV_USER}" \
  -d "${DEV_DB}" \
  --format=custom \
  --file=/tmp/dev_safety.dump
docker cp "${DEV_CONTAINER}:/tmp/dev_safety.dump" "${LOCAL_SAFETY_DUMP}"
docker exec "${DEV_CONTAINER}" rm /tmp/dev_safety.dump
LOCAL_SAFETY_SIZE=$(ls -lh "${LOCAL_SAFETY_DUMP}" | awk '{print $5}')
echo -e "${GREEN}  Dev safety backup: ${LOCAL_SAFETY_DUMP} (${LOCAL_SAFETY_SIZE})${NC}"
echo ""

# --- Step 3: Download prod dump ---
echo -e "${BLUE}[3/4] Downloading prod dump...${NC}"
${SCP} "${REMOTE_HOST}:/tmp/prod_pull.dump" "${PROD_DUMP}"
${SSH} "${REMOTE_HOST}" "rm /tmp/prod_pull.dump"
PROD_SIZE=$(ls -lh "${PROD_DUMP}" | awk '{print $5}')
echo -e "${GREEN}  Downloaded: ${PROD_DUMP} (${PROD_SIZE})${NC}"
echo ""

# --- Step 4: Restore into dev ---
echo -e "${BLUE}[4/4] Restoring into local dev database...${NC}"

echo "  [4a] Stopping local dev backend/sync..."
DEV_BACKEND=$(docker ps --format '{{.Names}}' | grep -E 'backend.*dev|dev.*backend' || true)
DEV_SYNC=$(docker ps --format '{{.Names}}' | grep -E 'sync.*dev|dev.*sync' || true)
[ -n "${DEV_BACKEND}" ] && docker stop "${DEV_BACKEND}" >/dev/null && echo "    Backend stopped (${DEV_BACKEND})"
[ -n "${DEV_SYNC}" ] && docker stop "${DEV_SYNC}" >/dev/null && echo "    Sync stopped (${DEV_SYNC})"

echo "  [4b] Terminating DB connections..."
docker exec "${DEV_CONTAINER}" psql -U "${DEV_USER}" -c \
  "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${DEV_DB}' AND pid <> pg_backend_pid();" \
  >/dev/null 2>&1 || true

echo "  [4c] Copying dump into dev container..."
docker cp "${PROD_DUMP}" "${DEV_CONTAINER}:/tmp/prod_restore.dump"

echo "  [4d] Dropping and recreating dev database..."
docker exec "${DEV_CONTAINER}" psql -U "${DEV_USER}" -c "DROP DATABASE IF EXISTS ${DEV_DB};" 2>&1 | grep -v NOTICE || true
docker exec "${DEV_CONTAINER}" psql -U "${DEV_USER}" -c "CREATE DATABASE ${DEV_DB};"

echo "  [4e] Restoring from prod dump..."
docker exec "${DEV_CONTAINER}" pg_restore \
  -U "${DEV_USER}" \
  -d "${DEV_DB}" \
  --clean \
  --if-exists \
  --no-owner \
  --no-privileges \
  /tmp/prod_restore.dump 2>&1 | grep -E "^pg_restore: (creating|processing)" | tail -5 || true

echo "  [4f] Disabling sync schedule on dev (prevents dev from burning through prod API quota)..."
docker exec "${DEV_CONTAINER}" psql -U "${DEV_USER}" -d "${DEV_DB}" -c \
  "UPDATE admin_sync_config SET cron_enabled = FALSE;" 2>&1 | grep -v NOTICE || true
echo -e "${GREEN}    Cron disabled on dev (toggle back on in admin panel if you need it)${NC}"

echo "  [4g] Cleaning up and restarting services..."
docker exec "${DEV_CONTAINER}" rm /tmp/prod_restore.dump
[ -n "${DEV_BACKEND}" ] && docker start "${DEV_BACKEND}" >/dev/null && echo "    Backend restarted"
[ -n "${DEV_SYNC}" ] && docker start "${DEV_SYNC}" >/dev/null && echo "    Sync restarted"

echo "  [4h] Verifying..."
TABLES=$(docker exec "${DEV_CONTAINER}" psql -U "${DEV_USER}" -d "${DEV_DB}" -t -c "\dt" | grep -c "public" || echo "0")
echo "    Tables found: ${TABLES}"
docker exec "${DEV_CONTAINER}" psql -U "${DEV_USER}" -d "${DEV_DB}" -t -c \
  "SELECT 'Participants: ' || COUNT(*) FROM participants
   UNION ALL SELECT 'Courses: ' || COUNT(*) FROM courses
   UNION ALL SELECT 'Modules: ' || COUNT(*) FROM modules
   UNION ALL SELECT 'Enrollments: ' || COUNT(*) FROM participant_courses;" 2>/dev/null || true

echo ""
echo -e "${GREEN}=== Pull Complete ===${NC}"
echo "Prod dump:        ${PROD_DUMP}"
echo "Dev safety dump:  ${LOCAL_SAFETY_DUMP}"
echo ""
echo -e "${YELLOW}To restore the dev safety backup if needed:${NC}"
echo "  docker cp ${LOCAL_SAFETY_DUMP} ${DEV_CONTAINER}:/tmp/restore.dump"
echo "  docker exec ${DEV_CONTAINER} pg_restore -U ${DEV_USER} -d ${DEV_DB} --clean --if-exists /tmp/restore.dump"
