#!/bin/bash

# DendreoProgression Database Migration Runner
# This script runs the migration inside the backend container

set -e  # Exit on any error

echo "🚀 Starting DendreoProgression Database Migration"
echo "=================================================="

# Check if we're in the right directory
if [ ! -f "scripts/migrate_database.py" ]; then
    echo "❌ Error: migrate_database.py not found. Make sure you're in the backend directory."
    exit 1
fi

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: python3 not found"
    exit 1
fi

# Run the migration
echo "📝 Running database migration..."
python3 scripts/migrate_database.py

# Check exit code
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Migration completed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Restart your application containers"
    echo "2. Run a sync to populate time tracking data"
    echo "3. Verify time tracking appears in the frontend"
else
    echo ""
    echo "❌ Migration failed. Check the logs above for details."
    exit 1
fi
