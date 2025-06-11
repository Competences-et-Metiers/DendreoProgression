import uvicorn
import logging
from app.main import app
from app.models.database import create_tables

if __name__ == "__main__":
    # Configure root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(logging.INFO)

    # Create formatters and handlers
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    
    # Console handler for terminal output
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    console_handler.setFormatter(formatter)
    
    # File handler for log file
    file_handler = logging.FileHandler('logs/app.log')
    file_handler.setLevel(logging.INFO)
    file_handler.setFormatter(formatter)

    # Remove any existing handlers from root logger
    for handler in root_logger.handlers[:]:
        root_logger.removeHandler(handler)

    # Add both console and file handlers
    root_logger.addHandler(console_handler)
    root_logger.addHandler(file_handler)

    # Set specific logger levels
    for logger_name in [
        'app.services.dendreo_client',
        'app.services.dendreo_sync',
        'app.services.data_processor',
        'httpx'
    ]:
        logger = logging.getLogger(logger_name)
        logger.setLevel(logging.INFO)
        # Remove any existing handlers
        for handler in logger.handlers[:]:
            logger.removeHandler(handler)
        # Add both console and file handlers
        logger.addHandler(console_handler)
        logger.addHandler(file_handler)

    # Silence noisy loggers that cause loops (keep these silenced!)
    logging.getLogger('watchfiles').setLevel(logging.ERROR)
    logging.getLogger('watchfiles.main').setLevel(logging.ERROR)
    logging.getLogger('uvicorn.access').setLevel(logging.WARNING)

    # Create database tables
    create_tables()

    print("\nStarting Dendreo Progression API...")
    print("Server will run at http://192.168.254.24:8000")
    print("Logs will appear below and be saved to logs/app.log")
    print("-" * 50 + "\n")

    # Run with normal console logging
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        reload_excludes=["logs/*", "*.log"],  # Exclude log files from triggering reloads
        log_level="info"  # Back to info level for uvicorn
    )
