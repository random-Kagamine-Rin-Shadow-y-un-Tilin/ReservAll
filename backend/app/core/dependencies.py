from fastapi import Header, HTTPException, status, Depends, Cookie
from app.core.config import settings
from app.core.security import decode_acces_token
from app.core.database import get_pool
import asyncpg

async def verify_api_key(x_api_key: str = Header(...)):
    if x_api_key != settings.api_key:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "API key invalida.")
    
async def get_current_user(
    access_token: str | None = Cookie(default=None, alias="SNRL_access_token"),
    _: None = Depends(verify_api_key)
    ) -> dict:
    if not access_token:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "No hay sesión activa.")

    payload = decode_acces_token(access_token)
    if payload is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Token inválido o expirado.")
        
    return payload

async def get_db_pool() -> asyncpg.Pool:
    return get_pool()