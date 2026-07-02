from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    APP_NAME: str = "MintFlow"
    DEBUG: bool = True

    # Database
    DATABASE_URL: str = "postgresql://postgres:123@localhost:5432/mintflow_db"

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # JWT
    SECRET_KEY: str = "mintflow-super-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # CORS
    ALLOWED_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:5173",
        "https://omkarpujeri.github.io",
    ]

    # AWS S3 / Storage
    AWS_ACCESS_KEY_ID: str = ""
    AWS_SECRET_ACCESS_KEY: str = ""
    AWS_BUCKET_NAME: str = "mintflow-videos"
    AWS_REGION: str = "ap-south-1"

    class Config:
        env_file = ".env"


settings = Settings()
