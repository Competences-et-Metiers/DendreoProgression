# Backend Agent Guide

This document provides guidelines for AI agents working on the Dendreo Progression backend.

## Tech Stack

- **FastAPI** (0.115) - Async web framework
- **SQLAlchemy** (2.0+) - ORM with PostgreSQL
- **Pydantic** (2.x) / **pydantic-settings** - Data validation and settings
- **python-jose** - JWT authentication
- **passlib** + **bcrypt** - Password hashing
- **httpx** - Async HTTP client (Dendreo API)
- **Redis** - Optional caching layer
- **pandas** - Data processing for sync
- **Uvicorn** - ASGI server

## Directory Structure

```
back/
├── app/
│   ├── main.py                  # FastAPI app entry point, CORS, route registration
│   ├── config/
│   │   └── settings.py          # Pydantic BaseSettings, env loading
│   ├── models/
│   │   ├── database.py          # Engine, session, connection pool config
│   │   ├── models.py            # SQLAlchemy ORM models
│   │   └── schemas.py           # Pydantic request/response schemas
│   ├── schemas/
│   │   └── course.py            # Course-specific response schemas
│   ├── api/
│   │   └── routes/
│   │       ├── auth.py          # Login, user info, password change
│   │       ├── participants.py  # Participant listing, search, filtering
│   │       ├── courses.py       # Courses, dashboard stats, modules
│   │       └── sync.py          # Sync status (read-only)
│   ├── auth/
│   │   ├── utils.py             # JWT create/decode, password hash/verify
│   │   └── dependencies.py      # FastAPI Depends() for auth injection
│   └── services/
│       ├── dendreo_client.py    # Async Dendreo API client
│       ├── dendreo_sync.py      # Sync orchestration
│       ├── data_processor.py    # Data transformation layer
│       ├── hubspot_client.py    # HubSpot deal updates
│       └── cache_service.py     # Redis caching wrapper
├── scripts/
│   ├── sync_dendreo.py          # Standalone sync runner (CLI)
│   ├── create_user.py           # User creation utility
│   ├── migrate_database.py      # Database migrations
│   ├── check_sync_status.py     # Sync monitoring
│   └── sync_health_check.py     # Health checks (Nagios-compatible)
├── _archive/                    # Archived one-time migration/test scripts
├── requirements.txt             # Python dependencies
├── run.py                       # Development server launcher
├── reset_database.py            # Database reset utility (destructive)
├── Dockerfile.backend.prod      # Production API container
└── Dockerfile.sync.prod         # Production sync container (cron-based)
```

## Architecture

**Layered structure:**
```
API Routes (routes/)  -->  Services (services/)  -->  Models (models/)
       |                        |                          |
  HTTP endpoints          Business logic             ORM + schemas
  Auth injection          External APIs              Database ops
  Response formatting     Data transformation        Validation
```

**Data flow (sync):**
```
Dendreo API  -->  DendreoClient  -->  DendreoSync  -->  DataProcessor  -->  DB
                                           |
                                      HubSpotClient  -->  HubSpot API
```

**Data flow (API requests):**
```
HTTP Request  -->  Auth Dependency  -->  Route Handler  -->  DB Query  -->  Response
                                              |
                                        Cache (Redis)
```

## Database Models

Seven tables defined in `models/models.py`:

| Model | Table | Purpose |
|-------|-------|---------|
| `Participant` | `participants` | Learner profiles from Dendreo |
| `Course` | `courses` | Actions de Formation (ADF) |
| `Module` | `modules` | E-learning modules with LMS progression |
| `ParticipantCourse` | `participant_courses` | Enrollments with computed progression |
| `ParticipantHubspotData` | `participant_hubspot_data` | HubSpot transaction links |
| `SyncMetadata` | `sync_metadata` | Sync operation logs |
| `User` | `users` | Authentication accounts |

### Dendreo ID Conventions

These IDs come from the Dendreo API and are used throughout the codebase:

- `id_participant` - Learner identifier
- `id_action_formation` (ADF) - Course/training action identifier
- `id_lam` - Learning Activity Module (groups modules within an ADF)
- `id_lmp` - Learning Module Participant (module assigned to a learner)
- `id_lap` - Learning Activity Participant (enrollment record)
- `id_entreprise` - Company identifier

### Key Relationships

```
Participant (1) <--> (M) ParticipantCourse (M) <--> (1) Course
Participant (1) <--> (M) Module (M) <--> (1) Course
Participant (1) <--> (M) ParticipantHubspotData
Course (1) <--> (M) Module
```

### Unique Constraints

- `Course`: (`id_action_formation`, `id_lam`)
- `Module`: (`id_lmp`, `participant_id`)
- `ParticipantHubspotData`: (`participant_id`, `id_action_formation`)
- `User`: `username`

## API Endpoints

