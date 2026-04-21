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
| PUT | `/change-password` | Yes | Change user password |

### Participants (`/api/participants`)
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/` | No | List with pagination, search, filters |
| GET | `/count` | No | Total participant count |
| GET | `/{id}` | No | Single participant with courses |
| GET | `/email/{email}` | No | Lookup by email |
| GET | `/inactive` | No | Inactive participants tracking |

**Query params:**
- List: `skip`, `limit` (max 1000), `search`, `email`
- Inactive: `group_by_course`, `course_id`, `min_progression`, `max_progression`, `inactivity_threshold_days`, `exclude_recent_enrollments_days`

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

**CRITICAL: Detached instance pitfall with `get_db_session()`**

`get_db_session()` is a context manager that closes the session on exit. Objects created in one session become **detached** — modifying them in a new session is silently a no-op.

```python
# WRONG - status update is silently lost
with get_db_session() as db:
    record = SyncMetadata(status='in_progress')
    db.add(record)
    db.commit()

with get_db_session() as db:
    record.status = 'success'  # Modifies detached Python object only
    db.commit()                # New session doesn't know about `record`

# CORRECT - re-fetch by ID in the new session
with get_db_session() as db:
    record = SyncMetadata(status='in_progress')
    db.add(record)
    db.commit()
    record_id = record.id

with get_db_session() as db:
    record = db.query(SyncMetadata).get(record_id)
    record.status = 'success'  # Now tracked by this session
    db.commit()                # Persisted correctly
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

**Sync container environment:** Cron jobs don't inherit Docker env vars. The entrypoint generates `/app/cron_env.sh` at startup with all required vars. When adding a new required env var to `settings.py`, it must also be added to:
1. `Dockerfile.sync.prod` — the `cron_env.sh` heredoc in the entrypoint
2. `Dockerfile.sync.prod` — the embedded `sync_wrapper.sh`
3. `docker-compose.prod.yml` — the sync service `environment` section

**Sync wrapper exit codes:** `sync_wrapper_prod.sh` uses distinct exit codes for the pre-sync check: `0` = should run, `2` = skip (recent sync), any other = check failed (falls back to running sync). This prevents config errors from being silently misinterpreted as "recent sync found".

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

#### 4. Implemented API Rate Limiting
**Problem:** Dendreo API enforces a rate limit of 100 requests per 10 seconds. The chunked sync approach makes hundreds of requests (1 for ADFs + N for LAPs + M for LMPs), which can easily exceed this limit and trigger warnings or throttling.

**Solution:** Implemented automatic rate limiting in `DendreoClient`:
- Tracks all request timestamps in a sliding 10-second window
- Automatically waits when approaching the 100 requests/10s limit
- Defaults to 90 requests per 10 seconds (configurable) to leave headroom for third-party services sharing the API quota
- Logs progress every 50 requests and warnings when rate limiting activates

**Configuration (environment variables):**
```bash
DENDREO_RATE_LIMIT_REQUESTS=90    # Max requests per window (default: 90, Dendreo limit is 100)
DENDREO_RATE_LIMIT_WINDOW=10      # Time window in seconds (default: 10)
```

**Why 90 instead of 100:** Other third-party services (CRM integrations, etc.) may also consume the same Dendreo API quota concurrently. The 10-request buffer prevents rate limit violations.

**How it works:**
1. Before each API request, the client checks timestamps of recent requests
2. If 90+ requests were made in the last 10 seconds, it waits until the oldest request expires
3. The sync logs show: `⏳ Rate limit reached (90/90 requests in 10s). Waiting 2.3s...`
4. After sync completes, rate limiting statistics are logged

**Files changed:**
- `dendreo_client.py:14-38` - Added rate limiting configuration and tracking
- `dendreo_client.py:40-65` - Added `_wait_for_rate_limit()` method
- `dendreo_client.py:67-103` - Updated `_make_request()` to use rate limiting
- `dendreo_client.py:119-137` - Added `get_rate_limit_stats()` and `reset_rate_limit_stats()` methods
- `dendreo_sync.py:57-59` - Reset rate limit stats at start of sync
- `dendreo_sync.py:273-276` - Log rate limit stats at end of sync

**Example logs:**
```
🔄 Rate limiting statistics reset
📊 API requests: 50 total, 50 in last 10s
📊 API requests: 100 total, 90 in last 10s
⏳ Rate limit reached (90/90 requests in 10s). Waiting 2.1s...
📊 API requests: 150 total, 89 in last 10s
🚦 Rate Limiting Stats: {'total_requests': 523, 'requests_in_current_window': 47, 'rate_limit': '90 requests per 10s', 'percentage_of_limit': '52.2%'}
```

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

## Inactivity Tracking System

### Overview

The inactivity tracking system identifies participants who have stopped making progression in their courses. It's designed for the "Gestion des inactifs" (Inactive Management) frontend page.

**Key Principles:**
- Inactivity is based on **progression changes**, not login/connection events
- Results are **grouped by ADF** (Action de Formation) to avoid duplicate entries
- Each participant appears **once per ADF**, with aggregated metrics across all LAMs (modules)

### Architecture

