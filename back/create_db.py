import os
from sqlalchemy import create_engine, text
from app.models.models import Base
import logging
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def main():
    try:
        # Use your exact DATABASE_URL from .env
        database_url = os.getenv('DATABASE_URL')
        logger.info(f"Connecting to: {database_url}")
        logger.info("Creating database tables...")

        engine = create_engine(database_url)

        # Test connection first
        with engine.connect() as connection:
            logger.info("Database connection successful!")

        # Drop existing tables if they exist (to ensure clean state)
        logger.info("Dropping existing tables if they exist...")
        with engine.connect() as connection:
            connection.execute(text("DROP TABLE IF EXISTS participant_courses CASCADE"))
            connection.execute(text("DROP TABLE IF EXISTS participants CASCADE"))
            connection.execute(text("DROP TABLE IF EXISTS courses CASCADE"))
            connection.commit()
            logger.info("Existing tables dropped")

        # Create all tables
        logger.info("Creating new tables...")
        Base.metadata.create_all(bind=engine)

        # Verify tables were created
        with engine.connect() as connection:
            result = connection.execute(text("""
                                             SELECT tablename FROM pg_tables
                                             WHERE schemaname = 'public'
                                             ORDER BY tablename
                                             """))

            tables = [row[0] for row in result.fetchall()]
            logger.info(f"Created tables: {tables}")

        logger.info("Database tables created successfully!")
        engine.dispose()

    except Exception as e:
        logger.error(f"Error creating tables: {e}")
        raise

if __name__ == "__main__":
    main()
