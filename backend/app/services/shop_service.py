from fastapi import HTTPException, status
from app.models.shop import ShopRegister, ShopEdit
from app.models.shop_contact import ShopContactRegister, ShopContactUpdate
from app.models.shop_schedule import ShopRegisterSchedule, ShopScheduleUpdate
from app.models.shop_address import ShopAddressRegister
from app.repositories import shop_repository as shop_repo
from app.repositories import shop_contact_repository as contact_repo
from app.repositories import shop_schedule_repository as sche_repo
from app.repositories import shop_address_repository as address_repo

import asyncpg
import asyncio

#GENERAL SHOP ACTIONS
async def register_shop(pool: asyncpg.pool, data: ShopRegister, current_user_id: int, rol: str):
    if rol != "negocio":
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Solo los usuarios tipo negocio pueden registrar un negocio."
        )
        
    shop = await shop_repo.create_shop(
        pool,
        id_owner = current_user_id,
        name = data.nombre,
        description = data.descripcion,
        category = data.categoria_negocio,
        shop_img = data.imagen_negocio,
    )
    
    return shop

async def edit_shop(
    pool: asyncpg.Pool, data:ShopEdit, current_user_id: int, shop_id: int, rol: str
    ):
    if rol != 'negocio': 
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Error de autenticación.")
    
    shop = await shop_repo.get_shop_by_id(pool, shop_id)
    if not shop:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Negocio no encontrado.")
    
    if shop["dueno_id"] != current_user_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "No tienes permiso para editar este negocio.")
    
    shop = await shop_repo.edit_basic_shop(
        pool, 
        shop_id,
        data.nombre,
        data.descripcion,
        data.fk_categoria,
        data.imagen_negocio
    )
    return shop

async def get_my_shops(pool: asyncpg.Pool, owner_id: int):
    shops = await shop_repo.get_shops_by_owner(pool, owner_id)
    return shops

async def get_shop_by_id(pool: asyncpg.Pool, shop_id: int, current_user_id: int):
    shop = await shop_repo.get_shop_by_id(pool, shop_id)
    if not shop:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Negocio no encontrado.")
    
    if shop["dueno_id"] != current_user_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "No tienes permiso para ver este negocio.")
    
    return shop

async def get_shop_full_profile(pool: asyncpg.Pool, shop_id: int):
    shop = await shop_repo.get_shop_by_id(pool, shop_id)
    
    if not shop:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Negocio no encontrado.")
    
    contacts = await get_contacts_by_shop(pool, shop_id)
    schedule = await get_weekly_schedule(pool, shop_id)
    address = await get_address_by_shop(pool, shop_id)
    
    return{
        "general": dict(shop),
        "contacto": [dict(c) for c in contacts],
        "horario": [dict(sh) for sh in schedule],
        "direccion": dict(address) if address else None
    }

# SERVICES FOR CONTACT
async def add_contact(pool: asyncpg.Pool, shop_id: int, data: ShopContactRegister,
                      current_user_id: int):
    shop = await shop_repo.get_shop_by_id(pool, shop_id)
    
    if not shop:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Negocio no encontrado.")
    
    if shop['dueno_id'] != current_user_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "No tienes permiso para editar este negocio")
    
    exist_contact = await contact_repo.get_contact_by_shop_and_red(
        pool, shop_id, data.nombre_red.value
    )
    
    if exist_contact:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"Ya existe un contacto de tipo '{data.nombre_red.value}' para este negocio"
        )
    
    contact = await contact_repo.create_contact(
        pool, shop_id, data.nombre_red.value, data.url
    )
    
    return contact

async def get_contacts_by_shop(pool: asyncpg.Pool, shop_id: int):
    conatcts = await contact_repo.get_contact_by_shop(pool, shop_id)
    return conatcts

#SERVICE FOR ADDRESS
async def get_address_by_shop(pool: asyncpg.Pool, shop_id: int):
    address = await address_repo.get_shop_address(pool, shop_id)
    return address

async def insert_address(pool:asyncpg.Pool, 
                         shop_id, current_user_id: int, 
                         data:ShopAddressRegister):
    shop = await shop_repo.get_shop_by_id(pool, shop_id)
    if not shop:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Negocio no encontrado.")
    
    if shop["dueno_id"] != current_user_id:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "No tienes permiso para editar este negocio.")
    
    exist_address = await address_repo.get_shop_address(pool, shop_id)
    
    if exist_address:
        raise HTTPException(status.HTTP_409_CONFLICT, 'Ya hay una direccion resgitrada')
    
    address = await address_repo.register_address(
        pool,
        shop_id,
        data.direccion_calle,
        data.ciudad,
        data.estado,
        data.codigo_postal,
        data.pais,
        data.latitud,
        data.longitud,
        data.osm_id,
        data.numero_local,
        data.numero_interior
    )
    
    return address
        
#SERVICE FOR SCHEDULE

async def get_weekly_schedule(pool: asyncpg.Pool, shop_id: int):
    schedule = await sche_repo.get_weekly_schedule(pool, shop_id)
    return schedule

