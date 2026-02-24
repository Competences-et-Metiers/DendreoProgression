# Dendreo Development Environment Restart Script for Windows
# This script helps restart the development environment with updated configuration

Write-Host "Restarting Dendreo Development Environment..." -ForegroundColor Green

# Stop all containers
Write-Host "Stopping existing containers..." -ForegroundColor Yellow
docker-compose -f docker-compose.dev.yml down

# Remove old volumes (optional - uncomment if you want to start fresh)
# Write-Host "Removing old volumes..." -ForegroundColor Yellow
# docker-compose -f docker-compose.dev.yml down -v

# Build and start services
Write-Host "Building and starting services..." -ForegroundColor Yellow
docker-compose -f docker-compose.dev.yml up --build -d

# Wait for services to be ready
Write-Host "Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Show status
Write-Host "Service Status:" -ForegroundColor Cyan
docker-compose -f docker-compose.dev.yml ps

# Show logs for troubleshooting
Write-Host "Recent logs (last 20 lines):" -ForegroundColor Cyan
docker-compose -f docker-compose.dev.yml logs --tail=20

Write-Host ""
Write-Host "Development environment restarted!" -ForegroundColor Green
Write-Host ""
Write-Host "Services available at:" -ForegroundColor Cyan
Write-Host "   Frontend: http://localhost:3000"
Write-Host "   Backend:  http://localhost:8000"
Write-Host "   API Docs: http://localhost:8000/docs"
Write-Host "   Portainer: http://localhost:9000"
Write-Host ""
Write-Host "To view logs: docker-compose -f docker-compose.dev.yml logs -f [service_name]"
Write-Host "To stop: docker-compose -f docker-compose.dev.yml down" 