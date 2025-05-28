import os
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables
env_path = Path(__file__).parent / ".env"
print(f"Looking for .env at: {env_path}")
print(f"File exists: {env_path.exists()}")

load_dotenv(dotenv_path=env_path)

print(f"DATABASE_URL: {os.getenv('DATABASE_URL')}")
print(f"DENDREO_API_KEY: {os.getenv('DENDREO_API_KEY')}")
print(f"DENDREO_BASE_URL: {os.getenv('DENDREO_BASE_URL')}")