async def insert_schedule(
    pool: asyncpg.Pool, shop_id: int, data: ShopRegisterSchedule, current_user_id:int
    ):
    shop = await shop_repo.get_shop_by_id(pool, shop_id)
    
    if not shop:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Negocio no encontrado.")
            
    if shop["dueno_id"] != current_user_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "No tienes permiso para ver este negocio.")
    
    exist_day = await sche_repo.get_day_by_shop_and_day(pool, shop_id, data.dia)
    
    if exist_day:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"""
                Ya existe el dia {data.dia} registrado. Si quiere modificarlo elija la opción 
                'Editar'
            """
        )
    
    schedule = await sche_repo.create_schedule(
        pool, shop_id, data.dia, data.hora_apertura, data.hora_cierre
    )
    
    return schedule

async def update_contact(
    pool: asyncpg.Pool, 
    shop_id: int, 
    contact_id: int, 
    data: ShopContactUpdate, 
    current_user_id: int
):
    # Verificar que el negocio existe y pertenece al usuario
    shop = await shop_repo.get_shop_by_id(pool, shop_id)
    if not shop:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Negocio no encontrado.")
    
    if shop['dueno_id'] != current_user_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "No tienes permiso para editar este negocio.")
    
    # Verificar que el contacto existe y pertenece al negocio
    contact = await contact_repo.get_contact_by_id(pool, contact_id)
    if not contact:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Contacto no encontrado.")
    
    if contact['negocio_id'] != shop_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "El contacto no pertenece a este negocio.")
    
    updated = await contact_repo.update_contact(pool, contact_id, data.url)
    return updated


async def delete_contact(
    pool: asyncpg.Pool, 
    shop_id: int, 
    contact_id: int, 
    current_user_id: int
):
    shop = await shop_repo.get_shop_by_id(pool, shop_id)
    if not shop:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Negocio no encontrado.")
    
    if shop['dueno_id'] != current_user_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "No tienes permiso.")
    
    contact = await contact_repo.get_contact_by_id(pool, contact_id)
    if not contact or contact['negocio_id'] != shop_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Contacto no encontrado.")
    
    await contact_repo.delete_contact(pool, contact_id)
    return {"message": "Contacto eliminado correctamente."}

async def edit_schedule(
    pool: asyncpg.Pool, 
    shop_id: int, 
    schedule_id: int, 
    data: ShopScheduleUpdate, 
    current_user_id: int
):
    shop = await shop_repo.get_shop_by_id(pool, shop_id)
    if not shop:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Negocio no encontrado.")
    
    if shop['dueno_id'] != current_user_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "No tienes permiso.")
    
    schedule = await sche_repo.get_schedule_by_id(pool, schedule_id)
    if not schedule or schedule['negocio_id'] != shop_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Horario no encontrado.")
    
    # Validación de horas
    if data.hora_apertura and data.hora_cierre:
        if data.hora_apertura >= data.hora_cierre:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST, 
                "La hora de apertura debe ser menor que la hora de cierre."
            )
    
    updated = await sche_repo.update_schedule(
        pool, schedule_id,
        data.hora_apertura, data.hora_cierre, 
        data.hora_descanso, data.estado_horario
    )
    return updated


async def delete_schedule(
    pool: asyncpg.Pool, 
    shop_id: int, 
    schedule_id: int, 
    current_user_id: int
):
    shop = await shop_repo.get_shop_by_id(pool, shop_id)
    if not shop or shop['dueno_id'] != current_user_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "No tienes permiso.")
    
    schedule = await sche_repo.get_schedule_by_id(pool, schedule_id)
    if not schedule or schedule['negocio_id'] != shop_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Horario no encontrado.")
    
    await sche_repo.delete_schedule(pool, schedule_id)
    return {"message": "Horario eliminado correctamente."}

async def delete_shop(pool: asyncpg.Pool, shop_id: int, current_user_id: int):
    shop = await shop_repo.get_shop_by_id(pool, shop_id)
    if not shop:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Negocio no encontrado.")
    
    if shop['dueno_id'] != current_user_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "No tienes permiso para eliminar este negocio.")
    
    deleted = await shop_repo.soft_delete_shop(pool, shop_id, current_user_id)
    return {"message": "Negocio desactivado correctamente.", "shop": dict(deleted)}

async def toggle_shop_status(
    pool: asyncpg.Pool, 
    shop_id: int, 
    estado: bool, 
    current_user_id: int
):
    shop = await shop_repo.get_shop_by_id(pool, shop_id)
    if not shop:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Negocio no encontrado.")
    
    if shop['dueno_id'] != current_user_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "No tienes permiso.")
    
    if estado:
        updated = await shop_repo.reactivate_shop(pool, shop_id, current_user_id)
    else:
        updated = await shop_repo.soft_delete_shop(pool, shop_id, current_user_id)
    
    return {
        "message": f"Negocio {'activado' if estado else 'desactivado'} correctamente.",
        "shop": dict(updated)
    }