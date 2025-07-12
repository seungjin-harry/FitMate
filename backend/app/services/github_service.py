import os
from github import Github
from app.core.config import settings
from app.models.content import ContentType

class GitHubService:
    def __init__(self):
        self.github = Github(settings.GITHUB_TOKEN)
        self.repo = self.github.get_repo(settings.GITHUB_REPO)
        
    def _get_directory_path(self, content_type: ContentType) -> str:
        base_path = "contents"
        directories = {
            ContentType.DAILY: "감성적_일상_나눔",
            ContentType.ARTISTIC: "예술적_취향_나눔",
            ContentType.PHILOSOPHY: "인용_및_철학",
            ContentType.WORK: "작품_소개",
            ContentType.INTERVIEW: "감성_인터뷰"
        }
        return f"{base_path}/{directories[content_type]}"
        
    def upload_to_github(self, file_path: str, content_type: ContentType) -> str:
        directory = self._get_directory_path(content_type)
        file_name = os.path.basename(file_path)
        
        with open(file_path, 'rb') as file:
            content = file.read()
        
        try:
            # 디렉토리가 없으면 생성
            try:
                self.repo.get_contents(directory)
            except:
                self.repo.create_file(
                    f"{directory}/.gitkeep",
                    "Initialize directory",
                    ""
                )
            
            # 파일 업로드
            github_path = f"{directory}/{file_name}"
            self.repo.create_file(
                github_path,
                f"Upload {file_name}",
                content
            )
            
            return github_path
            
        except Exception as e:
            raise Exception(f"GitHub 업로드 실패: {str(e)}")
            
    def delete_from_github(self, github_path: str):
        try:
            file = self.repo.get_contents(github_path)
            self.repo.delete_file(
                github_path,
                f"Delete {os.path.basename(github_path)}",
                file.sha
            )
        except Exception as e:
            raise Exception(f"GitHub 삭제 실패: {str(e)}")
            
    def get_file_url(self, github_path: str) -> str:
        try:
            file = self.repo.get_contents(github_path)
            return file.download_url
        except Exception as e:
            raise Exception(f"GitHub 파일 URL 조회 실패: {str(e)}") 