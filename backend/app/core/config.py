from pydantic_settings import BaseSettings
from typing import Optional
import os

class Settings(BaseSettings):
    PROJECT_NAME: str = "FitMate"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # 보안 설정
    SECRET_KEY: str = "your-secret-key-here"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 8  # 8 days
    
    # 데이터베이스 설정
    DATABASE_URL: str = "postgresql://postgres:postgres@localhost:5432/fitmate"
    
    # GitHub 설정
    GITHUB_CLIENT_ID: Optional[str] = None
    GITHUB_CLIENT_SECRET: Optional[str] = None
    
    # CORS 설정
    BACKEND_CORS_ORIGINS: list = ["http://localhost:3000"]
    
    # JWT
    ALGORITHM: str = "HS256"
    
    # GitHub
    GITHUB_TOKEN: str = "your-github-token"
    GITHUB_REPO: str = "your-username/FitMate"
    
    # Social Media
    FACEBOOK_TOKEN: str = "your-facebook-token"
    TWITTER_API_KEY: str = "your-twitter-api-key"
    TWITTER_API_SECRET: str = "your-twitter-api-secret"
    TWITTER_ACCESS_TOKEN: str = "your-twitter-access-token"
    TWITTER_ACCESS_TOKEN_SECRET: str = "your-twitter-access-token-secret"
    INSTAGRAM_USERNAME: str = "your-instagram-username"
    INSTAGRAM_PASSWORD: str = "your-instagram-password"
    
    # File Upload
    UPLOAD_DIR: str = "uploads"
    FONT_PATH: str = "/System/Library/Fonts/Supplemental/Arial.ttf"  # macOS 기본 Arial 폰트 경로
    
    class Config:
        case_sensitive = True
        env_file = ".env"

settings = Settings() 