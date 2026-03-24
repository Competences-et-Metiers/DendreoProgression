from sqlalchemy import create_engine, event, text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import QueuePool
import logging
import os
from contextlib import contextmanager
from typing import Generator
from app.config.settings import settings

logger = logging.getLogger(__name__)

def create_database_engine():
    """Create database engine with proper configuration based on environment."""
    
    database_url = settings.database_url
    
    # Base engine configuration
    engine_config = {
        'pool_pre_ping': True,  # Verify connections before use
        'pool_recycle': 3600,   # Recycle connections every hour
        'pool_timeout': 30,     # Connection timeout
        # Only enable SQL logging when explicitly needed for debugging
        'echo': os.getenv('SQLALCHEMY_ECHO', 'false').lower() == 'true',
        'echo_pool': os.getenv('SQLALCHEMY_ECHO_POOL', 'false').lower() == 'true',
    }
    
    # PostgreSQL specific configuration
    if database_url.startswith(('postgresql://', 'postgresql+psycopg2://')):
        # Use local timezone instead of forcing UTC
        timezone_setting = os.getenv('POSTGRES_TZ', 'Europe/Paris')
        engine_config.update({
            'connect_args': {
                'connect_timeout': 30,
                'options': f'-c timezone={timezone_setting} -c client_encoding=utf8',
            },
            'poolclass': QueuePool,
            'pool_size': 10 if settings.is_production else 5,
            'max_overflow': 20 if settings.is_production else 10,
        })
    
    try:
        engine = create_engine(database_url, **engine_config)
        
        # Test connection using text() for SQLAlchemy 2.0+ compatibility
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
            
        logger.info(f"✅ Database engine created successfully")
        if settings.is_development:
            db_name = database_url.split('/')[-1].split('?')[0]
            logger.info(f"Connected to database: {db_name}")
            
        return engine
        
    except Exception as e:
        logger.error(f"❌ Failed to create database engine: {e}")
        raise

# Create engine instance
engine = create_database_engine()

# Create session factory
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
    expire_on_commit=False  # Don't expire objects after commit
)

# Import models after engine creation to avoid circular imports
from app.models.models import Base

@contextmanager
def get_db_session() -> Generator:
    """Context manager for database sessions with proper cleanup."""
    session = SessionLocal()
    try:
        yield session
        session.commit()
    except Exception as e:
        session.rollback()
        logger.error(f"Database session error: {e}")
        raise
    finally:
        session.close()

def get_db():
    """Dependency function for FastAPI to get database session."""
    db = SessionLocal()
    try:
        yield db
    except Exception as e:
        db.rollback()
        logger.error(f"Database dependency error: {e}")
        raise
    finally:
        db.close()

def create_tables():
    """Create all database tables with proper error handling."""
    try:
        # Import all models to ensure they're registered
        from app.models.models import Participant, Course, Module, ParticipantCourse, ParticipantHubspotData, SyncMetadata, User, Creneau, CreneauParticipant, ModuleCategory, Intervention, UserView

        logger.info("Creating database tables...")

        # Create tables
        Base.metadata.create_all(bind=engine)

        # Safe migration: add new columns to existing tables
        with engine.connect() as conn:
            try:
                conn.execute(text("ALTER TABLE courses ADD COLUMN IF NOT EXISTS categorie_module_id VARCHAR"))
                conn.commit()
                logger.info("Ensured courses.categorie_module_id column exists")
            except Exception as e:
                logger.debug(f"Column migration note: {e}")

        with engine.connect() as conn:
            try:
                conn.execute(text(
                    "ALTER TABLE participant_hubspot_data "
                    "ADD COLUMN IF NOT EXISTS is_manual_link BOOLEAN NOT NULL DEFAULT FALSE"
                ))
                conn.commit()
                logger.info("Ensured participant_hubspot_data.is_manual_link column exists")
            except Exception as e:
                logger.debug(f"Column migration note: {e}")
        
        # Verify tables were created using text() for SQLAlchemy 2.0+ compatibility
        with engine.connect() as conn:
            result = conn.execute(
                text("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'")
            )
            tables = [row[0] for row in result]
            
        logger.info(f"✅ Database tables created successfully: {', '.join(tables)}")
        
    except Exception as e:
        logger.error(f"❌ Error creating database tables: {e}")
        logger.error(f"Database URL: {settings.database_url.split('@')[0]}@...")
        raise

def check_database_health() -> bool:
    """Check if database is healthy and accessible."""
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return True
    except Exception as e:
        logger.error(f"Database health check failed: {e}")
        return False

# Add connection event listeners for better debugging in development
if settings.is_development:
    @event.listens_for(engine, "connect")
    def connect_handler(dbapi_connection, connection_record):
        logger.debug("Database connection established")

    @event.listens_for(engine, "checkout")
    def checkout_handler(dbapi_connection, connection_record, connection_proxy):
        logger.debug("Database connection checked out from pool")

    @event.listens_for(engine, "checkin")
    def checkin_handler(dbapi_connection, connection_record):
        logger.debug("Database connection returned to pool")
