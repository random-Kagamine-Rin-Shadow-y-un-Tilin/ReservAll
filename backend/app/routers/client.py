from fastapi import APIRouter, Depends, Query, Path, HTTPException, status
from app.core.dependencies import get_db_pool, verify_api_key, get_current_user
from app.models.client import (
    ShopView,
    ShopDetailView,
    CategoryView,
    AvailableTimesResponse,
    AvailableTimes,
    ReservationResponse,
    CreateReservationRequest,
    ServiceView,
)
from app.services import client_service
from typing import Optional
from datetime import date, time

import asyncpg

router = APIRouter(prefix="/client", tags=["client"], dependencies=[Depends(verify_api_key)])

# Catálogo de categorías (para las etiquetas de filtro)
@router.get('/categories', response_model=list[CategoryView])
async def list_categories(
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    return await client_service.list_categories(pool)

# Búsqueda unificada del catálogo (HU_34 a HU_41)
@router.get('/shops', response_model=list[ShopView])
async def search_catalog(
    q: Optional[str] = Query(
        None, min_length=2, max_length=100,
        description="Texto libre: nombre, descripción, categoría o servicio",
    ),
    categoria_id: Optional[int] = Query(
        None, ge=1, description="ID de categoría",
    ),
    categoria: Optional[str] = Query(
        None, min_length=2, max_length=100, description="Nombre de categoría",
    ),
    ciudad: Optional[str] = Query(
        None, min_length=2, max_length=100, description="Ciudad del negocio",
    ),
    lat: Optional[float] = Query(
        None, ge=-90, le=90, description="Latitud del cliente",
    ),
    lng: Optional[float] = Query(
        None, ge=-180, le=180, description="Longitud del cliente",
    ),
    radio_km: Optional[float] = Query(
        None, gt=0, le=500, description="Radio de búsqueda en kilómetros",
    ),
    precio_min: Optional[float] = Query(
        None, ge=0, description="Precio mínimo de algún servicio",
    ),
    precio_max: Optional[float] = Query(
        None, ge=0, description="Precio máximo de algún servicio",
    ),
    fecha: Optional[date] = Query(
        None, description="Filtra negocios con disponibilidad en esta fecha",
    ),
    hora: Optional[time] = Query(
        None, description="Hora deseada (HH:MM); requiere fecha",
    ),
    servicio_id: Optional[int] = Query(
        None, ge=1, description="Servicio requerido para el filtro de disponibilidad",
    ),
    orden: str = Query(
        "relevancia",
        description=(
            "relevancia | nombre | precio_asc | precio_desc | "
            "distancia | valoracion | populares"
        ),
    ),
    limit: int = Query(50, ge=1, le=200, description="Resultados por página"),
    offset: int = Query(0, ge=0, description="Desplazamiento de resultados"),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    return await client_service.search_catalog(
        pool,
        q=q,
        categoria_id=categoria_id,
        categoria=categoria,
        ciudad=ciudad,
        lat=lat,
        lng=lng,
        radio_km=radio_km,
        precio_min=precio_min,
        precio_max=precio_max,
        fecha=fecha,
        hora=hora,
        servicio_id=servicio_id,
        orden=orden,
        limit=limit,
        offset=offset,
    )

# Detalle público de un negocio (HU_40)
@router.get('/shops/{negocio_id}', response_model=ShopDetailView)
async def get_shop_detail(
    negocio_id: int = Path(..., description="ID del negocio"),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    return await client_service.get_shop_detail(pool, negocio_id)

# Traer todos los negocios (compatibilidad)
@router.get('/list-shops', response_model=list[ShopView])
async def list_shops(
    category: Optional[str] = Query(
        None, min_length=2, description="Nombre de categoría (compatibilidad)",
    ),
    categoria_id: Optional[int] = Query(None, ge=1),
    ciudad: Optional[str] = Query(None, min_length=2),
    orden: str = Query("relevancia"),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    return await client_service.list_shops(
        pool,
        categoria_id=categoria_id,
        categoria=category,
        ciudad=ciudad,
        orden=orden,
        limit=limit,
        offset=offset,
    )

# Buscador de negocios general (compatibilidad)
@router.get('/search', response_model=list[ShopView])
async def search_shops(
    q: str = Query(..., min_length=2, description="Término de búsqueda"),
    pool: asyncpg.Pool = Depends(get_db_pool)
):
    return await client_service.search_shops(pool, q)

# Buscador de negocios por nombre (compatibilidad)
@router.get('/search-by-name', response_model=list[ShopView])
async def search_shops_by_name(
    name: str = Query(..., min_length=2, description="Nombre del negocio"),
    pool: asyncpg.Pool = Depends(get_db_pool)
):
    return await client_service.search_shops_by_name(pool, name)

# Buscador de negocios por categoría (compatibilidad)
@router.get('/search-by-category', response_model=list[ShopView])
async def search_shops_by_category(
    category: str = Query(..., min_length=2, description="Categoría del negocio"),
    pool: asyncpg.Pool = Depends(get_db_pool)
):
    return await client_service.search_shops_by_category(pool, category)

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
    profesional_id: Optional[int] = Query(None, description="ID del profesional (opcional)"),
    intervalo_minutos: int = Query(30, ge=5, le=240, description="Intervalo de atención en minutos"),
    descanso_minutos: int = Query(60, ge=0, le=240, description="Duración del descanso en minutos"),
    pool: asyncpg.Pool = Depends(get_db_pool)
):
    return await client_service.get_available_times(
        pool,
        negocio_id,
        fecha,
        servicio_id,
        profesional_id,
        intervalo_minutos,
        descanso_minutos,
    )

#Obtener solo los horarios libres de un negocio en una fecha específica
@router.get('/{negocio_id}/available-times-only', response_model=list[AvailableTimes])
async def get_only_available_times(
    negocio_id: int = Path(..., description="ID del negocio"),
    fecha: date = Query(..., description="Fecha (YYYY-MM-DD)"),
    servicio_id: Optional[int] = Query(None, description="ID del servicio (opcional)"),
    profesional_id: Optional[int] = Query(None, description="ID del profesional (opcional)"),
    intervalo_minutos: int = Query(30, ge=5, le=240, description="Intervalo de atención en minutos"),
    descanso_minutos: int = Query(60, ge=0, le=240, description="Duración del descanso en minutos"),
    pool: asyncpg.Pool = Depends(get_db_pool)
):
    return await client_service.get_only_available_times(
        pool,
        negocio_id,
        fecha,
        servicio_id,
        profesional_id,
        intervalo_minutos,
        descanso_minutos,
    )

# Obtener horarios disponibles para un servicio específico
@router.get('/{negocio_id}/available-times-by-service', response_model=AvailableTimesResponse)
async def get_available_times_by_service(
    negocio_id: int = Path(..., description="ID del negocio"),
    fecha: date = Query(..., description="Fecha (YYYY-MM-DD)"),
    servicio_id: int = Query(..., description="ID del servicio"),
    profesional_id: Optional[int] = Query(None, description="ID del profesional (opcional)"),
    intervalo_minutos: int = Query(30, ge=5, le=240, description="Intervalo de atención en minutos"),
    descanso_minutos: int = Query(60, ge=0, le=240, description="Duración del descanso en minutos"),
    pool: asyncpg.Pool = Depends(get_db_pool)
):
    return await client_service.get_available_times_by_service(
        pool,
        negocio_id,
        fecha,
        servicio_id,
        profesional_id,
        intervalo_minutos,
        descanso_minutos,
    )

# Endpoints de reservas
@router.post('/create-reservation', response_model=ReservationResponse)
async def create_reservation(
    reservation: CreateReservationRequest,
    current_user = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool)
):
    # El cliente_id se obtiene del usuario autenticado
    cliente_id = int(current_user["sub"])
    
    return await client_service.create_reservation(
        pool,
        cliente_id,
        reservation.servicio_id,
        reservation.fecha,
        reservation.hora_inicio,
        reservation.profesional_id,
    )

# Endpoint para verificar disponibilidad
@router.get('/check-availability')
async def check_availability(
    negocio_id: int = Query(..., description="ID del negocio"),
    fecha: date = Query(..., description="Fecha (YYYY-MM-DD)"),
    hora_inicio: str = Query(..., description="Hora inicio (HH:MM)"),
    duracion_minutos: int = Query(..., description="Duración en minutos"),
    profesional_id: Optional[int] = Query(None, description="ID del profesional (opcional)"),
    descanso_minutos: int = Query(60, ge=0, le=240, description="Duración del descanso en minutos"),
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
        pool,
        negocio_id,
        fecha,
        hora_inicio_obj,
        duracion_minutos,
        profesional_id=profesional_id,
        descanso_minutos=descanso_minutos,
    )
    
    return {
        "negocio_id": negocio_id,
        "fecha": fecha,
        "hora_inicio": hora_inicio,
        "duracion_minutos": duracion_minutos,
        "profesional_id": profesional_id,
        "disponible": disponible
    }