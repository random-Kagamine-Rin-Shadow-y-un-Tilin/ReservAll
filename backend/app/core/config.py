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
    #Geocodificacion (OpenStreetMap / Nominatim)
    geocoding_url: str = "https://nominatim.openstreetmap.org"
    geocoding_user_agent: str = "ReservAll/1.0 (+https://github.com/random-Kagamine-Rin-Shadow-y-un-Tilin/ReservAll)"
    geocoding_timeout_seconds: float = 10.0
    # CORS y cookies. En producción configurar CORS_ORIGINS y COOKIE_SECURE=true.
    cors_origins: str = "http://localhost:5173"
    cookie_secure: bool = False
    cookie_samesite: str = "lax"
    # Recuperación de contraseña (HU_03).
    smtp_host: str | None = None
    smtp_port: int = 587
    smtp_user: str | None = None
    smtp_password: str | None = None
    smtp_from: str | None = None
    smtp_use_tls: bool = True
    password_reset_code_ttl_minutes: int = 15
    # Solo para desarrollo/local: devuelve el código en la respuesta.
    password_reset_return_code: bool = False
    # Notificaciones push de reservas (Web Push / VAPID).
    push_enabled: bool = True
    vapid_public_key: str | None = None
    vapid_private_key: str | None = None
    vapid_subject: str = "mailto:soporte@reservall.local"
    # Minutos de antelación con los que se avisa de una reserva (0 = a su hora).
    push_lead_minutes: int = 0
    # Cada cuántos segundos se revisan las reservas próximas.
    push_check_interval_seconds: int = 30

    @property
    def push_configured(self) -> bool:
        return bool(self.vapid_public_key and self.vapid_private_key)

    @property
    def cors_origins_list(self) -> list[str]:
        return [
            origin.strip()
            for origin in self.cors_origins.split(",")
            if origin.strip()
        ]

    model_config = SettingsConfigDict(env_file=BASE_DIR / ".env")

settings = Settings()