### Auth (`/api/auth`)
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/login` | No | Authenticate, returns JWT |
| GET | `/me` | Yes | Get current user info |

### Participants (`/api/participants`)
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/` | No | List with pagination, search, filters |
| GET | `/count` | No | Total participant count |
| GET | `/{id}` | No | Single participant with courses |
| GET | `/email/{email}` | No | Lookup by email |

**Query params:** `skip`, `limit` (max 1000), `search`, `email`

### Courses (`/api/courses`)
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/stats` | No | Dashboard statistics |
| GET | `/courses` | No | All courses with participants |
| GET | `/{id}/time-stats` | No | Time spent statistics |
| GET | `/{id}/participants` | No | Participants for a course |
| GET | `/participants/{id}` | No | Participant course details |
| GET | `/elearning/` | No | E-learning courses only |

### Sync (`/api/sync`)
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/last-sync` | No | Last sync status and stats |

### Health
| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Root - "API is running" |
| GET | `/health` | Health check endpoint |

## Authentication System

### Flow
1. Client sends `POST /api/auth/login` with `{ username, password }`
2. Server verifies credentials, returns `{ access_token, token_type: "bearer" }`
3. Client sends `Authorization: Bearer <token>` on subsequent requests
4. `get_current_user` dependency validates token and injects `User` object

### JWT Details
- Algorithm: HS256
- Token payload: `{ "sub": "<username>", "exp": <timestamp> }`
- Default expiration: 24 hours
- Secret key: `JWT_SECRET_KEY` env var

### Adding Protected Endpoints
```python
from app.auth.dependencies import get_current_user
from app.models.models import User

@router.get("/protected")
async def protected_route(current_user: User = Depends(get_current_user)):
    # current_user is the authenticated User ORM object
    return {"user": current_user.username}
```

Use `get_current_user_optional` when auth is optional (returns `None` if no token).

### Creating Users
```bash
python scripts/create_user.py <username> <password>
```

## Key Patterns

### Database Sessions
```python
from app.models.database import get_db

@router.get("/endpoint")
async def handler(db: Session = Depends(get_db)):
    result = db.query(Model).filter(...).first()
```

### Error Handling
```python
raise HTTPException(
    status_code=status.HTTP_404_NOT_FOUND,
    detail="Resource not found"
)
```

All auth errors return 401 with `WWW-Authenticate: Bearer` header.

### Caching (Redis)
```python
from app.services.cache_service import CacheService

cache = CacheService(settings.redis_url, settings.redis_enabled)

# Get/set with 5-minute TTL
cached = cache.get("key")
if not cached:
    data = expensive_query()
    cache.set("key", data, ttl=300)
```

Cache is optional and degrades gracefully if Redis is unavailable.

### Activity Status Logic
```python
if progression >= 100:     return "completed"
if no_last_activity:       return "not_started"
if days_since_activity <= 30: return "active"
else:                      return "inactive"
```

### Accent-Insensitive Search
The participant search generates multiple ILIKE patterns for French accented characters (e/é/è/ê, a/à/â, etc.) combined with OR conditions.

## Configuration

Settings are loaded via Pydantic in `config/settings.py`. Environment variables are read from `.env.dev` or `.env.prod` depending on `APP_ENV`.

### Required Environment Variables
| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | PostgreSQL connection string |
| `DENDREO_API_KEY` | Dendreo API key |
| `DENDREO_BASE_URL` | Dendreo API base URL |
| `JWT_SECRET_KEY` | Secret for JWT signing |

### Optional Environment Variables
| Variable | Default | Description |
|----------|---------|-------------|
| `APP_ENV` | `development` | Environment mode |
| `LOG_LEVEL` | `INFO` | Logging level |
| `REDIS_URL` | `redis://localhost:6379/0` | Redis connection |
| `REDIS_ENABLED` | `true` | Enable/disable caching |
| `HUBSPOT_API_KEY` | None | HubSpot integration |
| `JWT_ALGORITHM` | `HS256` | JWT algorithm |
| `JWT_EXPIRATION_HOURS` | `24` | Token expiration |
| `DENDREO_ADF_LIMIT` | `0` (no limit) | Limit ADFs per sync |
| `DENDREO_ENABLE_CLEANUP` | `true` | Enable sync cleanup |
| `SYNC_SCHEDULE` | `0 8 * * *` | Cron schedule for sync |
| `POSTGRES_TZ` | `Europe/Paris` | Database timezone |

## Docker Setup

Two production Dockerfiles:

- **Dockerfile.backend.prod** - API server (multi-stage, non-root user, health check)
- **Dockerfile.sync.prod** - Cron-based sync worker (daily at 8 AM by default)

Development uses `docker-compose.dev.yml` with hot-reload:
```bash
docker compose -f docker-compose.dev.yml up --build
```

Services: `backend`, `sync`, `frontend`, `postgres`, `portainer`

## Sync System

### Architecture

The sync system fetches data from the Dendreo API and populates the local database with participants, courses, modules, and enrollments.

**Components:**
- `dendreo_client.py` - HTTP client for Dendreo API endpoints
- `dendreo_sync.py` - Sync orchestration and business logic
- `scripts/sync_dendreo.py` - CLI wrapper for manual/scheduled execution

