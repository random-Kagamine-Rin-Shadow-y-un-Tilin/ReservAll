from fastapi import APIRouter, Depends
from app.core.dependencies import get_current_user, get_db_pool
from app.repositories import user_repository as repo
from app.models.user import ProfileUpdate, UserOut
from app.services import profile_service
import asyncpg

router = APIRouter(prefix="/profile", tags=["perfil"])

@router.get("/me", response_model=UserOut)
async def my_profile(current_user : dict = Depends(get_current_user),
                     pool: asyncpg.Pool = Depends(get_db_pool)):
    user = await repo.get_user_by_id(pool, int(current_user["sub"]))
    return dict(user)


@router.patch("/me", response_model=UserOut, summary="Editar mi perfil")
async def update_my_profile(
    data: ProfileUpdate,
    current_user: dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    # El ID se toma siempre del token: un usuario nunca puede editar a otro.
    return await profile_service.update_profile(
        pool, int(current_user["sub"]), data
    )
