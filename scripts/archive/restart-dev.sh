#!/bin/bash

# Dendreo Development Environment Restart Script
# This script helps restart the development environment with updated configuration

set -e

echo "🔄 Restarting Dendreo Development Environment..."

# Stop all containers
echo "📦 Stopping existing containers..."
docker-compose -f docker-compose.dev.yml down

# Remove old volumes (optional - uncomment if you want to start fresh)
# echo "🗑️  Removing old volumes..."
# docker-compose -f docker-compose.dev.yml down -v

# Build and start services
echo "🔨 Building and starting services..."
docker-compose -f docker-compose.dev.yml up --build -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 10

# Show status
echo "📊 Service Status:"
docker-compose -f docker-compose.dev.yml ps

# Show logs for troubleshooting
echo "📋 Recent logs (last 20 lines):"
docker-compose -f docker-compose.dev.yml logs --tail=20

echo ""
echo "✅ Development environment restarted!"
echo ""
echo "🌐 Services available at:"
echo "   Frontend: http://localhost:3000"
echo "   Backend:  http://localhost:8000"
echo "   API Docs: http://localhost:8000/docs"
echo "   Portainer: http://localhost:9000"
echo ""
echo "📝 To view logs: docker-compose -f docker-compose.dev.yml logs -f [service_name]"
echo "📝 To stop: docker-compose -f docker-compose.dev.yml down" 