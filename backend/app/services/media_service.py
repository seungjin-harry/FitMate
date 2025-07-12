import os
from PIL import Image, ImageDraw, ImageFont
from moviepy.editor import VideoFileClip, TextClip, CompositeVideoClip
from fastapi import UploadFile
import uuid
from app.core.config import settings

class MediaService:
    def __init__(self):
        self.upload_dir = settings.UPLOAD_DIR
        self.watermark_text = "Lento&Lux Inc."
        self.font_path = settings.FONT_PATH  # Arial 폰트 경로
        
    async def save_file(self, file: UploadFile) -> str:
        # 업로드 디렉토리가 없으면 생성
        os.makedirs(self.upload_dir, exist_ok=True)
        
        # 유니크한 파일명 생성
        file_extension = os.path.splitext(file.filename)[1]
        unique_filename = f"{uuid.uuid4()}{file_extension}"
        file_path = os.path.join(self.upload_dir, unique_filename)
        
        # 파일 저장
        with open(file_path, "wb") as buffer:
            content = await file.read()
            buffer.write(content)
            
        return file_path
        
    def add_watermark(self, image_path: str) -> str:
        # 이미지 열기
        image = Image.open(image_path)
        
        # 워터마크용 레이어 생성
        watermark = Image.new('RGBA', image.size, (0,0,0,0))
        draw = ImageDraw.Draw(watermark)
        
        # 폰트 설정
        font_size = 12
        font = ImageFont.truetype(self.font_path, font_size)
        
        # 텍스트 크기 계산
        text_width = draw.textlength(self.watermark_text, font=font)
        text_height = font_size
        
        # 대각선으로 텍스트 그리기
        angle = -45
        text_position = (
            (image.width - text_width) // 2,
            (image.height - text_height) // 2
        )
        
        # 회색으로 텍스트 그리기
        draw.text(text_position, self.watermark_text, font=font, fill=(128,128,128,128))
        
        # 워터마크 회전
        rotated_watermark = watermark.rotate(angle, expand=True)
        
        # 워터마크 합성
        watermarked = Image.alpha_composite(image.convert('RGBA'), rotated_watermark)
        
        # 저장
        output_path = f"{os.path.splitext(image_path)[0]}_watermarked.png"
        watermarked.save(output_path)
        
        return output_path
        
    def add_video_watermark(self, video_path: str) -> str:
        # 비디오 로드
        video = VideoFileClip(video_path)
        
        # 워터마크 텍스트 클립 생성
        watermark = TextClip(
            self.watermark_text,
            fontsize=12,
            color='gray',
            font=self.font_path
        )
        
        # 워터마크 위치 설정 (우측 하단)
        watermark = watermark.set_position(('right', 'bottom'))
        
        # 워터마크 합성
        final = CompositeVideoClip([video, watermark])
        
        # 저장
        output_path = f"{os.path.splitext(video_path)[0]}_watermarked.mp4"
        final.write_videofile(output_path)
        
        return output_path 