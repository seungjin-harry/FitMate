from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.content import Content, ContentType
from app.models.user import User, UserRole
from app.core.deps import get_current_user
from app.services.social_service import SocialService
from datetime import datetime
from typing import List

router = APIRouter()

@router.post("/upload/{content_id}")
async def upload_to_social(
    content_id: int,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="관리자만 업로드할 수 있습니다")

    content = db.query(Content).filter(Content.id == content_id).first()
    if not content:
        raise HTTPException(status_code=404, detail="컨텐츠를 찾을 수 없습니다")

    if content.is_uploaded:
        raise HTTPException(status_code=400, detail="이미 업로드된 컨텐츠입니다")

    social_service = SocialService()
    background_tasks.add_task(
        social_service.upload_content,
        content=content,
        db=db
    )

    return {"message": "업로드가 시작되었습니다"}

@router.get("/schedule")
def get_upload_schedule(current_user: User = Depends(get_current_user)):
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="관리자만 접근할 수 있습니다")

    schedule = {
        "월요일": {
            "time": "07:00",
            "content_type": ContentType.DAILY,
            "tag": "#엘리안 샘의 월요 편지"
        },
        "화요일": {
            "time": "08:00",
            "content_type": ContentType.ARTISTIC,
            "tag": "#오늘의 운동"
        },
        "수요일": {
            "time": "20:00",
            "content_type": ContentType.PHILOSOPHY,
            "tag": "#사색의 운동"
        },
        "목요일": {
            "time": "21:00",
            "content_type": ContentType.WORK,
            "tag": "#엘리안샘의 Gym"
        },
        "금요일": {
            "time": "21:00",
            "content_type": ContentType.INTERVIEW,
            "tag": "#엘리안샘의 스토리"
        }
    }
    return schedule

@router.get("/status/{content_id}")
def get_upload_status(
    content_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    content = db.query(Content).filter(Content.id == content_id).first()
    if not content:
        raise HTTPException(status_code=404, detail="컨텐츠를 찾을 수 없습니다")

    if current_user.role != UserRole.ADMIN and content.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="접근 권한이 없습니다")

    return content.upload_status 