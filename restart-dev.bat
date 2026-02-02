@echo off
echo Restarting Dendreo Development Environment...

echo Stopping existing containers...
docker-compose -f docker-compose.dev.yml down

echo Building and starting services...
docker-compose -f docker-compose.dev.yml up --build -d

echo Waiting for services to be ready...
timeout /t 10 /nobreak >nul

echo Service Status:
docker-compose -f docker-compose.dev.yml ps

echo Recent logs:
docker-compose -f docker-compose.dev.yml logs --tail=20

echo.
echo Development environment restarted!
echo.
echo Services available at:
echo    Frontend: http://localhost:3000
echo    Backend:  http://localhost:8000
echo    API Docs: http://localhost:8000/docs
echo    Portainer: http://localhost:9000
echo.
echo To view logs: docker-compose -f docker-compose.dev.yml logs -f [service_name]
echo To stop: docker-compose -f docker-compose.dev.yml down 