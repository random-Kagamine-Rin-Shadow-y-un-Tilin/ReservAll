from fastapi import APIRouter, Depends, status
from app.core.dependencies import get_db_pool, verify_api_key, get_current_user
from app.models.profesional import ProfessionalRegister, ProfessionalEdit, ProfessionalOut
from app.services import profesional_service
import asyncpg

router = APIRouter(prefix="/professional", tags=["professional"], dependencies=[Depends(verify_api_key)])

@router.post("/register/{shop_id}", response_model=ProfessionalOut, status_code=201)
async def register_professional(
    shop_id: int,
    data: ProfessionalRegister,
    current_user: dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    prof = await profesional_service.register_professional(pool, shop_id, data, int(current_user["sub"]))
    return dict(prof)

@router.get("/list/{shop_id}", response_model=list[ProfessionalOut])
async def list_professionals(shop_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    return [dict(p) for p in await profesional_service.list_professionals(pool, shop_id)]

@router.put("/edit/{shop_id}/{professional_id}", response_model=ProfessionalOut)
async def edit_professional(
    shop_id: int,
    professional_id: int,
    data: ProfessionalEdit,
    current_user: dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    return dict(await profesional_service.edit_professional(pool, shop_id, professional_id, data, int(current_user["sub"])))

@router.delete("/delete/{shop_id}/{professional_id}")
async def delete_professional(
    shop_id: int,
    professional_id: int,
    current_user: dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    return await profesional_service.delete_professional(pool, shop_id, professional_id, int(current_user["sub"]))