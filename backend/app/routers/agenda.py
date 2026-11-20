from datetime import date
from typing import Optional

from fastapi import APIRouter, Depends, Query
import asyncpg

from app.core.dependencies import get_db_pool, verify_api_key, get_current_user
from app.models.agenda import (
    BlockCreate,
    BlockListOut,
    BlockOut,
    OwnerAgendaOut,
)
from app.services import agenda_service


router = APIRouter(
    prefix="/owner",
    tags=["agenda"],
    dependencies=[Depends(verify_api_key)],
)


@router.get("/{shop_id}/agenda", response_model=OwnerAgendaOut)
async def get_agenda(
    shop_id: int,
    fecha_desde: Optional[date] = Query(
        None, description="Fecha inicial del calendario (YYYY-MM-DD)"
    ),
    fecha_hasta: Optional[date] = Query(
        None, description="Fecha final del calendario (YYYY-MM-DD)"
    ),
    servicio_id: Optional[int] = Query(
        None, description="Calcula la disponibilidad con la duración de este servicio"
    ),
    profesional_id: Optional[int] = Query(
        None, description="Filtra reservas y disponibilidad por profesional"
    ),
    intervalo_minutos: int = Query(
        30, ge=5, le=240, description="Intervalo de atención en minutos"
    ),
    descanso_minutos: int = Query(
        60, ge=0, le=240, description="Duración del descanso en minutos"
    ),
    current_user: dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    return await agenda_service.get_agenda(
        pool,
        shop_id,
        int(current_user["sub"]),
        fecha_desde=fecha_desde,
        fecha_hasta=fecha_hasta,
        servicio_id=servicio_id,
        profesional_id=profesional_id,
        intervalo_minutos=intervalo_minutos,
        descanso_minutos=descanso_minutos,
    )


@router.get("/{shop_id}/blocks", response_model=BlockListOut)
async def list_blocks(
    shop_id: int,
    fecha_desde: Optional[date] = Query(
        None, description="Fecha inicial (YYYY-MM-DD)"
    ),
    fecha_hasta: Optional[date] = Query(
        None, description="Fecha final (YYYY-MM-DD)"
    ),
    current_user: dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    return await agenda_service.list_blocks(
        pool,
        shop_id,
        int(current_user["sub"]),
        fecha_desde=fecha_desde,
        fecha_hasta=fecha_hasta,
    )


@router.post("/{shop_id}/blocks", response_model=BlockOut, status_code=201)
async def create_block(
    shop_id: int,
    data: BlockCreate,
    current_user: dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    return await agenda_service.create_block(
        pool, shop_id, int(current_user["sub"]), data
    )


@router.delete("/{shop_id}/blocks/{block_id}")
async def delete_block(
    shop_id: int,
    block_id: int,
    current_user: dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    return await agenda_service.delete_block(
        pool, shop_id, block_id, int(current_user["sub"])
    )
