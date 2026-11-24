from fastapi import HTTPException, status
from app.models.shop import ShopRegister, ShopEdit
from app.models.shop_contact import ShopContactRegister, ShopContactUpdate
from app.models.shop_schedule import ShopRegisterSchedule, ShopScheduleUpdate
from app.models.shop_address import ShopAddressRegister, ShopAddressUpdate
from app.core.schedule_utils import normalize_day, to_minutes
from app.repositories import shop_repository as shop_repo
from app.repositories import category_repository as category_repo
from app.repositories import shop_contact_repository as contact_repo
from app.repositories import shop_schedule_repository as sche_repo
from app.repositories import shop_address_repository as address_repo

import asyncpg


async def _ensure_categoria_activa(pool: asyncpg.Pool, categoria_id: int) -> None:
    """HU_14: un negocio solo puede asociarse a una categoría vigente."""

    categoria = await category_repo.get_category_by_id(pool, int(categoria_id))
    if not categoria:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND, "La categoría seleccionada no existe."
        )
    if categoria["estado"] is False:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "La categoría seleccionada está desactivada.",
        )


#GENERAL SHOP ACTIONS
async def register_shop(pool: asyncpg.pool, data: ShopRegister, current_user_id: int, rol: str):
    if rol != "negocio":
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Solo los usuarios tipo negocio pueden registrar un negocio."
        )

    await _ensure_categoria_activa(pool, data.categoria_negocio)

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

    await _ensure_categoria_activa(pool, data.fk_categoria)

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
    schedule = await get_weekly_schedule(pool, shop_id, include_inactive=False)
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
        data.numero_interior or None
    )

    return address


async def edit_address(
    pool: asyncpg.Pool,
    shop_id: int,
    current_user_id: int,
    data: ShopAddressUpdate,
):
    """Corrige o mueve la ubicación ya registrada de un negocio."""

    shop = await shop_repo.get_shop_by_id(pool, shop_id)
    if not shop:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Negocio no encontrado.")

    if shop["dueno_id"] != current_user_id:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "No tienes permiso para editar este negocio.",
        )

    existing = await address_repo.get_shop_address(pool, shop_id)
    if not existing:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "El negocio todavía no tiene una dirección registrada.",
        )

    fields = data.model_dump(exclude_unset=True)
    if not fields:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "No hay cambios para guardar.",
        )

    non_nullable = {
        "direccion_calle",
        "ciudad",
        "estado",
        "codigo_postal",
        "pais",
        "latitud",
        "longitud",
        "numero_local",
    }
    for column in non_nullable.intersection(fields):
        if fields[column] is None:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                f"El campo '{column}' no puede ser nulo.",
            )

    if "numero_interior" in fields and fields["numero_interior"] == "":
        fields["numero_interior"] = None

    updated = await address_repo.update_address(pool, shop_id, fields)
    if not updated:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "El negocio todavía no tiene una dirección registrada.",
        )
    return updated


#SERVICE FOR SCHEDULE

def _validate_schedule_hours(apertura, cierre, descanso, descanso_duracion_min: int = 60):
    if apertura >= cierre:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "La hora de apertura debe ser menor que la hora de cierre.",
        )
    if descanso is not None:
        if not (apertura <= descanso < cierre):
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                "La hora de descanso debe estar dentro del horario de atención.",
            )
        fin_descanso = to_minutes(descanso) + descanso_duracion_min
        if fin_descanso > to_minutes(cierre):
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                "El descanso debe terminar antes del cierre del horario.",
            )


def _validate_no_overlap(nuevo, existentes) -> None:
    """Permite varios turnos por día siempre que no se solapen."""

    inicio = to_minutes(nuevo["hora_apertura"])
    fin = to_minutes(nuevo["hora_cierre"])
    for otro in existentes:
        if otro["estado_horario"] is False:
            continue
        otro_inicio = to_minutes(otro["hora_apertura"])
        otro_fin = to_minutes(otro["hora_cierre"])
        if inicio < otro_fin and fin > otro_inicio:
            raise HTTPException(
                status.HTTP_409_CONFLICT,
                "El turno se solapa con otro horario configurado para ese día.",
            )


async def get_weekly_schedule(
    pool: asyncpg.Pool, shop_id: int, include_inactive: bool = True
):
    schedule = await sche_repo.get_weekly_schedule(
        pool, shop_id, include_inactive=include_inactive
    )
    return schedule


async def insert_schedule(
    pool: asyncpg.Pool, shop_id: int, data: ShopRegisterSchedule, current_user_id:int
    ):
    shop = await shop_repo.get_shop_by_id(pool, shop_id)

    if not shop:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Negocio no encontrado.")

    if shop["dueno_id"] != current_user_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "No tienes permiso para editar este negocio.")

    day = normalize_day(data.dia)
    _validate_schedule_hours(
        data.hora_apertura,
        data.hora_cierre,
        data.hora_descanso,
        data.descanso_duracion_min,
    )

    # HU_25: se permiten varios turnos por día (mañana/tarde). Solo se
    # rechazan los que se solapan con un turno ya activo.
    existentes = await sche_repo.get_schedules_by_shop_and_day(pool, shop_id, day)
    _validate_no_overlap(
        {
            "hora_apertura": data.hora_apertura,
            "hora_cierre": data.hora_cierre,
        },
        existentes,
    )

    schedule = await sche_repo.create_schedule(
        pool,
        shop_id,
        day,
        data.hora_apertura,
        data.hora_cierre,
        data.hora_descanso,
        data.descanso_duracion_min,
        data.estado_horario,
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

    fields = data.model_dump(exclude_unset=True)
    if not fields:
        return schedule

    if "hora_apertura" in fields and fields["hora_apertura"] is None:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "La hora de apertura no puede ser nula.",
        )
    if "hora_cierre" in fields and fields["hora_cierre"] is None:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "La hora de cierre no puede ser nula.",
        )
    for campo in ("estado_horario", "descanso_duracion_min"):
        if campo in fields and fields[campo] is None:
            fields.pop(campo)

    apertura = fields.get("hora_apertura", schedule["hora_apertura"])
    cierre = fields.get("hora_cierre", schedule["hora_cierre"])
    descanso = (
        fields["hora_descanso"]
        if "hora_descanso" in fields
        else schedule["hora_descanso"]
    )
    duracion = fields.get(
        "descanso_duracion_min",
        (
            schedule["descanso_duracion_min"]
            if schedule.get("descanso_duracion_min") is not None
            else 60
        ),
    )
    _validate_schedule_hours(apertura, cierre, descanso, duracion)

    turnos = await sche_repo.get_schedules_by_shop_and_day(
        pool, shop_id, schedule["dia"]
    )
    otros = [turno for turno in turnos if turno["id_horario"] != schedule_id]
    _validate_no_overlap(
        {"hora_apertura": apertura, "hora_cierre": cierre},
        otros,
    )

    updated = await sche_repo.update_schedule(pool, schedule_id, fields)
    return updated


async def delete_schedule(
    pool: asyncpg.Pool,
    shop_id: int,
    schedule_id: int,
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