from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class ContentBase(BaseModel):
    title: str
    description: Optional[str] = None
    content_type: str  # video, image, text 등
    tags: Optional[List[str]] = []
    is_public: bool = True

class ContentCreate(ContentBase):
    file_url: Optional[str] = None
    thumbnail_url: Optional[str] = None

class ContentResponse(ContentBase):
    id: int
    file_url: str
    thumbnail_url: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    author_id: int
    likes_count: int = 0
    comments_count: int = 0
    
    class Config:
        from_attributes = True 