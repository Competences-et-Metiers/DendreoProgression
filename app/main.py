import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config.settings import settings
from app.models.database import create_tables
from app.api.routes import courses, participants, sync

# Configure logging
logging.basicConfig(
    level=getattr(logging, settings.log_level.upper()),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)

app = FastAPI(
    title=settings.app_name,
    version=settings.version,
    description="Internal API for Dendreo e-learning progression tracking"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(courses.router, prefix="/api/v1")
app.include_router(participants.router, prefix="/api/v1")
app.include_router(sync.router, prefix="/api/v1")

@app.on_event("startup")
async def startup_event():
    """Create database tables on startup"""
    create_tables()

@app.get("/")
async def root():
    return {"message": f"Welcome to {settings.app_name}"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "version": settings.version}
