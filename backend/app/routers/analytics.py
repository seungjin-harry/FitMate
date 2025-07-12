from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.database import get_db
from app.models.content import Content, ContentType
from app.models.user import User, UserRole
from app.core.deps import get_current_user
from datetime import datetime, timedelta
from typing import List, Dict

router = APIRouter()

@router.get("/summary")
def get_analytics_summary(
    start_date: datetime,
    end_date: datetime,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="관리자만 접근할 수 있습니다")
        
    # 전체 컨텐츠 수
    total_contents = db.query(Content).filter(
        Content.created_at.between(start_date, end_date)
    ).count()
    
    # 컨텐츠 타입별 수
    content_type_counts = db.query(
        Content.content_type,
        func.count(Content.id)
    ).filter(
        Content.created_at.between(start_date, end_date)
    ).group_by(Content.content_type).all()
    
    # 업로드 성공/실패 수
    upload_stats = {
        'success': db.query(Content).filter(
            Content.created_at.between(start_date, end_date),
            Content.is_uploaded == True
        ).count(),
        'failed': db.query(Content).filter(
            Content.created_at.between(start_date, end_date),
            Content.is_uploaded == False
        ).count()
    }
    
    # 실패한 컨텐츠 상세 정보
    failed_contents = db.query(Content).filter(
        Content.created_at.between(start_date, end_date),
        Content.is_uploaded == False
    ).all()
    
    failed_details = []
    for content in failed_contents:
        failed_details.append({
            'id': content.id,
            'title': content.title,
            'content_type': content.content_type,
            'created_at': content.created_at,
            'upload_status': content.upload_status
        })
    
    return {
        'period': {
            'start': start_date,
            'end': end_date
        },
        'total_contents': total_contents,
        'content_type_counts': dict(content_type_counts),
        'upload_stats': upload_stats,
        'failed_contents': failed_details
    }

@router.get("/daily")
def get_daily_analytics(
    days: int = 7,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="관리자만 접근할 수 있습니다")
        
    end_date = datetime.now()
    start_date = end_date - timedelta(days=days)
    
    daily_stats = []
    current_date = start_date
    
    while current_date <= end_date:
        next_date = current_date + timedelta(days=1)
        
        # 일별 통계
        stats = {
            'date': current_date.date(),
            'total': db.query(Content).filter(
                Content.created_at.between(current_date, next_date)
            ).count(),
            'uploaded': db.query(Content).filter(
                Content.created_at.between(current_date, next_date),
                Content.is_uploaded == True
            ).count()
        }
        
        daily_stats.append(stats)
        current_date = next_date
    
    return daily_stats

@router.get("/content-type")
def get_content_type_analytics(
    content_type: ContentType,
    days: int = 30,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="관리자만 접근할 수 있습니다")
        
    end_date = datetime.now()
    start_date = end_date - timedelta(days=days)
    
    contents = db.query(Content).filter(
        Content.content_type == content_type,
        Content.created_at.between(start_date, end_date)
    ).all()
    
    success_rate = len([c for c in contents if c.is_uploaded]) / len(contents) if contents else 0
    
    return {
        'content_type': content_type,
        'period': {
            'start': start_date,
            'end': end_date
        },
        'total_contents': len(contents),
        'success_rate': success_rate,
        'contents': [{
            'id': c.id,
            'title': c.title,
            'created_at': c.created_at,
            'is_uploaded': c.is_uploaded,
            'upload_status': c.upload_status
        } for c in contents]
    } 