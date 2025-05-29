import uvicorn
import logging
from app.main import app
from app.models.database import create_tables

if __name__ == "__main__":
    # Configure root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(logging.DEBUG)

    # Create formatters and handlers
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    
    # Console handler with DEBUG level
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.DEBUG)
    console_handler.setFormatter(formatter)
    
    # File handler with DEBUG level
    file_handler = logging.FileHandler('app.log')
    file_handler.setLevel(logging.DEBUG)
    file_handler.setFormatter(formatter)

    # Remove any existing handlers from root logger
    for handler in root_logger.handlers[:]:
        root_logger.removeHandler(handler)

    # Add our handlers
    root_logger.addHandler(console_handler)
    root_logger.addHandler(file_handler)

    # Ensure specific loggers are set to DEBUG
    for logger_name in [
        'app.services.dendreo_client',
        'app.services.dendreo_sync',
        'httpx',
        'uvicorn',
        'fastapi'
    ]:
        logger = logging.getLogger(logger_name)
        logger.setLevel(logging.DEBUG)
        # Remove any existing handlers
        for handler in logger.handlers[:]:
            logger.removeHandler(handler)
        # Add our handlers
        logger.addHandler(console_handler)
        logger.addHandler(file_handler)

    # Create database tables
    create_tables()

    print("\nStarting Dendreo Progression API...")
    print("Logs will appear below:")
    print("-" * 50 + "\n")

    # Run with logging
    uvicorn.run(
        "app.main:app",
        host="127.0.0.1",
        port=8000,
        reload=True,
        log_level="debug",
        access_log=True
    )
