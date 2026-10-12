from fastapi import APIRouter, Depends, Query, Path, HTTPException, status
from app.core.dependencies import get_db_pool, verify_api_key, get_current_user
from app.models.client import ShopView, AvailableTimesResponse, AvailableTimes, ShopSchedules, ReservationResponse, CreateReservationRequest, ServiceView, ShopSearchParams
from app.services import client_service
from app.repositories import client_repository as repo
from typing import Optional, List
from datetime import date

import asyncpg

router = APIRouter(prefix="/client", tags=["client"], dependencies=[Depends(verify_api_key)])

# Traer todos los negocios
@router.get('/list-shops', response_model=list[ShopView])
async def list_shops(
    pool: asyncpg.Pool = Depends(get_db_pool)
    ):
    
    shops = await client_service.list_shops(pool)
    return shops

# Buscador de negocios general
@router.get('/search', response_model=list[ShopView])
async def search_shops(
    q: str = Query(..., min_length=2, description="Término de búsqueda"),
    pool: asyncpg.Pool = Depends(get_db_pool)
):
    shops = await client_service.search_shops(pool, q)
    return shops

# Buscador de negocios por nombre
@router.get('/search-by-name', response_model=list[ShopView])
async def search_shops_by_name(
    name: str = Query(..., min_length=2, description="Nombre del negocio"),
    pool: asyncpg.Pool = Depends(get_db_pool)
):
    shops = await client_service.search_shops_by_name(pool, name)
    return shops

# Buscador de negocios por categoría
@router.get('/search-by-category', response_model=list[ShopView])
async def search_shops_by_category(
    category: str = Query(..., min_length=2, description="Categoría del negocio"),
    pool: asyncpg.Pool = Depends(get_db_pool)
):
    shops = await client_service.search_shops_by_category(pool, category)
    return shops

#Obtener servicios de un negocio
@router.get('/{negocio_id}/servicios', response_model=list[ServiceView])
async def get_services_by_negocio(
    negocio_id: int = Path(..., description="ID del negocio"),
    pool: asyncpg.Pool = Depends(get_db_pool)
):
    return await client_service.get_services_by_negocio(pool, negocio_id)

# Endpoints de horarios
@router.get('/{negocio_id}/available-times', response_model=AvailableTimesResponse)
async def get_available_times(
    negocio_id: int = Path(..., description="ID del negocio"),
    fecha: date = Query(..., description="Fecha (YYYY-MM-DD)"),
    servicio_id: Optional[int] = Query(None, description="ID del servicio (opcional)"),
    pool: asyncpg.Pool = Depends(get_db_pool)
):
    return await client_service.get_available_times(pool, negocio_id, fecha, servicio_id)

#Obtener solo los horarios libres de un negocio en una fecha específica
@router.get('/{negocio_id}/available-times-only', response_model=list[AvailableTimes])
async def get_only_available_times(
    negocio_id: int = Path(..., description="ID del negocio"),
    fecha: date = Query(..., description="Fecha (YYYY-MM-DD)"),
    servicio_id: Optional[int] = Query(None, description="ID del servicio (opcional)"),
    pool: asyncpg.Pool = Depends(get_db_pool)
):
    return await client_service.get_only_available_times(pool, negocio_id, fecha, servicio_id)

# Obtener horarios disponibles para un servicio específico
@router.get('/{negocio_id}/available-times-by-service', response_model=AvailableTimesResponse)
async def get_available_times_by_service(
    negocio_id: int = Path(..., description="ID del negocio"),
    fecha: date = Query(..., description="Fecha (YYYY-MM-DD)"),
    servicio_id: int = Query(..., description="ID del servicio"),
    pool: asyncpg.Pool = Depends(get_db_pool)
):
    return await client_service.get_available_times_by_service(pool, negocio_id, fecha, servicio_id)

# Endpoints de reservas
@router.post('/create-reservation', response_model=ReservationResponse)
async def create_reservation(
    reservation: CreateReservationRequest,
    current_user = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool)
):
    # El cliente_id se obtiene del usuario autenticado
    cliente_id = current_user['id']  # Asumiendo que el usuario autenticado es el cliente
    
    return await client_service.create_reservation(
        pool,
        cliente_id,
        reservation.servicio_id,
        reservation.fecha,
        reservation.hora_inicio
    )

# Endpoint para verificar disponibilidad
@router.get('/check-availability')
async def check_availability(
    negocio_id: int = Query(..., description="ID del negocio"),
    fecha: date = Query(..., description="Fecha (YYYY-MM-DD)"),
    hora_inicio: str = Query(..., description="Hora inicio (HH:MM)"),
    duracion_minutos: int = Query(..., description="Duración en minutos"),
    pool: asyncpg.Pool = Depends(get_db_pool)
):
    from datetime import datetime
    
    try:
        hora_inicio_obj = datetime.strptime(hora_inicio, '%H:%M').time()
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Formato de hora inválido. Use HH:MM"
        )
    
    disponible = await client_service.check_availability(
        pool, negocio_id, fecha, hora_inicio_obj, duracion_minutos
    )
    
    return {
        "negocio_id": negocio_id,
        "fecha": fecha,
        "hora_inicio": hora_inicio,
        "duracion_minutos": duracion_minutos,
        "disponible": disponible
    }