import asyncio
import os
from dotenv import load_dotenv
from sqlalchemy.orm import Session
from app.models.database import get_db
from app.services.dendreo_client import DendreoClient
from app.services.dendreo_sync import DendreoSync
import logging

# Set up logging
logging.basicConfig(
    level=logging.DEBUG,  # Set to DEBUG level
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

async def test_adf_limit():
    """Test the ADF limit functionality"""
    load_dotenv()
    
    # Get database session
    db: Session = next(get_db())
    
    try:
        # Initialize services
        client = DendreoClient()
        sync_service = DendreoSync(db, client)
        
        # Log current limit setting
        limit = os.getenv('DENDREO_ADF_LIMIT', '0')
        logger.info(f"Testing with DENDREO_ADF_LIMIT={limit}")
        
        # Run sync
        logger.info("Starting sync...")
        result = await sync_service.sync_all()
        
        # Log results
        logger.info("Sync completed")
        logger.info(f"Status: {result['status']}")
        logger.info(f"Message: {result['message']}")
        logger.info("Stats:")
        for key, value in result['stats'].items():
            logger.info(f"  {key}: {value}")
            
    except Exception as e:
        logger.error(f"Error during test: {str(e)}")
        raise
    finally:
        db.close()

if __name__ == "__main__":
    asyncio.run(test_adf_limit()) 