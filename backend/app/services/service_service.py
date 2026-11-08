from fastapi import HTTPException, status
from app.models.service import ServiceRegister, ServiceEdit
from app.repositories import service_repository as repo
from app.repositories import shop_repository as shop_repo
import asyncpg

async def register_service(pool: asyncpg.Pool, shop_id: int, data: ServiceRegister, current_user_id: int):
    shop = await shop_repo.get_shop_by_id(pool, shop_id)
    if not shop:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Negocio no encontrado.")
    if shop['dueno_id'] != current_user_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "No tienes permiso.")

    if data.duracion_minutos <= 0:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "La duración debe ser mayor a 0.")
    if data.precio < 0:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "El precio no puede ser negativo.")
    if data.cantidad_servicio < 1:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "La cantidad debe ser al menos 1.")

    service = await repo.create_service(pool, shop_id, data.model_dump())

    if data.profesional_ids:
        await repo.assign_professionals(pool, service['id_servicio'], data.profesional_ids)

    return service

async def get_services_with_professionals(pool: asyncpg.Pool, shop_id: int):
    services = await repo.get_services_by_shop(pool, shop_id)
    result = []
    for s in services:
        service_dict = dict(s)
        professionals = await repo.get_professionals_for_service(pool, s['id_servicio'])
        service_dict['profesionales'] = [dict(p) for p in professionals]
        result.append(service_dict)
    return result

async def edit_service(pool: asyncpg.Pool, shop_id: int, service_id: int, data: ServiceEdit, current_user_id: int):
    shop = await shop_repo.get_shop_by_id(pool, shop_id)
    if not shop or shop['dueno_id'] != current_user_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "No tienes permiso.")

    service = await repo.get_service_by_id(pool, service_id)
    if not service or service['negocio_id'] != shop_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Servicio no encontrado.")

    update_data = data.model_dump(exclude_unset=True)
    profesional_ids = update_data.pop('profesional_ids', None)

    if update_data.get('duracion_minutos') is not None and update_data['duracion_minutos'] <= 0:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "La duración debe ser mayor a 0.")
    if update_data.get('precio') is not None and update_data['precio'] < 0:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "El precio no puede ser negativo.")
    if update_data.get('cantidad_servicio') is not None and update_data['cantidad_servicio'] < 1:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "La cantidad debe ser al menos 1.")

    if update_data:
        await repo.update_service(pool, service_id, update_data)

    if profesional_ids is not None:
        await repo.replace_service_professionals(pool, service_id, profesional_ids)

    return await repo.get_service_by_id(pool, service_id)

async def delete_service(pool: asyncpg.Pool, shop_id: int, service_id: int, current_user_id: int):
    shop = await shop_repo.get_shop_by_id(pool, shop_id)
    if not shop or shop['dueno_id'] != current_user_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "No tienes permiso.")

    service = await repo.get_service_by_id(pool, service_id)
    if not service or service['negocio_id'] != shop_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Servicio no encontrado.")

    await repo.set_service_status(pool, service_id, False)

    return {"message": "Servicio desactivado correctamente."}
