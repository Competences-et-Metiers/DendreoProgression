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
            # Production runs multiple uvicorn workers (UVICORN_WORKERS, default 2), and
            # each worker process gets its OWN pool. These are sized per-worker so the
            # total stays within Postgres' default max_connections=100 alongside the
            # sync container: 2 workers x (5 + 10) = 30 connections max.
            'pool_size': int(os.getenv('DB_POOL_SIZE', '5')),
            'max_overflow': int(os.getenv('DB_MAX_OVERFLOW', '10')),
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

# Indexes backing the hot read paths (inactivity list, ADF list, course/participant
# detail). Entries are (index_name, table, column_list), using the same idx_<table>_<col>
# convention as database/init/01-init.sql — which already covers modules(participant_id),
# modules(course_id), courses(id_action_formation), courses(id_lam),
# participant_courses(participant_id|course_id) and participant_hubspot_data(participant_id).
# Only the genuinely missing ones are listed here.
PERFORMANCE_INDEXES = [
    # modules.id_lam drives every `Module.id_lam IN (...)` lookup and the
    # Module.id_lam == Course.id_lam join; the composite serves the very common
    # `participant_id == X AND id_lam IN (...)` pattern in one index.
    ("idx_modules_id_lam", "modules", "id_lam"),
    ("idx_modules_participant_id_lam", "modules", "participant_id, id_lam"),

    # Active-ADF filter: status IN ('5','6','7').
    ("idx_courses_status", "courses", "status"),

    # Liveroom (classe virtuelle) tables had no non-unique indexes at all, despite
    # being joined on every inactivity/course/participant query.
    ("idx_creneaux_id_action_formation", "creneaux", "id_action_formation"),
    ("idx_creneaux_id_lam", "creneaux", "id_lam"),
    ("idx_creneaux_date_debut", "creneaux", "date_debut"),
    ("idx_creneaux_date_fin", "creneaux", "date_fin"),
    ("idx_creneau_participants_creneau_id", "creneau_participants", "creneau_id"),
    ("idx_creneau_participants_participant_id", "creneau_participants", "participant_id"),

    # EDOF/deal lookups filter by ADF alone; the existing unique constraint leads
    # with participant_id, so it can't serve this.
    ("idx_participant_hubspot_data_id_action_formation", "participant_hubspot_data", "id_action_formation"),
]


def create_indexes(conn_factory=None):
    """Create performance indexes if an equivalent one doesn't already exist.

    Safe to run on every startup. Beyond CREATE INDEX IF NOT EXISTS (which only
    matches on name), this skips any index whose leading columns are already
    covered by an existing index under a different name, so it can't create
    duplicates alongside the idx_* indexes from database/init/01-init.sql.
    """
    target_engine = conn_factory if conn_factory is not None else engine

    # Map table -> set of leading-column-lists already indexed, e.g. {"modules": {"participant_id", ...}}
    existing: dict = {}
    try:
        with target_engine.connect() as conn:
            rows = conn.execute(text("""
                SELECT t.relname AS table_name,
                       string_agg(a.attname, ', ' ORDER BY k.ord) AS cols
                FROM pg_index i
                JOIN pg_class t ON t.oid = i.indrelid
                JOIN pg_namespace n ON n.oid = t.relnamespace
                JOIN LATERAL unnest(i.indkey) WITH ORDINALITY AS k(attnum, ord) ON TRUE
                JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = k.attnum
                WHERE n.nspname = 'public'
                GROUP BY i.indexrelid, t.relname
            """)).fetchall()
        for table_name, cols in rows:
            existing.setdefault(table_name, set()).add(cols)
    except Exception as e:
        logger.debug(f"Could not introspect existing indexes, falling back to name check: {e}")

    created = skipped = 0
    for index_name, table, columns in PERFORMANCE_INDEXES:
        normalized = ", ".join(c.strip() for c in columns.split(","))
        table_indexes = existing.get(table, set())
        # Skip when an existing index already leads with exactly these columns.
        if normalized in table_indexes:
            skipped += 1
            continue
        try:
            with target_engine.connect() as conn:
                conn.execute(text(
                    f"CREATE INDEX IF NOT EXISTS {index_name} ON {table} ({columns})"
                ))
                conn.commit()
            created += 1
            logger.info(f"✅ Created index {index_name} on {table}({columns})")
        except Exception as e:
            logger.warning(f"⚠️  Could not create index {index_name}: {e}")

    logger.info(
        f"Performance indexes: {created} created, {skipped} already covered "
        f"({len(PERFORMANCE_INDEXES)} total)"
    )


