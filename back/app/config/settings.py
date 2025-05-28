import os
from pathlib import Path
from pydantic_settings import BaseSettings
from pydantic import Field
from typing import Optional
from dotenv import load_dotenv

# Get the root directory (where .env should be located)
ROOT_DIR = Path(__file__).parent.parent.parent
ENV_FILE = ROOT_DIR / ".env"

# Load environment variables from .env file
load_dotenv(dotenv_path=ENV_FILE)

class Settings(BaseSettings):
    # App settings
    app_name: str = "Dendreo Progression API"
    version: str = "1.0.0"
    log_level: str = "INFO"

    # Database
    database_url: str = Field(..., env="DATABASE_URL")

    # Dendreo API
    dendreo_api_key: str = Field(..., env="DENDREO_API_KEY")
    dendreo_base_url: str = Field(..., env="DENDREO_BASE_URL")

    # HubSpot
    hubspot_api_key: Optional[str] = Field(None, env="HUBSPOT_API_KEY")
    hubspot_base_url: str = "https://api.hubapi.com"

    class Config:
        env_file = ENV_FILE
        env_file_encoding = "utf-8"

# Create settings instance
settings = Settings()
