from sqlalchemy import create_engine, text
from app.models.database import get_database_url
from app.models.models import Base
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def reset_database():
    """Drop all tables and recreate them"""

    # Get database URL
    database_url = get_database_url()
    engine = create_engine(database_url)

    try:
        # Connect to database
        with engine.connect() as connection:
            # Start a transaction
            trans = connection.begin()

            try:
                logger.info("Dropping all tables with CASCADE...")

                # Get all table names first
                result = connection.execute(text("""
                                                 SELECT tablename FROM pg_tables
                                                 WHERE schemaname = 'public'
                                                   AND tablename NOT LIKE 'pg_%'
                                                   AND tablename != 'information_schema'
                                                 """))

                tables = [row[0] for row in result.fetchall()]
                logger.info(f"Found tables to drop: {tables}")

                # Drop each table with CASCADE
                for table in tables:
                    logger.info(f"Dropping table: {table}")
                    connection.execute(text(f"DROP TABLE IF EXISTS {table} CASCADE"))

                # Commit the drops
                trans.commit()
                logger.info("All tables dropped successfully")

            except Exception as e:
                trans.rollback()
                logger.error(f"Error during table drops: {e}")
                raise

        # Recreate all tables
        logger.info("Creating all tables...")
        Base.metadata.create_all(bind=engine)
        logger.info("All tables created successfully")

        # Verify tables were created
        with engine.connect() as connection:
            result = connection.execute(text("""
                                             SELECT tablename FROM pg_tables
                                             WHERE schemaname = 'public'
                                             ORDER BY tablename
                                             """))

            tables = [row[0] for row in result.fetchall()]
            logger.info(f"Created tables: {tables}")

        logger.info("Database reset completed successfully!")

    except Exception as e:
        logger.error(f"Error resetting database: {e}")
        raise
    finally:
        engine.dispose()

if __name__ == "__main__":
    reset_database()
