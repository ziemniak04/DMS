"""
Configuration settings for the DMS Backend
"""
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings"""

    # App
    APP_NAME: str = "DMS Backend API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False

    # Dexcom API
    DEXCOM_CLIENT_ID: str = ""
    DEXCOM_CLIENT_SECRET: str = ""
    DEXCOM_REDIRECT_URI: str = "http://localhost:8000/auth/callback"
    DEXCOM_ENVIRONMENT: str = "sandbox"  # sandbox, us, eu, jp

    # Dexcom base URLs
    DEXCOM_SANDBOX_BASE_URL: str = "https://sandbox-api.dexcom.com"
    DEXCOM_US_BASE_URL: str = "https://api.dexcom.com"
    DEXCOM_EU_BASE_URL: str = "https://api.dexcom.eu"
    DEXCOM_JP_BASE_URL: str = "https://api.dexcom.jp"

    # OAuth URLs
    DEXCOM_AUTH_BASE_URL: str = "https://sandbox-api.dexcom.com"  # Same for all environments
    DEXCOM_TOKEN_ENDPOINT: str = "/v2/oauth2/token"
    DEXCOM_AUTHORIZE_ENDPOINT: str = "/v2/oauth2/login"

    # Rate limiting
    DEXCOM_RATE_LIMIT: int = 60000  # 60,000 calls per hour
    DEXCOM_RATE_WINDOW: int = 3600  # 1 hour in seconds

    # Firebase
    FIREBASE_PROJECT_ID: str = ""
    FIREBASE_CREDENTIALS_PATH: str = ""

    # Database
    DATABASE_URL: str = ""

    # Encryption
    ENCRYPTION_KEY: str = ""  # For encrypting Dexcom tokens

    # CORS
    CORS_ORIGINS: list = ["http://localhost:3000", "http://localhost:8080"]

    class Config:
        env_file = ".env"
        case_sensitive = True

    def get_dexcom_base_url(self) -> str:
        """Get the appropriate Dexcom API base URL based on environment"""
        env_map = {
            "sandbox": self.DEXCOM_SANDBOX_BASE_URL,
            "us": self.DEXCOM_US_BASE_URL,
            "eu": self.DEXCOM_EU_BASE_URL,
            "jp": self.DEXCOM_JP_BASE_URL,
        }
        return env_map.get(self.DEXCOM_ENVIRONMENT.lower(), self.DEXCOM_SANDBOX_BASE_URL)


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance"""
    return Settings()
