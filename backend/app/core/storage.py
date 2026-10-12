import httpx
import uuid
from app.core.config import settings

async def upload_img(content: bytes, file_name: str, content_type: str) -> str:
    extension = file_name.split(".")[-1] if "." in file_name else "jpg"
    unique_name = f"{uuid.uuid4()}.{extension}"
    
    upload_url = f"{settings.supabase_url}/storage/v1/object/{settings.supabase_bucket}/{unique_name}"
    
    async with httpx.AsyncClient() as client:
        response = await client.post(
            upload_url,
            content=content,
            headers={
                "Authorization": f"Bearer {settings.supabase_service_role_key}",
                "apikey": settings.supabase_service_role_key,
                "Content-Type": content_type,
            },
        )
        
    if response.status_code not in (200, 201):
        raise Exception(f"Error al subir imagen: {response.text}")
    
    public_url = f"{settings.supabase_url}/storage/v1/object/public/{settings.supabase_bucket}/{unique_name}"
    return public_url