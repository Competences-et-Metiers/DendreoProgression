#!/bin/bash
#
# Automated PostgreSQL backup with Google Drive upload via rclone.
#
# Usage:
#   ./scripts/backup_db.sh              # manual run
#   crontab: 0 2 * * * /path/to/scripts/backup_db.sh >> /path/to/logs/backup.log 2>&1
#
# Prerequisites:
#   - rclone configured with a remote named "gdrive" (Google Drive service account)
#   - Docker running with dendreo_postgres_prod container
#

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUP_DIR="${PROJECT_DIR}/backups"
CONTAINER="dendreo_postgres_prod"
DB_NAME="dendreo_prod_db"
DB_USER="postgres"
GDRIVE_REMOTE="gdrive:DendreoBackups"
RETAIN_DAYS=30
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="dendreo_backup_${TIMESTAMP}.sql.gz"

# Colors (disabled when not interactive)
if [ -t 1 ]; then
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  NC='\033[0m'
else
  GREEN='' RED='' NC=''
fi

log() { echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

# Verify container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  log "${RED}Error: Container ${CONTAINER} is not running${NC}"
  exit 1
fi

# Verify rclone is available
if ! command -v rclone &>/dev/null; then
  log "${RED}Error: rclone is not installed${NC}"
  exit 1
fi

mkdir -p "$BACKUP_DIR"

# Dump and compress
log "Dumping database..."
docker exec "$CONTAINER" pg_dump -U "$DB_USER" "$DB_NAME" | gzip > "$BACKUP_DIR/$FILENAME"
SIZE=$(du -h "$BACKUP_DIR/$FILENAME" | cut -f1)
log "${GREEN}Backup created: $FILENAME ($SIZE)${NC}"

# Upload to Google Drive
log "Uploading to Google Drive..."
if rclone copy "$BACKUP_DIR/$FILENAME" "$GDRIVE_REMOTE/" --log-level NOTICE; then
  log "${GREEN}Upload complete${NC}"
else
  log "${RED}Upload failed - local backup is still available${NC}"
  exit 1
fi

# Prune old local backups
DELETED=$(find "$BACKUP_DIR" -name "dendreo_backup_*.sql.gz" -mtime +$RETAIN_DAYS -delete -print | wc -l)
if [ "$DELETED" -gt 0 ]; then
  log "Pruned $DELETED local backup(s) older than $RETAIN_DAYS days"
fi

log "${GREEN}Backup complete${NC}"
