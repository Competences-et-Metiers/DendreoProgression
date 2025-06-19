from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import logging
from app.config.settings import settings

logger = logging.getLogger(__name__)

# Use the DATABASE_URL from settings
DATABASE_URL = settings.database_url

# Create engine with the URL from settings
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

from app.models.models import Base

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def create_tables():
    """Create all database tables"""
    try:
        # Import all models that inherit from Base
        from app.models.models import Participant, Course, Module, ParticipantCourse
        
        logger.info("Creating database tables...")
        Base.metadata.create_all(bind=engine)
        logger.info("Database tables created successfully")
    except Exception as e:
        logger.error(f"Error creating database tables: {e}")
        raise
