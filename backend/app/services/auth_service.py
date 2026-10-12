import asyncpg
from fastapi import HTTPException, status
from app.models.user import UserRegister, UserLogin
from app.repositories import user_repository as user_repo
from app.repositories import refresh_token_repository as refresh_repo
from app.core.security import (
    hash_password, verify_password, create_acces_token,
    generate_refresh_token, hash_refresh_token
)
from app.core.config import settings

async def register_user(pool: asyncpg.Pool, data: UserRegister):
    if data.password != data.confirm_password:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Las contraseñas no coinciden.")
    
    exist = await user_repo.get_user_by_email(pool, data.correo)
    if exist:
        raise HTTPException(status.HTTP_409_CONFLICT, "Ese correo ya esta registrado.")
    
    password_hash = hash_password(data.password)
    user = await user_repo.create_user(pool, data.nombre, data.correo, password_hash, data.rol)
    return user

async def login_user(pool: asyncpg.Pool, data: UserLogin):
    user = await user_repo.get_user_by_email(pool, data.correo)
    
    if not user or not verify_password(data.password, user['password_hash']):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Correo o contraseña incorrectos.")
    
    access_token = create_acces_token({"sub": str(user["id"]), "rol": user["rol"]})
    
    refresh_token = generate_refresh_token()
    await refresh_repo.save_refresh_token(
        pool, user['id'], hash_refresh_token(refresh_token), settings.jwt_refresh_expire_days
    )
    
    return access_token, refresh_token, user

async def refresh_access_token(pool: asyncpg.Pool, refresh_token: str):
    token_hash = hash_refresh_token(refresh_token)
    record = await refresh_repo.get_valid_refresh_token(pool, token_hash)
    
    print(record)
    
    if not record:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, 
                            "Sesión expirada, inicia sesión de nuevo.")
    
    user = await user_repo.get_user_by_id(pool, record['user_id'])
    if not user:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Usuario no encontrado.")
    
    await refresh_repo.revoke_all_user_tokens(pool, user['id'])
    
    new_acces = create_acces_token({"sub": str(user["id"]), "rol": user["rol"]})
    new_refresh = generate_refresh_token()
    await refresh_repo.save_refresh_token(
        pool, user["id"], hash_refresh_token(new_refresh), settings.jwt_refresh_expire_days
    )
    
    return new_acces, new_refresh

async def logout_user(pool: asyncpg.Pool, refresh_token: str | None):
    if not refresh_token:
        return
    token_hash = hash_refresh_token(refresh_token)
    record = await refresh_repo.get_valid_refresh_token(pool, token_hash)
    if record:
        await refresh_repo.revoke_all_user_tokens(pool, record['user_id'])