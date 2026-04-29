from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
from logging.handlers import TimedRotatingFileHandler
import os

# Create logs directory if it doesn't exist
os.makedirs("logs", exist_ok=True)

# Configure logging - console and rotating file output (with fallback)
handlers = [logging.StreamHandler()]  # Console logging

# Try to add file logging, but fall back gracefully if permissions fail.
# Rotate at midnight, keep 30 days of history. Old files are auto-deleted.
try:
    file_handler = TimedRotatingFileHandler(
        'logs/app.log',
        when='midnight',
        interval=1,
        backupCount=30,
        encoding='utf-8',
        utc=False,
    )
    file_handler.suffix = '%Y-%m-%d'
    handlers.append(file_handler)
    print("✅ File logging enabled: logs/app.log (daily rotation, 30-day retention)")
except (PermissionError, OSError) as e:
    print(f"⚠️  File logging disabled due to permission error: {e}")
    print("📄 Using console logging only")

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=handlers
)

# Set specific logger levels
logging.getLogger("app").setLevel(logging.INFO)
logging.getLogger("uvicorn").setLevel(logging.INFO)

# Silence noisy loggers that cause infinite loops (keep these silenced!)
logging.getLogger('watchfiles').setLevel(logging.ERROR)
logging.getLogger('watchfiles.main').setLevel(logging.ERROR)

# Silence SQLAlchemy database logs to reduce terminal noise
logging.getLogger('sqlalchemy.engine.Engine').setLevel(logging.WARNING)
logging.getLogger('sqlalchemy.pool').setLevel(logging.WARNING)
logging.getLogger('sqlalchemy.orm').setLevel(logging.WARNING)
logging.getLogger('sqlalchemy.dialects').setLevel(logging.WARNING)
logging.getLogger('sqlalchemy.engine').setLevel(logging.WARNING)
logging.getLogger('sqlalchemy').setLevel(logging.WARNING)

app = FastAPI(title="Dendreo Progression API", version="1.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
from app.api.routes import participants, courses, sync, auth, hubspot, admin, interventions, views

app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(participants.router, prefix="/api/participants", tags=["participants"])
app.include_router(courses.router, prefix="/api/courses", tags=["courses"])
app.include_router(sync.router, prefix="/api/sync", tags=["sync"])
app.include_router(hubspot.router, prefix="/api/hubspot", tags=["hubspot"])
app.include_router(admin.router, prefix="/api/admin", tags=["admin"])
app.include_router(interventions.router, prefix="/api/interventions", tags=["interventions"])
app.include_router(views.router, prefix="/api/views", tags=["views"])

@app.on_event("startup")
async def _prune_old_sync_logs():
    """Best-effort cleanup of per-sync log files older than 90 days. Runs at most
    once per backend startup; the sync container also runs this nightly via cron."""
    try:
        from app.services.sync_logs import cleanup_old_sync_logs
        removed = cleanup_old_sync_logs(retention_days=90)
        if removed:
            logging.getLogger(__name__).info(f"Pruned {removed} sync log file(s) older than 90 days")
    except Exception as e:
        logging.getLogger(__name__).warning(f"Sync-log cleanup failed: {e}")


@app.get("/")
async def root():
    return {"message": "Dendreo Progression API is running"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