**Components:**
- `inactivity_service.py` - Core business logic for inactivity calculation and ADF grouping
- `routes/participants.py` - `/inactive` endpoint
- `schemas.py` - Response models (`InactivitySummary`, `InactiveParticipantDetail`, etc.)

**Data Aggregation:**
When a participant is enrolled in an ADF with multiple LAMs, the system:
1. Groups all LAM enrollments by `(participant_id, id_action_formation)`
2. Calculates aggregated metrics:
   - **Average progression** across all LAMs
   - **Total modules** count (number of LAMs)
   - **Total planned duration** (sum of all LAM durations in hours)
   - **Total time spent** (sum of actual time across all modules in hours)
   - **Most recent activity** (latest `last_activity` across all LAMs)
   - **Earliest enrollment date** (oldest `created_at` across all LAMs)

### Inactivity Classification

Participants are classified into distinct categories based on days without progression updates:

| Status | Condition | Default Threshold | Description |
|--------|-----------|-------------------|-------------|
| `active` | < threshold days inactive | `inactivity_threshold_days` | Recent progression activity |
| `inactive` | >= threshold days inactive | `inactivity_threshold_days` | Inactive - needs attention |
| `never_started` | 0% progression, never active | - | Enrolled but never began |

### Exclusion Logic

The system automatically excludes:

1. **Newly enrolled participants** - < 7 days since enrollment (configurable)
2. **Completed courses** - progression >= 100%
3. **Participants without activity data** - no `last_activity` timestamp

**Rationale:** Recent enrollments need time to start, and completed participants aren't inactive.

### API Endpoint

**GET** `/api/participants/inactive`

#### Query Parameters

| Parameter | Type | Default | Range | Description |
|-----------|------|---------|-------|-------------|
| `group_by_course` | boolean | `false` | - | Group results by course |
| `course_id` | int | `null` | - | Filter to specific course |
| `min_progression` | float | `null` | 0-100 | Minimum progression % |
| `max_progression` | float | `null` | 0-100 | Maximum progression % |
| `inactivity_threshold_days` | int | `30` | 1-365 | Days for "inactive" status |
| `exclude_recent_enrollments_days` | int | `7` | 0-90 | Exclude enrollments newer than X days |

#### Response Format

**Flat list** (when `group_by_course=false`):
```json
{
  "total_participants_checked": 1450,
  "total_participants": 1450,
  "active_count": 1200,
  "inactive_count": 200,
  "never_started_count": 50,
  "newly_enrolled_excluded": 23,
  "participants": [
    {
      "id": 123,
      "id_participant": "P456",
      "nom": "Dupont",
      "prenom": "Marie",
      "email": "marie.dupont@example.com",
      "course_id": 42,
      "course_title": "Formation Python Avancé",
      "id_action_formation": "ADF789",
      "total_modules": 5,
      "total_planned_duration_hours": 150.0,
      "total_time_spent_hours": 45.5,
      "current_progression": 45.5,
      "last_activity": "2025-12-15T10:30:00Z",
      "days_inactive": 65,
      "enrollment_date": "2025-10-01T08:00:00Z",
      "days_since_enrollment": 125,
      "inactivity_status": "inactive",
      "inactivity_reason": "No progression update for 65 days"
    }
  ],
  "inactivity_threshold_days": 30,
  "exclude_recent_enrollments_days": 7
}
```

**Grouped by course** (when `group_by_course=true`):
```json
{
  "total_participants_checked": 1450,
  "total_participants": 1450,
  "active_count": 1200,
  "inactive_count": 200,
  "never_started_count": 50,
  "by_course": [
    {
      "course_id": 42,
      "course_title": "Formation Python Avancé",
      "id_action_formation": "ADF789",
      "total_participants": 30,
      "active_count": 15,
      "inactive_count": 13,
      "never_started_count": 2,
      "participants": [/* array of InactiveParticipantDetail */]
    }
  ]
}
```

### Usage Examples

#### Get all inactive participants (flat list)
```bash
curl http://localhost:8000/api/participants/inactive
```

#### Get inactive participants grouped by course
```bash
curl "http://localhost:8000/api/participants/inactive?group_by_course=true"
```

#### Get inactive participants in specific course
```bash
curl "http://localhost:8000/api/participants/inactive?course_id=42&inactivity_threshold_days=30"
```

#### Filter by progression range
```bash
# Find participants stuck at 20-50% progression
curl "http://localhost:8000/api/participants/inactive?min_progression=20&max_progression=50"
```

### Frontend Integration

For the "Gestion des inactifs" page:

```typescript
// Fetch inactive participants grouped by course
const response = await fetch('/api/participants/inactive?group_by_course=true');
const data = await response.json();

// Display courses sorted by most inactive first
data.by_course.forEach(course => {
  console.log(`${course.course_title}: ${course.inactive_count} inactive`);

  // Show participants sorted by days_inactive (already sorted)
  course.participants.forEach(p => {
    console.log(`  ${p.nom} ${p.prenom}: ${p.days_inactive} days, ${p.current_progression}%`);
  });
});
```

### Implementation Notes

