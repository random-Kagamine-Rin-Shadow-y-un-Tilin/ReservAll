from fastapi import APIRouter, Depends, Response, Cookie, HTTPException,  status
import asyncpg
from app.models.user import UserRegister, UserLogin, UserOut
from app.services import auth_service
from app.core.dependencies import get_db_pool, verify_api_key
from app.core.config import settings

router = APIRouter(prefix='/auth', tags=["auth"], dependencies=[Depends(verify_api_key)])

def _set_auth_cookies(response: Response, access_token: str, resfresh_token: str):
    response.set_cookie(
        key="SNRL_access_token",
        value=access_token,
        httponly=True,
        secure=False,
        samesite="lax",
        max_age=settings.jwt_access_expire_minutes * 60,
        path="/",
    )
    response.set_cookie(
        key="SNRL_refresh_token",
        value=resfresh_token,
        httponly=True,
        secure=False,
        samesite="lax",
        max_age=settings.jwt_refresh_expire_days * 24 * 60 * 60,
        path="/api/v1/auth",
    )

@router.post("/register", response_model=UserOut, status_code=201)
async def register(data: UserRegister, pool: asyncpg.Pool = Depends(get_db_pool)):
    user = await auth_service.register_user(pool, data)
    return dict(user)

@router.post("/login", response_model=UserOut)
async def login(data: UserLogin, response: Response, pool: asyncpg.Pool = Depends(get_db_pool)):
    access_token, refresh_token, user = await auth_service.login_user(pool, data)
    _set_auth_cookies(response, access_token, refresh_token)
    return dict(user)

@router.post("/refresh")
async def refresh(
    response: Response,
    refresh_token: str | None = Cookie(default=None, alias='SNRL_refresh_token'),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    if not refresh_token:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "No hay refresh token.")
    
    new_acces, new_refresh = await auth_service.refresh_access_token(pool, refresh_token)
    _set_auth_cookies(response, new_acces, new_refresh)
    return {"message": "Token renovado."}

@router.post('/logout')
async def logout(
    response: Response,
    refresh_token: str | None = Cookie(default=None, alias='SNRL_refresh_token'),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    await auth_service.logout_user(pool, refresh_token)
    response.delete_cookie("SNRL_access_token", path="/")
    response.delete_cookie("SNRL_refresh_token", path="/api/v1/auth")
    return {"message": "Sesión cerrada."}