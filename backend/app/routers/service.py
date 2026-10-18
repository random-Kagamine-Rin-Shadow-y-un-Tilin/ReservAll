from fastapi import APIRouter, Depends, status
from app.core.dependencies import get_db_pool, verify_api_key, get_current_user
from app.models.service import ServiceRegister, ServiceEdit, ServiceOut
from app.services import service_service
import asyncpg

router = APIRouter(prefix="/service", tags=["service"], dependencies=[Depends(verify_api_key)])

@router.post("/register/{shop_id}", response_model=ServiceOut, status_code=201)
async def register_service(
    shop_id: int,
    data: ServiceRegister,
    current_user: dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    service = await service_service.register_service(pool, shop_id, data, int(current_user["sub"]))
    return dict(service)

@router.get("/list/{shop_id}", response_model=list[ServiceOut])
async def list_services(shop_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    return await service_service.get_services_with_professionals(pool, shop_id)

@router.put("/edit/{shop_id}/{service_id}", response_model=ServiceOut)
async def edit_service(
    shop_id: int,
    service_id: int,
    data: ServiceEdit,
    current_user: dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    return dict(await service_service.edit_service(pool, shop_id, service_id, data, int(current_user["sub"])))

@router.delete("/delete/{shop_id}/{service_id}")
async def delete_service(
    shop_id: int,
    service_id: int,
    current_user: dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    return await service_service.delete_service(pool, shop_id, service_id, int(current_user["sub"]))