**Sync Flow (Chunked LAP-based approach):**
```
1. Fetch ADFs (Actions de Formation) → courses table
2. For each ADF with status 5 or 6:
   a. Fetch LAPs (Learning Activity Participants) → enrollments
   b. For each LAP:
      - Fetch LMPs (Learning Module Participants) → modules table
      - Create/update participant records
      - Create participant_course links
3. Clean up removed enrollments
4. Update HubSpot deal progressions (if enabled)
```

### Critical Field Names

The Dendreo API uses specific field names that must match exactly:

| Field | Usage | Notes |
|-------|-------|-------|
| `id_action_de_formation` | ADF identifier | ⚠️ Note the underscores! NOT `id_action_formation` |
| `id_etape_process` | ADF status | String type: '5' (active), '6' (active), others (inactive) |
| `id_lap` | LAP identifier | Links participant to ADF |
| `id_lmp` | LMP identifier | Links participant to module |
| `id_participant` | Participant ID | Unique learner identifier |
| `id_lam` | LAM identifier | Learning Activity Module grouping |

### Recent Fixes (2026-02-03)

#### 1. Fixed 70MB Timeout Issue
**Problem:** The original sync called `lmps.php` to fetch ALL LMPs at once, resulting in 70MB+ responses that timed out after 30 seconds.

**Solution:** Implemented chunked LAP-based sync approach:
- Fetch ADFs first (lightweight)
- For each ADF, fetch LAPs separately (small requests)
- For each LAP, fetch LMPs separately (small requests)
- This breaks one 70MB request into hundreds of <500KB requests

**Files changed:**
- `dendreo_sync.py:54-216` - New `sync_all()` method with chunked approach
- `dendreo_client.py:36` - Increased timeout from 30s to 120s as fallback

#### 2. Fixed Type Mismatch Bug
**Problem:** `id_etape_process` comparison failed because API returns integers but code compared against string list `['5', '6']`.

**Solution:** Added `str()` conversion:
```python
# Before (broken)
if id_etape_process not in ['5', '6']:

# After (fixed)
if str(id_etape_process) not in ['5', '6']:
```

**Files changed:**
- `dendreo_sync.py:100, 258, 324` - Added str() conversion

#### 3. Fixed Field Name Typo
**Problem:** LAP/LMP loop used wrong field name `id_action_formation` instead of `id_action_de_formation`, causing all ADFs to be skipped (returned `None`).

**Solution:** Corrected field name to match API response structure:
```python
# Before (broken)
id_adf = adf.get('id_action_formation')  # Returns None

# After (fixed)
id_adf = adf.get('id_action_de_formation')  # Correct field name
```

**Files changed:**
- `dendreo_sync.py:99` - Fixed field name in LAP/LMP processing loop

### Sync Status Filtering

Only ADFs with `id_etape_process` of `'5'` or `'6'` are processed (active courses). Other statuses are skipped during sync.

### Debugging Sync Issues

```bash
# Check sync logs
docker exec dendreo_sync_prod tail -100 /app/logs/sync.log

# Run manual sync with debug logging
docker exec dendreo_sync_prod python3 /app/scripts/sync_dendreo.py --force --log-level DEBUG

# Check database population
docker exec dendreo_postgres_prod psql -U postgres -d dendreo_prod_db -c "
  SELECT
    (SELECT COUNT(*) FROM courses) as courses,
    (SELECT COUNT(*) FROM participants) as participants,
    (SELECT COUNT(*) FROM modules) as modules,
    (SELECT COUNT(*) FROM participant_courses) as enrollments;
"

# Check sync metadata
docker exec dendreo_postgres_prod psql -U postgres -d dendreo_prod_db -c "
  SELECT last_sync_at, status, stats
  FROM sync_metadata
  ORDER BY last_sync_at DESC
  LIMIT 5;
"
```

## Adding a New API Endpoint

1. Add route function in appropriate file under `api/routes/`
2. If new schemas are needed, add them to `models/schemas.py` or `schemas/`
3. If new model fields are needed, update `models/models.py`
4. Register new routers in `main.py` if creating a new route file:
   ```python
   app.include_router(new_router, prefix="/api/new", tags=["new"])
   ```

## Timestamps & Timezone

- All timestamps stored in UTC: `DateTime(timezone=True)`
- Python: `datetime.now(timezone.utc)`
- PostgreSQL timezone: `Europe/Paris` (for display)
- API responses: ISO8601 format

## Development Commands

```bash
# Run dev server locally
python run.py

# Run via Docker
docker compose -f docker-compose.dev.yml up --build backend

# Create a user
python scripts/create_user.py admin mypassword

# Run sync manually
python scripts/sync_dendreo.py --log-level DEBUG

# Reset database (destructive!)
python reset_database.py --force
```

## Pending Work

- Password change endpoint (`PUT /api/auth/change-password`) - schemas ready, endpoint not yet implemented
- Account page integration with frontend