1. **ADF-level grouping** - Participants appear once per ADF (not per LAM) to avoid duplicate entries
2. **Aggregated metrics** - Progression, duration, and time spent are computed across all LAMs within an ADF
3. **Progression-based tracking** - Uses `ParticipantCourse.last_activity` timestamp (updated when progression changes)
4. **No login tracking** - Deliberately avoids connection/session data
5. **Rolling time windows** - Configurable thresholds for different intervention levels
6. **Sorted output** - Participants sorted by `days_inactive` DESC (most inactive first)
7. **Course-grouped option** - Useful for ADF-specific interventions
8. **Explainable** - Each participant includes `inactivity_reason` explaining why they're flagged
9. **Rate-limit friendly** - Frontend can cache results and avoid excessive API calls
10. **Module-level time tracking** - Queries `Module` table to sum actual time spent across all e-learning modules

### Configuration

Thresholds can be customized per request or set as defaults in the service:

```python
# Default configuration in InactivityService
service = InactivityService(
    db=db,
    inactivity_threshold_days=30,      # Inactivity threshold
    exclude_recent_enrollments_days=7, # Exclude new enrollments
)
```

### Future Enhancements

Potential additions (not yet implemented):
- Historical progression tracking for trend analysis
- Automated intervention triggers (email notifications, reminders)
- Progression velocity calculation (rate of change)
- Comparative analysis (peer progression benchmarks)

## Adding a New API Endpoint

1. Add route function in appropriate file under `api/routes/`
2. If new schemas are needed, add them to `models/schemas.py` or `schemas/`
3. If new model fields are needed, update `models/models.py`
4. Register new routers in `main.py` if creating a new route file:
   ```python
   app.include_router(new_router, prefix="/api/new", tags=["new"])
   ```

### Important: Route Ordering in FastAPI

**CRITICAL:** In FastAPI, route order matters. Specific routes must be defined BEFORE parameterized routes.

**Example from participants.py:**
```python
# Correct order ✅
@router.get("/count")          # Specific route
@router.get("/inactive")       # Specific route
@router.get("/{participant_id}") # Parameterized route - MUST come last
@router.get("/email/{email}")  # Different parameter name - OK after

# Wrong order ❌
@router.get("/{participant_id}") # This will match EVERYTHING
@router.get("/inactive")         # Never reached - "inactive" matches as participant_id
```

**Why:** FastAPI matches routes in order. A parameterized route like `/{participant_id}` will match ANY string, including "inactive" or "count". Always define specific string routes before parameterized ones.

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

- Test sync with fixed field name (`id_action_de_formation`) to populate participants/modules

## Recently Completed (2026-02-09)

- Fixed sync status permanently stuck on "in_progress" (SQLAlchemy detached instance bug in `sync_dendreo.py`)
- Added `JWT_SECRET_KEY` to sync container's `cron_env.sh` and embedded `sync_wrapper.sh` in `Dockerfile.sync.prod`
- Fixed `sync_wrapper_prod.sh` to use distinct exit codes (0=run, 2=skip, other=error+fallback)
- Lowered default API rate limit from 95 to 90 req/10s to leave headroom for third-party services

## Recently Completed (2026-02-04)

- ✅ Account page with password change functionality
- ✅ Backend API endpoint `PUT /api/auth/change-password` with validation
- ✅ Password visibility toggles and client-side validation
- ✅ French translations for account management

## Recently Completed (2026-02-03)

- ✅ Inactivity tracking system with progression-based classification
- ✅ Course grouping for inactive participants
- ✅ Configurable thresholds for intervention levels
- ✅ API endpoint `/api/participants/inactive` with comprehensive filters
- ✅ API rate limiting to comply with Dendreo's 100 req/10s limit
- ✅ FastAPI route ordering fix for `/inactive` endpoint (must be before `/{participant_id}`)
- ✅ Added `backups/` to .gitignore (prevents committing sensitive credentials)

## Deployment Backups

### Automatic Backups

The `deploy-prod.sh` script automatically creates timestamped backups before each deployment in the `backups/` directory.

**Backup Structure:**
```
backups/
└── YYYYMMDD_HHMMSS/
    ├── env_backup              # Copy of .env.prod (credentials, API keys)
    ├── database_backup.sql     # PostgreSQL dump (if DB is running)
    └── logs_backup/            # Application logs
        ├── sync_YYYYMMDD.log
        ├── sync_status.json
        └── nginx/
            ├── access.log
            └── error.log
```

**Important Notes:**
- Backups are **NOT committed to git** (in `.gitignore`)
- Contains sensitive data (passwords, API keys, tokens)
- Useful for disaster recovery and deployment rollback
- Created automatically on every `./deploy-prod.sh` run
- Physical files remain on disk even after git ignores them

**Restoration:**
```bash
# Restore environment configuration
cp backups/20260203_121237/env_backup .env.prod

# Restore database (if needed)
docker compose -f docker-compose.prod.yml exec -T postgres \
  psql -U postgres dendreo_prod_db < backups/20260203_121237/database_backup.sql
```

**Cleanup old backups:**
```bash
# Remove backups older than 7 days
find backups/ -type d -mtime +7 -exec rm -rf {} +
```
