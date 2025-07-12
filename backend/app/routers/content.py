from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.models.content import Content, ContentType, MediaType
from app.models.user import User, UserRole
from app.core.deps import get_current_user
from app.schemas.content import ContentCreate, ContentResponse
from app.services.github_service import GitHubService
from app.services.media_service import MediaService
import os

router = APIRouter()

@router.post("/upload", response_model=ContentResponse)
async def upload_content(
    content_type: ContentType,
    title: str,
    description: str,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # 파일 저장
    media_service = MediaService()
    file_path = await media_service.save_file(file)
    
    # 워터마크 추가
    if file.content_type.startswith('image/'):
        media_type = MediaType.IMAGE
        watermarked_path = media_service.add_watermark(file_path)
    elif file.content_type.startswith('video/'):
        media_type = MediaType.VIDEO
        watermarked_path = media_service.add_video_watermark(file_path)
    else:
        media_type = MediaType.TEXT
        watermarked_path = file_path

    # GitHub에 저장
    github_service = GitHubService()
    github_path = github_service.upload_to_github(watermarked_path, content_type)

    # DB에 저장
    content = Content(
        user_id=current_user.id,
        content_type=content_type,
        media_type=media_type,
        title=title,
        description=description,
        file_path=watermarked_path,
        github_path=github_path
    )
    db.add(content)
    db.commit()
    db.refresh(content)
    
    return content

@router.get("/list", response_model=List[ContentResponse])
def list_contents(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    content_type: ContentType = None
):
    query = db.query(Content)
    
    if current_user.role != UserRole.ADMIN:
        query = query.filter(Content.user_id == current_user.id)
    
    if content_type:
        query = query.filter(Content.content_type == content_type)
    
    return query.all()

@router.get("/{content_id}", response_model=ContentResponse)
def get_content(
    content_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    content = db.query(Content).filter(Content.id == content_id).first()
    if not content:
        raise HTTPException(status_code=404, detail="컨텐츠를 찾을 수 없습니다")
    
    if current_user.role != UserRole.ADMIN and content.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="접근 권한이 없습니다")
    
    return content

@router.delete("/{content_id}")
def delete_content(
    content_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    content = db.query(Content).filter(Content.id == content_id).first()
    if not content:
        raise HTTPException(status_code=404, detail="컨텐츠를 찾을 수 없습니다")
    
    if current_user.role != UserRole.ADMIN and content.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="접근 권한이 없습니다")
    
    # 파일 삭제
    if os.path.exists(content.file_path):
        os.remove(content.file_path)
    
    # GitHub에서 삭제
    github_service = GitHubService()
    github_service.delete_from_github(content.github_path)
    
    db.delete(content)
    db.commit()
    
    return {"message": "컨텐츠가 삭제되었습니다"} 