from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from passlib.context import CryptContext
from datetime import datetime, timedelta
from jose import JWTError, jwt
from . import models, database
from typing import Optional
from pydantic import BaseModel

app = FastAPI()

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 비밀번호 해싱 설정
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# JWT 설정
SECRET_KEY = "your-secret-key-here"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# 데이터베이스 초기화
models.Base.metadata.create_all(bind=database.engine)

class UserCreate(BaseModel):
    username: str
    password: str
    is_admin: bool = False

# 초기 관리자 계정 생성
def create_initial_user():
    db = next(database.get_db())
    # 이미 사용자가 있는지 확인
    user = db.query(models.User).filter(models.User.username == "admin").first()
    if not user:
        hashed_password = pwd_context.hash("admin123")
        user = models.User(username="admin", hashed_password=hashed_password, is_admin=True)
        db.add(user)
        db.commit()
        db.refresh(user)
    
    # 테스트용 일반 사용자 계정 생성
    test_user = db.query(models.User).filter(models.User.username == "user1").first()
    if not test_user:
        hashed_password = pwd_context.hash("user123")
        test_user = models.User(username="user1", hashed_password=hashed_password, is_admin=False)
        db.add(test_user)
        db.commit()
        db.refresh(test_user)

# 애플리케이션 시작 시 초기 사용자 생성
create_initial_user()

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(database.get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    user = db.query(models.User).filter(models.User.username == username).first()
    if user is None:
        raise credentials_exception
    return user

@app.post("/token")
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.username == form_data.username).first()
    if not user or not pwd_context.verify(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username, "is_admin": user.is_admin}, 
        expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/users/", response_model=dict)
async def create_user(user: UserCreate, db: Session = Depends(database.get_db)):
    db_user = db.query(models.User).filter(models.User.username == user.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    hashed_password = pwd_context.hash(user.password)
    db_user = models.User(
        username=user.username,
        hashed_password=hashed_password,
        is_admin=user.is_admin
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return {"message": "User created successfully"}

@app.get("/api/dashboard/stats")
async def get_dashboard_stats(
    startDate: str,
    endDate: str,
    current_user: models.User = Depends(get_current_user)
):
    # 임시 데이터 반환
    return {
        "totalContent": 15,
        "socialMediaStats": {
            "facebook": {"uploaded": 5, "failed": 1},
            "instagram": {"uploaded": 4, "failed": 0},
            "youtube": {"uploaded": 4, "failed": 1}
        },
        "failedContent": [
            {"title": "홍보 영상 1", "reason": "파일 크기 초과"},
            {"title": "운동 가이드", "reason": "업로드 시간 초과"}
        ],
        "githubContent": [
            {"name": "운동 프로그램 1", "url": "https://github.com/example/workout1"},
            {"name": "식단 가이드", "url": "https://github.com/example/diet-guide"}
        ]
    }

@app.get("/")
async def root():
    return {"message": "FitMatePlatform API에 오신 것을 환영합니다!"} 