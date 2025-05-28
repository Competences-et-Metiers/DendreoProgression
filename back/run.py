import uvicorn
import logging
from app.main import app
from app.models.database import create_tables

if __name__ == "__main__":
    # Configure logging before starting
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )

    # Create database tables
    create_tables()

    print("Starting Dendreo Progression API...")
    print("Logs will appear below:")
    print("-" * 50)

    # Run with logging
    uvicorn.run(
        "app.main:app",
        host="127.0.0.1",
        port=8000,
        reload=True,
        log_level="info"
    )
