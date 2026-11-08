from fastapi import APIRouter, Depends, Query
from typing import Optional
from datetime import date

import asyncpg

from app.core.dependencies import get_db_pool, verify_api_key, get_current_user
from app.models.client import EstadoReserva
from app.models.owner import (
    ClientListOut,
    OwnerClientDetailOut,
    OwnerReportOut,
    OwnerReservationOut,
    ReservationListOut,
    ReservationRejectRequest,
    ReservationStatusUpdate,
)
from app.services import owner_service

router = APIRouter(
    prefix="/owner",
    tags=["owner"],
    dependencies=[Depends(verify_api_key)],
)


@router.get("/{shop_id}/reservations", response_model=ReservationListOut)
async def list_reservations(
    shop_id: int,
    fecha_desde: Optional[date] = Query(None, description="Fecha inicial (YYYY-MM-DD)"),
    fecha_hasta: Optional[date] = Query(None, description="Fecha final (YYYY-MM-DD)"),
    estado: Optional[EstadoReserva] = Query(None, description="Estado de la reserva"),
    profesional_id: Optional[int] = Query(None, description="Filtra por profesional"),
    search: Optional[str] = Query(
        None, max_length=100, description="Nombre o correo del cliente"
    ),
    current_user: dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    return await owner_service.list_reservations(
        pool,
        shop_id,
        int(current_user["sub"]),
        fecha_desde=fecha_desde,
        fecha_hasta=fecha_hasta,
        estado=estado.value if estado else None,
        profesional_id=profesional_id,
        search=search,
    )


@router.get(
    "/{shop_id}/reservations/history",
    response_model=ReservationListOut,
)
async def list_reservation_history(
    shop_id: int,
    fecha_desde: Optional[date] = Query(None, description="Fecha inicial (YYYY-MM-DD)"),
    fecha_hasta: Optional[date] = Query(None, description="Fecha final (YYYY-MM-DD)"),
    estado: Optional[EstadoReserva] = Query(None, description="Estado de la reserva"),
    profesional_id: Optional[int] = Query(None, description="Filtra por profesional"),
    search: Optional[str] = Query(
        None, max_length=100, description="Nombre o correo del cliente"
    ),
    current_user: dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    return await owner_service.list_reservation_history(
        pool,
        shop_id,
        int(current_user["sub"]),
        fecha_desde=fecha_desde,
        fecha_hasta=fecha_hasta,
        estado=estado.value if estado else None,
        profesional_id=profesional_id,
        search=search,
    )


@router.get(
    "/{shop_id}/reservations/{reservation_id}",
    response_model=OwnerReservationOut,
)
async def get_reservation(
    shop_id: int,
    reservation_id: int,
    current_user: dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    return await owner_service.get_reservation(
        pool, shop_id, reservation_id, int(current_user["sub"])
    )


@router.patch(
    "/{shop_id}/reservations/{reservation_id}/status",
    response_model=OwnerReservationOut,
)
async def update_reservation_status(
    shop_id: int,
    reservation_id: int,
    data: ReservationStatusUpdate,
    current_user: dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    return await owner_service.update_reservation_status(
        pool,
        shop_id,
        reservation_id,
        int(current_user["sub"]),
        data.estado.value,
        motivo=data.motivo,
    )


# HU_44: confirmar una reserva
@router.post(
    "/{shop_id}/reservations/{reservation_id}/confirm",
    response_model=OwnerReservationOut,
)
async def confirm_reservation(
    shop_id: int,
    reservation_id: int,
    current_user: dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    return await owner_service.confirm_reservation(
        pool, shop_id, reservation_id, int(current_user["sub"])
    )


# HU_45: rechazar una reserva (motivo opcional)
@router.post(
    "/{shop_id}/reservations/{reservation_id}/reject",
    response_model=OwnerReservationOut,
)
async def reject_reservation(
    shop_id: int,
    reservation_id: int,
    data: ReservationRejectRequest | None = None,
    current_user: dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    return await owner_service.reject_reservation(
        pool,
        shop_id,
        reservation_id,
        int(current_user["sub"]),
        data.motivo if data else None,
    )


# HU_52: completar una reserva
@router.post(
    "/{shop_id}/reservations/{reservation_id}/complete",
    response_model=OwnerReservationOut,
)
async def complete_reservation(
    shop_id: int,
    reservation_id: int,
    current_user: dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    return await owner_service.complete_reservation(
        pool, shop_id, reservation_id, int(current_user["sub"])
    )


@router.get("/{shop_id}/clients", response_model=ClientListOut)
async def list_clients(
    shop_id: int,
    search: Optional[str] = Query(
        None, max_length=100, description="Nombre o correo del cliente"
    ),
    current_user: dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    return await owner_service.list_clients(
        pool, shop_id, int(current_user["sub"]), search=search
    )


@router.get(
    "/{shop_id}/clients/{client_id}",
    response_model=OwnerClientDetailOut,
)
async def get_client(
    shop_id: int,
    client_id: int,
    current_user: dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    return await owner_service.get_client(
        pool, shop_id, client_id, int(current_user["sub"])
    )


@router.get("/{shop_id}/reports/summary", response_model=OwnerReportOut)
async def get_report(
    shop_id: int,
    fecha_desde: Optional[date] = Query(None, description="Fecha inicial (YYYY-MM-DD)"),
    fecha_hasta: Optional[date] = Query(None, description="Fecha final (YYYY-MM-DD)"),
    current_user: dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    return await owner_service.get_report(
        pool,
        shop_id,
        int(current_user["sub"]),
        fecha_desde=fecha_desde,
        fecha_hasta=fecha_hasta,
    )
