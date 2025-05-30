import os
from sqlalchemy import create_engine, text
from app.models.models import Base
import logging
from dotenv import load_dotenv
import psycopg2

# Load environment variables
load_dotenv()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def main():
    try:
        # Get database parameters
        host = os.getenv('DB_HOST', 'localhost')
        port = os.getenv('DB_PORT', '5432')
        database = os.getenv('DB_NAME', 'dendreo_db')
        user = os.getenv('DB_USER', 'postgres')
        password = os.getenv('DB_PASSWORD', 'admin')

        # Debug: print out the values (masking password)
        logger.info("Database connection parameters:")
        logger.info(f"Host: {host}")
        logger.info(f"Port: {port}")
        logger.info(f"Database: {database}")
        logger.info(f"User: {user}")
        logger.info("Password: ****")

        # Debug: print raw bytes of each parameter
        logger.info("Raw parameter bytes:")
        logger.info(f"Host bytes: {host.encode('latin1')}")
        logger.info(f"Database bytes: {database.encode('latin1')}")
        logger.info(f"User bytes: {user.encode('latin1')}")

        logger.info("Connecting to database...")

        # Try connecting with psycopg2 directly first
        logger.info("Testing direct psycopg2 connection...")
        test_conn = psycopg2.connect(
            host=host,
            port=port,
            dbname=database,
            user=user,
            password=password,
            client_encoding='utf8'
        )
        test_conn.close()
        logger.info("Direct psycopg2 connection successful!")

        # Create engine using psycopg2 parameters
        engine = create_engine(
            'postgresql+psycopg2://',
            creator=lambda: psycopg2.connect(
                host=host,
                port=port,
                dbname=database,
                user=user,
                password=password,
                client_encoding='utf8'
            )
        )

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
                SELECT tablename 
                FROM pg_tables 
                WHERE schemaname = 'public'
                ORDER BY tablename
            """))
            tables = [row[0] for row in result.fetchall()]
            logger.info(f"Created tables: {tables}")

        logger.info("Database tables created successfully!")
        engine.dispose()

    except Exception as e:
        logger.error(f"Error creating tables: {str(e)}")
        logger.error(f"Error type: {type(e)}")
        logger.error(f"Full error details: {repr(e)}")
        raise

if __name__ == "__main__":
    main()
