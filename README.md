# FitMate

FitMate는 피트니스 콘텐츠 관리 및 공유 플랫폼입니다.

## 주요 기능

- 사용자 인증 (관리자/일반 사용자)
- 카메라를 통한 사진/동영상 촬영
- 자동 워터마크 적용 ("Lento&Lux Inc.")
- 콘텐츠 관리자 승인 시스템
- 승인된 콘텐츠의 소셜 미디어 업로드

## 기술 스택

### iOS 앱
- Swift
- SwiftUI
- AVFoundation (카메라/비디오 처리)
- Combine (상태 관리)

### 백엔드
- Python
- FastAPI
- SQLite
- JWT 인증

### 프론트엔드 (웹 관리자)
- React
- TypeScript
- Material-UI

## 시작하기

### 요구사항
- iOS 14.0+
- Xcode 13.0+
- Python 3.8+
- Node.js 14.0+

### iOS 앱 설치
1. Xcode에서 FitMateApp 프로젝트를 엽니다
2. 시뮬레이터나 실제 기기를 선택합니다
3. Run 버튼을 클릭하여 앱을 실행합니다

### 백엔드 서버 실행
```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### 웹 관리자 페이지 실행
```bash
cd frontend
npm install
npm start
```

## 테스트 계정

### 관리자
- 이메일: admin@fitmate.com
- 비밀번호: admin123

### 일반 사용자
- 이메일: user@fitmate.com
- 비밀번호: user123

## 프로젝트 구조

```
FitMate/
├── FitMateApp/          # iOS 앱
├── backend/             # Python FastAPI 백엔드
└── frontend/            # React 웹 관리자
```

## 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다. 