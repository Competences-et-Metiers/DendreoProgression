#!/bin/bash
#
# Push .env.prod to the production remote machine.
#
# Usage: ./scripts/push-env-prod.sh
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
LOCAL_PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${LOCAL_PROJECT_DIR}/.env.prod"
REMOTE_HOST="cm@192.168.254.200"
REMOTE_PATH="/home/cm/DendreoProgression/.env.prod"

# Check .env.prod exists locally
if [ ! -f "${ENV_FILE}" ]; then
  echo -e "${RED}Error: ${ENV_FILE} not found${NC}"
  exit 1
fi

# Check remote is reachable
echo -e "${YELLOW}Checking remote machine...${NC}"
if ! ssh -o ConnectTimeout=5 "${REMOTE_HOST}" "echo ok" > /dev/null 2>&1; then
  echo -e "${RED}Error: Cannot reach ${REMOTE_HOST}${NC}"
  exit 1
fi
echo -e "${GREEN}Remote OK${NC}"
echo ""

# Show what we're doing
LOCAL_SIZE=$(ls -lh "${ENV_FILE}" | awk '{print $5}')
echo "Source:      ${ENV_FILE} (${LOCAL_SIZE})"
echo "Destination: ${REMOTE_HOST}:${REMOTE_PATH}"
echo ""

# Upload
echo -e "${YELLOW}Uploading .env.prod...${NC}"
scp "${ENV_FILE}" "${REMOTE_HOST}:${REMOTE_PATH}"

echo -e "${GREEN}Done — .env.prod pushed to ${REMOTE_HOST}${NC}"
