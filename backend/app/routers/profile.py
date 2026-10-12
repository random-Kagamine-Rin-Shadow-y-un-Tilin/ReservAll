from fastapi import APIRouter, Depends
from app.core.dependencies import get_current_user, get_db_pool
from app.repositories import user_repository as repo
from app.models.user import UserOut
import asyncpg

router = APIRouter(prefix="/profile", tags=["perfil"])

@router.get("/me", response_model=UserOut)
async def my_profile(current_user : dict = Depends(get_current_user), 
                     pool: asyncpg.Pool = Depends(get_db_pool)):
    user = await repo.get_user_by_id(pool, int(current_user["sub"]))
    return dict(user)