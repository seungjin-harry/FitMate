from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Enum, Boolean, JSON
from sqlalchemy.orm import relationship
from app.database import Base
import enum
from datetime import datetime

class ContentType(str, enum.Enum):
    DAILY = "감성적_일상_나눔"
    ARTISTIC = "예술적_취향_나눔"
    PHILOSOPHY = "인용_및_철학"
    WORK = "작품_소개"
    INTERVIEW = "감성_인터뷰"

class MediaType(str, enum.Enum):
    IMAGE = "image"
    VIDEO = "video"
    TEXT = "text"
    CAROUSEL = "carousel"
    STORY = "story"

class Content(Base):
    __tablename__ = "contents"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    content_type = Column(Enum(ContentType))
    media_type = Column(Enum(MediaType))
    title = Column(String)
    description = Column(String)
    file_path = Column(String)
    github_path = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
    is_uploaded = Column(Boolean, default=False)
    upload_status = Column(JSON)  # 각 소셜 미디어별 업로드 상태
    
    user = relationship("User", back_populates="contents") 