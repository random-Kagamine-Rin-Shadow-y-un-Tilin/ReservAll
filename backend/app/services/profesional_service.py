from fastapi import HTTPException, status
from app.models.profesional import ProfessionalRegister, ProfessionalEdit
from app.repositories import profesional_repository as repo
from app.repositories import shop_repository as shop_repo
import asyncpg

async def register_professional(pool: asyncpg.Pool, shop_id: int, data: ProfessionalRegister, current_user_id: int):
    shop = await shop_repo.get_shop_by_id(pool, shop_id)
    if not shop:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Negocio no encontrado.")
    if shop['dueno_id'] != current_user_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "No tienes permiso.")

    professional = await repo.create_professional(pool, shop_id, data.model_dump())
    return professional

async def list_professionals(pool: asyncpg.Pool, shop_id: int):
    return await repo.get_professionals_by_shop(pool, shop_id)

async def edit_professional(pool: asyncpg.Pool, shop_id: int, professional_id: int, data: ProfessionalEdit, current_user_id: int):
    shop = await shop_repo.get_shop_by_id(pool, shop_id)
    if not shop or shop['dueno_id'] != current_user_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "No tienes permiso.")

    prof = await repo.get_professional_by_id(pool, professional_id)
    if not prof or prof['negocio_id'] != shop_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Profesional no encontrado.")

    updated = await repo.update_professional(pool, professional_id, data.model_dump(exclude_unset=True))
    return updated

async def delete_professional(pool: asyncpg.Pool, shop_id: int, professional_id: int, current_user_id: int):
    shop = await shop_repo.get_shop_by_id(pool, shop_id)
    if not shop or shop['dueno_id'] != current_user_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "No tienes permiso.")

    prof = await repo.get_professional_by_id(pool, professional_id)
    if not prof or prof['negocio_id'] != shop_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Profesional no encontrado.")

    return await repo.deactivate_professional(pool, professional_id)