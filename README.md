# Dendreo Progression Dashboard

A full-stack application for tracking course progression and participant engagement in the Dendreo learning management system.

## 🎯 Features

### Frontend (React Dashboard)
- **Dashboard Overview**: Statistics for all courses, participants, and overall progress
- **Course Management**: Browse and filter courses by completion status and criteria  
- **Participant Tracking**: Detailed participant information for each course
- **Progress Visualization**: Interactive progress bars and completion indicators
- **Search & Filter**: Advanced filtering and sorting capabilities
- **Responsive Design**: Mobile-friendly interface built with Tailwind CSS

### Backend (FastAPI)
- **RESTful API**: Clean API endpoints for data access
- **Database Sync**: Synchronization with Dendreo API
- **Data Filtering**: Automatic filtering of elearning_sync courses
- **Course Analytics**: Progression tracking and completion statistics
- **Participant Management**: Comprehensive participant data management

## 🔧 Architecture

```
Frontend (React) ←→ Backend (FastAPI) ←→ PostgreSQL Database ←→ Dendreo API
```

## 🚀 Quick Start

### Prerequisites
- **Node.js** (version 14 or higher)
- **Python 3.8+**
- **PostgreSQL** database
- **Dendreo API** access credentials

### 1. Backend Setup

1. **Navigate to backend directory:**
   ```bash
   cd back
   ```

2. **Install Python dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Configure environment variables:**
   Create a `.env` file with:
   ```bash
   DATABASE_URL=postgresql://username:password@192.168.254.24:5432/dendreo_db
   DENDREO_API_KEY=your_api_key_here
   DENDREO_BASE_URL=https://pro.dendreo.com/competences_et_metiers/api
   ```

4. **Setup database:**
   ```bash
   python create_db.py
   ```

5. **Start the API server:**
   ```bash
   python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

### 2. Frontend Setup

1. **Navigate to frontend directory:**
   ```bash
   cd frontend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Start the development server:**
   ```bash
   npm start
   ```

The application will open at `http://192.168.254.24:3000`

### 3. Initial Data Sync

1. **Sync data from Dendreo API:**
   ```bash
   curl -X POST http://192.168.254.24:8000/api/sync/sync-all
   ```

2. **Or run a test sync first:**
   ```bash
   curl -X POST http://192.168.254.24:8000/api/sync/sync-test
   ```

## 📊 API Endpoints

### Dashboard & Statistics
- `GET /api/courses/stats` - Overall dashboard statistics
- `GET /api/courses/courses` - List all courses with basic info

### Course Management
- `GET /api/courses/courses/{id}/participants` - Course participants and progress
- `GET /api/courses/participants/{id}` - Individual participant details

### Data Synchronization
- `POST /api/sync/sync-all` - Full sync from Dendreo API
- `POST /api/sync/sync-test` - Test sync with sample data
- `POST /api/sync/cleanup-elearning-sync` - Clean up elearning_sync data
- `GET /api/sync/elearning-sync-stats` - Stats on elearning_sync data

## 🎨 Frontend Components

### Dashboard Page (`/`)
- **Stats Overview**: Total courses, participants, average progress, completion rate
- **Course List**: Searchable/filterable list of all courses
- **Interactive Elements**: Click courses to view participants

### Course Detail Page (`/courses/{id}`)
- **Course Summary**: Total participants, completion stats, average progress  
- **Participant List**: Detailed list with individual progress
- **Search & Filter**: Find participants by name, email, or completion status
- **Progress Tracking**: Visual progress bars and module completion counts

## 🔐 Data Flow

1. **Dendreo API** provides course and participant data
2. **Backend sync** processes and filters data (excludes elearning_sync)
3. **PostgreSQL** stores normalized data with relationships
4. **FastAPI** serves clean REST endpoints
5. **React frontend** displays interactive dashboards

## 📱 UI Screenshots

### Dashboard Overview
- Clean, modern interface with statistics cards
- Course grid with progress indicators
- Advanced filtering and sorting options

### Course Details
- Participant list with progress tracking
- Module completion visualization
- Real-time search and filtering

## 🛠️ Development

### Backend Development
- **Framework**: FastAPI with SQLAlchemy ORM
- **Database**: PostgreSQL with async support
- **API Client**: Custom Dendreo API integration
- **Logging**: Comprehensive logging to files and console

### Frontend Development
- **Framework**: React 18 with React Router
- **Styling**: Tailwind CSS for responsive design
- **Icons**: Lucide React icon library
- **HTTP Client**: Axios for API communication

### Adding New Features

1. **New API Endpoint**:
   - Add route in `back/app/api/routes/`
   - Update frontend service in `frontend/src/services/api.js`

2. **New Frontend Page**:
   - Create component in `frontend/src/pages/`
   - Add route in `frontend/src/App.js`

3. **New Data Model**:
   - Update `back/app/models/models.py`
   - Create migration or recreate database

## 🔧 Configuration

### Backend Settings
- **Database**: PostgreSQL connection string
- **API Keys**: Dendreo API credentials
- **Sync Settings**: Batch sizes and timing
- **Logging**: Log levels and file locations

### Frontend Settings
- **API URL**: Backend API base URL
- **Styling**: Tailwind configuration
- **Build**: React build settings

## 📈 Monitoring

### Health Checks
- `GET /health` - Backend health status
- Database connection monitoring
- API sync status tracking

### Logs
- Application logs in `back/logs/app.log`
- Sync operation detailed logging
- Error tracking and debugging

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test thoroughly
4. Submit a pull request

## 📄 License

This project is private and proprietary.

---

## 🎯 User Experience

The application provides an intuitive way to:

1. **Track Overall Progress**: See high-level statistics across all courses
2. **Monitor Individual Courses**: Drill down into specific course performance  
3. **Manage Participants**: View detailed participant progress and engagement
4. **Filter & Search**: Quickly find specific courses or participants
5. **Visual Progress**: Clear progress indicators and completion status

Perfect for administrators, course managers, and training coordinators who need comprehensive visibility into learning progress and engagement across the Dendreo platform. 