from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
import os

# Create logs directory if it doesn't exist
os.makedirs("logs", exist_ok=True)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),  # This sends logs to console
        logging.FileHandler('logs/app.log')  # This saves logs to a file in the logs directory
    ]
)

# Set specific logger levels
logging.getLogger("app").setLevel(logging.INFO)
logging.getLogger("uvicorn").setLevel(logging.INFO)

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
from app.api.routes import participants, courses, sync

app.include_router(participants.router, prefix="/api/participants", tags=["participants"])
app.include_router(courses.router, prefix="/api/courses", tags=["courses"])
app.include_router(sync.router, prefix="/api/sync", tags=["sync"])

@app.get("/")
async def root():
    return {"message": "Dendreo Progression API is running"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
