#!/bin/bash

echo "🔧 Starting Cron Service in Container"
echo "====================================="

# Function to start cron service
start_cron() {
    echo "🚀 Starting cron service..."
    
    # Method 1: Try service command
    if service cron start 2>/dev/null; then
        echo "✅ Cron service started with 'service' command"
    else
        echo "⚠️  Service command failed, trying alternative..."
        
        # Method 2: Start cron directly
        /usr/sbin/cron &
        sleep 2
        
        if pgrep -f "cron" > /dev/null; then
            echo "✅ Cron started directly"
        else
            echo "❌ Failed to start cron"
            return 1
        fi
    fi
    
    # Verify cron is running
    if pgrep -f "cron" > /dev/null; then
        echo "✅ Cron service is running:"
        ps aux | grep cron | grep -v grep
        return 0
    else
        echo "❌ Cron service not found in process list"
        return 1
    fi
}

# Function to monitor cron and restart if needed
monitor_cron() {
    echo "👀 Starting cron monitor..."
    while true; do
        if ! pgrep -f "cron" > /dev/null; then
            echo "$(date) - ⚠️  Cron service stopped, restarting..."
            start_cron
            sleep 5
        fi
        sleep 30
    done
}

# Main execution
echo "Current time: $(date)"
echo "Current cron jobs:"
crontab -l || echo "No cron jobs configured"

# Start cron service
if start_cron; then
    echo ""
    echo "🎉 Cron service started successfully!"
    echo "💡 To test, set a job for the next few minutes:"
    echo "   Example: sudo docker exec dendreo_sync_prod bash -c 'echo \"$(date +%M) $(date +%H) * * * /app/sync_wrapper_cron.sh >> /app/logs/cron.log 2>&1\" | crontab -'"
    echo ""
    echo "📊 Monitor logs with:"
    echo "   sudo docker exec dendreo_sync_prod tail -f /app/logs/cron.log"
    echo ""
    echo "🔄 Starting background monitor..."
    monitor_cron &
    echo "✅ Monitor started (PID: $!)"
else
    echo "❌ Failed to start cron service"
    exit 1
fi 