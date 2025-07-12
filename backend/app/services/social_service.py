from typing import Optional
from fastapi import HTTPException
import requests
from app.core.config import settings

class SocialService:
    """소셜 로그인 서비스"""
    
    @staticmethod
    async def verify_google_token(token: str) -> dict:
        """Google OAuth 토큰 검증"""
        try:
            google_response = requests.get(
                f"https://www.googleapis.com/oauth2/v3/tokeninfo?id_token={token}"
            )
            if google_response.status_code != 200:
                raise HTTPException(status_code=400, detail="Invalid Google token")
            return google_response.json()
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))
    
    @staticmethod
    async def verify_kakao_token(token: str) -> dict:
        """Kakao OAuth 토큰 검증"""
        try:
            headers = {"Authorization": f"Bearer {token}"}
            kakao_response = requests.get(
                "https://kapi.kakao.com/v2/user/me",
                headers=headers
            )
            if kakao_response.status_code != 200:
                raise HTTPException(status_code=400, detail="Invalid Kakao token")
            return kakao_response.json()
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))
