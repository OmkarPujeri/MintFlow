import os
from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict

# backend/ directory — so .env loads no matter the current working directory
# (uvicorn runs from backend/, alembic runs from the repo root).
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


class Settings(BaseSettings):
    APP_NAME: str = "MintFlow"
    ENVIRONMENT: str = "development"  # development | staging | production
    DEBUG: bool = False

    # Required — no insecure default. App refuses to start if missing.
    DATABASE_URL: str
    SECRET_KEY: str

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # JWT
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # CORS — comma-separated list of allowed frontend origins.
    CORS_ORIGINS: str = "http://localhost:3000,http://localhost:5173,https://omkarpujeri.github.io"

    # AWS S3 / Storage
    AWS_ACCESS_KEY_ID: str = ""
    AWS_SECRET_ACCESS_KEY: str = ""
    AWS_BUCKET_NAME: str = "mintflow-videos"
    AWS_REGION: str = "ap-south-1"

    model_config = SettingsConfigDict(
        env_file=os.path.join(BASE_DIR, ".env"),
        extra="ignore",
    )

    @property
    def allowed_origins(self) -> List[str]:
        return [o.strip() for o in self.CORS_ORIGINS.split(",") if o.strip()]

    @property
    def is_production(self) -> bool:
        return self.ENVIRONMENT.lower() == "production"


settings = Settings()
