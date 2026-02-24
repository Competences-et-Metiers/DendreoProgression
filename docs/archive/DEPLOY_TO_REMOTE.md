# Deploy to Remote Machine (192.168.254.82)

## 🎯 Architecture
Everything runs on the remote machine:
- **Frontend**: 192.168.254.82:3000
- **Backend**: 192.168.254.82:8000
- **Database**: 192.168.254.82:5433 (PostgreSQL container)

## 📋 Deployment Steps

### 1. Stop Local Services (if running)
```bash
# On your local machine
docker-compose -f docker-compose.dev-fixed.yml down
```

### 2. Copy Project to Remote Machine
```bash
# Copy the entire project to the remote machine
scp -r /path/to/DendreoProgression cm@192.168.254.82:~/
```

### 3. SSH to Remote Machine
```bash
ssh cm@192.168.254.82
cd ~/DendreoProgression
```

### 4. Deploy on Remote Machine
```bash
# On the remote machine (192.168.254.82)
# Stop any existing containers
docker-compose down

# Start with the remote configuration
docker-compose -f docker-compose.remote.yml up -d --build

# Check status
docker-compose -f docker-compose.remote.yml ps
```

### 5. Access the Application
- **Frontend**: http://192.168.254.82:3000
- **Backend API**: http://192.168.254.82:8000/api
- **Database**: 192.168.254.82:5433

## 🔧 Key Configuration Changes

### Database Connection
The backend uses **container name** (`postgres:5432`) since all services are in the same Docker network:
```yaml
DATABASE_URL: postgresql://postgres:admin@postgres:5432/dendreo_dev_db
```

### Frontend API URL
The frontend calls the backend using the **external IP** so users from other machines can access it:
```yaml
REACT_APP_API_URL: http://192.168.254.82:8000/api
```

## 🐛 Troubleshooting

### Check Logs
```bash
# Backend logs
docker-compose -f docker-compose.remote.yml logs backend

# Frontend logs
docker-compose -f docker-compose.remote.yml logs frontend

# Database logs
docker-compose -f docker-compose.remote.yml logs postgres
```

### Test Backend API
```bash
# On remote machine
curl http://localhost:8000/health
curl http://localhost:8000/api/courses/courses
```

### Test from External Machine
```bash
# From any other machine on the network
curl http://192.168.254.82:8000/health
```

## 🔄 Development Workflow

1. **Code locally** on your development machine
2. **Push to git** or sync files to remote machine
3. **Deploy on remote** using the remote docker-compose file
4. **Access via browser** at http://192.168.254.82:3000

## 📁 Files for Remote Deployment
- `docker-compose.remote.yml` - Main compose file for remote deployment
- All source code in `/back` and `/frontend` directories
- Environment configuration in `.env.dev` (if needed) 