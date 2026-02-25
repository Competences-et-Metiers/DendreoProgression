import os
import logging
from pathlib import Path
from pydantic_settings import BaseSettings
from pydantic import Field, validator
from typing import Optional
from dotenv import load_dotenv

logger = logging.getLogger(__name__)

def load_environment_file() -> Optional[Path]:
    """
    Load the appropriate environment file based on APP_ENV.
    Returns the path of the loaded file or None.
    """
    # Get the project root directory
    current_file = Path(__file__)
    project_root = current_file.parent.parent.parent.parent
    
    # Determine environment
    app_env = os.getenv("APP_ENV", "development").lower()
    
    # Environment file priority
    env_files = []
    if app_env == "production":
        env_files = [
            project_root / ".env.prod",
            project_root / ".env.production",
            project_root / ".env"
        ]
    elif app_env == "development":
        env_files = [
            project_root / ".env.dev",
            project_root / ".env.development", 
            project_root / ".env"
        ]
    else:
        env_files = [project_root / ".env"]
    
    # Try to load the first available environment file
    for env_file in env_files:
        if env_file.exists():
            load_dotenv(dotenv_path=env_file, override=True)
            logger.info(f"Loaded environment configuration from: {env_file.name}")
            return env_file
    
    logger.warning(f"No environment file found for APP_ENV='{app_env}'. Using system environment variables.")
    return None

class Settings(BaseSettings):
    """Application settings with validation and environment-based configuration."""
    
    # App settings
    app_name: str = "Dendreo Progression API"
    version: str = "1.0.0"
    app_env: str = Field(default="development", env="APP_ENV")
    log_level: str = Field(default="INFO", env="LOG_LEVEL")
    debug: bool = Field(default=False, env="DEBUG")

    # Database
    database_url: str = Field(..., env="DATABASE_URL", description="PostgreSQL database connection URL")

    # Dendreo API
    dendreo_api_key: str = Field(..., env="DENDREO_API_KEY", description="Dendreo API key")
    dendreo_base_url: str = Field(..., env="DENDREO_BASE_URL", description="Dendreo API base URL")

    # HubSpot
    hubspot_api_key: Optional[str] = Field(None, env="HUBSPOT_API_KEY", description="HubSpot API key")
    hubspot_base_url: str = Field(default="https://api.hubapi.com", env="HUBSPOT_BASE_URL")

    # Redis (optional)
    redis_url: str = Field(default="redis://localhost:6379/0", env="REDIS_URL")
    redis_enabled: bool = Field(default=True, env="REDIS_ENABLED")

    # JWT Authentication
    jwt_secret_key: str = Field(..., env="JWT_SECRET_KEY", description="Secret key for JWT token signing")
    jwt_algorithm: str = Field(default="HS256", env="JWT_ALGORITHM")
    jwt_expiration_hours: int = Field(default=24, env="JWT_EXPIRATION_HOURS")

    # Microsoft Entra ID (Azure AD) - Optional
    azure_ad_tenant_id: Optional[str] = Field(None, env="AZURE_AD_TENANT_ID")
    azure_ad_client_id: Optional[str] = Field(None, env="AZURE_AD_CLIENT_ID")
    azure_ad_client_secret: Optional[str] = Field(None, env="AZURE_AD_CLIENT_SECRET")
    azure_ad_admin_group_id: Optional[str] = Field(None, env="AZURE_AD_ADMIN_GROUP_ID")

    # Server settings
    host: str = Field(default="0.0.0.0", env="HOST")
    port: int = Field(default=8000, env="PORT")

    @validator('app_env')
    def validate_app_env(cls, v):
        allowed_envs = ['development', 'production', 'testing']
        if v.lower() not in allowed_envs:
            raise ValueError(f'APP_ENV must be one of: {allowed_envs}')
        return v.lower()

    @validator('log_level')
    def validate_log_level(cls, v):
        allowed_levels = ['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL']
        if v.upper() not in allowed_levels:
            raise ValueError(f'LOG_LEVEL must be one of: {allowed_levels}')
        return v.upper()

    @validator('database_url')
    def validate_database_url(cls, v):
        if not v.startswith(('postgresql://', 'postgresql+psycopg2://')):
            raise ValueError('DATABASE_URL must be a valid PostgreSQL connection string')
        return v

    @property
    def azure_ad_enabled(self) -> bool:
        return bool(self.azure_ad_tenant_id and self.azure_ad_client_id)

    @property
    def is_development(self) -> bool:
        return self.app_env == 'development'

    @property
    def is_production(self) -> bool:
        return self.app_env == 'production'

    @property
    def is_testing(self) -> bool:
        return self.app_env == 'testing'

    class Config:
        env_file_encoding = "utf-8"
        case_sensitive = False
        validate_assignment = True

def create_settings() -> Settings:
    """
    Factory function to create settings instance with proper environment loading.
    """
    # Load environment file first
    env_file = load_environment_file()
    
    try:
        settings = Settings()
        
        # Log configuration summary (only in development)
        if settings.is_development:
            logger.info(f"Configuration loaded for environment: {settings.app_env}")
            logger.info(f"Database: {settings.database_url.split('@')[-1] if '@' in settings.database_url else 'local'}")
            logger.info(f"Log level: {settings.log_level}")
            logger.info(f"Redis enabled: {settings.redis_enabled}")
        
        return settings
        
    except Exception as e:
        logger.error(f"Failed to load settings: {e}")
        raise

# Create settings instance
settings = create_settings()
