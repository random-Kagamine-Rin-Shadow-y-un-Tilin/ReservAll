from pydantic_settings import BaseSettings, SettingsConfigDict
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent.parent

class Settings(BaseSettings):
    database_url: str
    jwt_secret: str
    jwt_algorithm: str = "HS256"
    jwt_access_expire_minutes : int = 60
    jwt_refresh_expire_days : int = 14
    api_key: str
    #Bucket for photos
    supabase_url : str
    supabase_service_role_key: str
    supabase_bucket: str = 'negocios_fotos'
    
    model_config = SettingsConfigDict(env_file=BASE_DIR / ".env")
        
settings = Settings()