from pydantic_settings import BaseSettings
from pydantic import Field
from typing import Optional

class Settings(BaseSettings):
    # Database
    database_url: str = Field(..., env="DATABASE_URL")

    # Dendreo API
    dendreo_api_key: str = Field(..., env="DENDREO_API_KEY")
    dendreo_base_url: str = Field(..., env="DENDREO_BASE_URL")

    # HubSpot
    hubspot_api_key: Optional[str] = Field(None, env="HUBSPOT_API_KEY")

    # App settings
    log_level: str = Field("INFO", env="LOG_LEVEL")
    app_name: str = "Dendreo Internal API"
    version: str = "1.0.0"

    class Config:
        env_file = ".env"
        case_sensitive = False

settings = Settings()