def create_tables():
    """Create all database tables with proper error handling."""
    try:
        # Import all models to ensure they're registered
        from app.models.models import Participant, Course, Module, ParticipantCourse, ParticipantHubspotData, SyncMetadata, User, Creneau, CreneauParticipant, ModuleCategory, Intervention, UserView, ActionHistory

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

        with engine.connect() as conn:
            try:
                conn.execute(text(
                    "ALTER TABLE participant_hubspot_data "
                    "ADD COLUMN IF NOT EXISTS edof_date_debut VARCHAR"
                ))
                conn.execute(text(
                    "ALTER TABLE participant_hubspot_data "
                    "ADD COLUMN IF NOT EXISTS edof_date_fin VARCHAR"
                ))
                conn.commit()
                logger.info("Ensured participant_hubspot_data.edof_date_debut/edof_date_fin columns exist")
            except Exception as e:
                logger.debug(f"Column migration note: {e}")

        with engine.connect() as conn:
            try:
                for col, sql_type in (
                    ("deal_amount", "DOUBLE PRECISION"),
                    ("deal_type_financement", "VARCHAR"),
                    ("deal_montant_pec", "DOUBLE PRECISION"),
                    ("deal_montant_rac", "DOUBLE PRECISION"),
                    ("deal_facturation", "VARCHAR"),
                    ("deal_facturation_synced_at", "TIMESTAMPTZ"),
                ):
                    conn.execute(text(
                        f"ALTER TABLE participant_hubspot_data ADD COLUMN IF NOT EXISTS {col} {sql_type}"
                    ))
                conn.commit()
                logger.info("Ensured participant_hubspot_data deal financial columns exist")
            except Exception as e:
                logger.debug(f"Column migration note: {e}")

        with engine.connect() as conn:
            try:
                conn.execute(text(
                    "ALTER TABLE users "
                    "ADD COLUMN IF NOT EXISTS role_source VARCHAR(20) NOT NULL DEFAULT 'group'"
                ))
                conn.commit()
                logger.info("Ensured users.role_source column exists")
            except Exception as e:
                logger.debug(f"Column migration note: {e}")

        with engine.connect() as conn:
            try:
                conn.execute(text("ALTER TABLE participants ADD COLUMN IF NOT EXISTS edof_sessions JSON"))
                conn.commit()
                logger.info("Ensured participants.edof_sessions column exists")
            except Exception as e:
                logger.debug(f"Column migration note: {e}")

        with engine.connect() as conn:
            try:
                conn.execute(text("ALTER TABLE courses ADD COLUMN IF NOT EXISTS date_debut TIMESTAMPTZ"))
                conn.execute(text("ALTER TABLE courses ADD COLUMN IF NOT EXISTS date_fin TIMESTAMPTZ"))
                conn.commit()
                logger.info("Ensured courses.date_debut and courses.date_fin columns exist")
            except Exception as e:
                logger.debug(f"Column migration note: {e}")

        with engine.connect() as conn:
            try:
                conn.execute(text(
                    "ALTER TABLE user_views "
                    "ADD COLUMN IF NOT EXISTS page VARCHAR(50) NOT NULL DEFAULT 'inactive'"
                ))
                conn.execute(text(
                    "CREATE INDEX IF NOT EXISTS ix_user_views_page ON user_views (page)"
                ))
                conn.commit()
                logger.info("Ensured user_views.page column exists")
            except Exception as e:
                logger.debug(f"Column migration note: {e}")

        with engine.connect() as conn:
            try:
                conn.execute(text("ALTER TABLE sync_metadata ADD COLUMN IF NOT EXISTS log_path VARCHAR"))
                conn.commit()
                logger.info("Ensured sync_metadata.log_path column exists")
            except Exception as e:
                logger.debug(f"Column migration note: {e}")

        # Performance indexes for the read-heavy API endpoints.
        # Postgres does NOT auto-index foreign keys, so every join/filter below was
        # doing a sequential scan. Names match SQLAlchemy's `index=True` convention
        # (ix_<table>_<column>) so create_all() and this migration stay idempotent.
        create_indexes(conn_factory=engine)

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
