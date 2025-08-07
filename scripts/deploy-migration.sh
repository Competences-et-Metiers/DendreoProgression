#!/bin/bash

# DendreoProgression Database Migration Script
# This script applies the time tracking migration to your production database

set -e  # Exit on any error

# Configuration - UPDATE THESE VALUES FOR YOUR PRODUCTION SERVER
DB_HOST="your-production-db-host"
DB_PORT="5432"
DB_NAME="your-production-db-name"
DB_USER="your-production-db-user"
DB_PASSWORD="your-production-db-password"

# Migration file path
MIGRATION_FILE="database/migrations/001-add-time-tracking-columns.sql"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== DendreoProgression Database Migration ===${NC}"
echo "This script will add time tracking columns to your production database."
echo ""

# Check if migration file exists
if [ ! -f "$MIGRATION_FILE" ]; then
    echo -e "${RED}Error: Migration file not found at $MIGRATION_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}Please update the database configuration variables in this script:${NC}"
echo "  - DB_HOST: $DB_HOST"
echo "  - DB_PORT: $DB_PORT"
echo "  - DB_NAME: $DB_NAME"
echo "  - DB_USER: $DB_USER"
echo "  - DB_PASSWORD: [hidden]"
echo ""

# Ask for confirmation
read -p "Have you updated the database configuration? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Migration cancelled. Please update the configuration and run again.${NC}"
    exit 1
fi

echo -e "${YELLOW}Warning: This will modify your production database.${NC}"
read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Migration cancelled.${NC}"
    exit 1
fi

# Test database connection
echo -e "${GREEN}Testing database connection...${NC}"
if ! PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${RED}Error: Cannot connect to database. Please check your configuration.${NC}"
    exit 1
fi
echo -e "${GREEN}Database connection successful!${NC}"

# Create backup
echo -e "${GREEN}Creating database backup...${NC}"
BACKUP_FILE="dendreo_backup_$(date +%Y%m%d_%H%M%S).sql"
PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" > "$BACKUP_FILE"
echo -e "${GREEN}Backup created: $BACKUP_FILE${NC}"

# Run migration
echo -e "${GREEN}Running migration...${NC}"
PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$MIGRATION_FILE"

echo -e "${GREEN}Migration completed successfully!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Restart your application to pick up the new columns"
echo "2. Run a sync to populate the new time tracking data"
echo "3. Verify the migration by checking the new columns in your database"
echo ""
echo -e "${GREEN}Backup file: $BACKUP_FILE${NC}"
echo "Keep this backup file for safety."
