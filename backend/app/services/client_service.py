from fastapi import HTTPException, status
from app.models.client import ShopView, ShopSchedules, AvailableTimes, AvailableTimesResponse, DiaSemana, ReservationResponse, ServiceView
from app.repositories import client_repository as repo
from typing import Optional, List, Dict, Any  # Agregar Dict y Any
from datetime import date, time
import asyncpg

# mapeo de dias de la semana
DIAS_MAP = {
    0: DiaSemana.LUNES,
    1: DiaSemana.MARTES,
    2: DiaSemana.MIERCOLES,
    3: DiaSemana.JUEVES,
    4: DiaSemana.VIERNES,
    5: DiaSemana.SABADO,
    6: DiaSemana.DOMINGO
}

# Listado normal
async def list_shops(pool: asyncpg.Pool):
    shops = await repo.get_all_shops(pool)
    if not shops:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No hay negocios registrados"
        )
    return [dict(shop) for shop in shops]

#Listado con filtro de nombre
async def search_shops_by_name(pool: asyncpg.Pool, search_term: str):
    if not search_term or len(search_term.strip()) < 2:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El término de búsqueda debe tener al menos 2 caracteres"
        )
    
    shops = await repo.search_shops_by_name(pool, search_term.strip())
    if not shops:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No se encontraron negocios con '{search_term}'"
        )
    return [dict(shop) for shop in shops]

#Listado con filtro de categoria
async def search_shops_by_category(pool: asyncpg.Pool, category: str):
    if not category or len(category.strip()) < 2:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La categoría debe tener al menos 2 caracteres"
        )
    
    shops = await repo.search_shops_by_category(pool, category.strip())
    if not shops:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No se encontraron negocios en la categoría '{category}'"
        )
    return [dict(shop) for shop in shops]

#Listado con filtro de nombre o categoria
async def search_shops(pool: asyncpg.Pool, search_term: str):
    if not search_term or len(search_term.strip()) < 2:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El término de búsqueda debe tener al menos 2 caracteres"
        )
    
    shops = await repo.search_shops(pool, search_term.strip())
    if not shops:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No se encontraron negocios relacionados con '{search_term}'"
        )
    return [dict(shop) for shop in shops]

#Obtener datos de un negocio
SLOT_MINUTES = 30
BREAK_MINUTES = 60


def _to_minutes(value: time) -> int:
    return value.hour * 60 + value.minute


def _to_time(total_minutes: int) -> time:
    total_minutes %= 24 * 60
    return time(hour=total_minutes // 60, minute=total_minutes % 60)


def _overlaps(start: int, end: int, other_start: int, other_end: int) -> bool:
    return start < other_end and end > other_start


async def get_available_times(
    pool: asyncpg.Pool,
    negocio_id: int,
    fecha: date,
    servicio_id: Optional[int] = None
) -> AvailableTimesResponse:
    # 1. Verificar que el negocio existe
    negocio = await repo.get_negocio_by_id(pool, negocio_id)
    if not negocio:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El negocio no existe o no está activo"
        )

    # 2. Obtener el día de la semana en español
    dia_numero = fecha.weekday()
    dia_nombre = DIAS_MAP.get(dia_numero)
    if not dia_nombre:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Día no válido"
        )

    # 3. Obtener horarios del negocio para ese día
    horarios = await repo.get_horarios_by_negocio_dia(pool, negocio_id, dia_nombre)
    if not horarios:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No hay horarios disponibles para el negocio en {dia_nombre.value}"
        )

    # 4. Servicio solicitado (define la duración de cada espacio)
    duracion = SLOT_MINUTES
    if servicio_id is not None:
        servicio = await repo.get_servicio_by_id(pool, servicio_id)
        if not servicio:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="El servicio no existe"
            )
        if servicio['negocio_id'] != negocio_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El servicio no pertenece a este negocio"
            )
        duracion = servicio['duracion_minutos'] or SLOT_MINUTES

    # 5. Reservas existentes para esa fecha
    reservas = await repo.get_reservas_by_negocio_fecha(pool, negocio_id, fecha)
    ocupados = []
    for reserva in reservas:
        inicio = _to_minutes(reserva['hora_inicio'])
        if reserva['hora_fin'] is not None:
            fin = _to_minutes(reserva['hora_fin'])
        else:
            fin = inicio + (reserva['duracion_minutos'] or SLOT_MINUTES)
        ocupados.append((inicio, fin))

    # 6. Generar espacios de 30 minutos dentro de cada horario
    horarios_disponibles = []

    for horario in horarios:
        apertura = _to_minutes(horario['hora_apertura'])
        cierre = _to_minutes(horario['hora_cierre'])
        if cierre <= apertura:
            continue

        descanso = (
            _to_minutes(horario['hora_descanso'])
            if horario['hora_descanso'] is not None
            else None
        )

        slot = apertura
        while slot + duracion <= cierre:
            slot_fin = slot + duracion
            ocupado = any(
                _overlaps(slot, slot_fin, inicio, fin)
                for inicio, fin in ocupados
            )

            if (
                not ocupado
                and descanso is not None
                and _overlaps(slot, slot_fin, descanso, descanso + BREAK_MINUTES)
            ):
                ocupado = True

            horarios_disponibles.append(
                AvailableTimes(
                    id_horario=horario['id_horario'],
                    dia=horario['dia'],
                    hora_inicio=_to_time(slot),
                    hora_fin=_to_time(slot_fin),
                    disponible=not ocupado
                )
            )
            slot += SLOT_MINUTES

    if not horarios_disponibles:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No hay horarios disponibles para la fecha seleccionada"
        )

    return AvailableTimesResponse(
        negocio_id=negocio_id,
        nombre_negocio=negocio['nombre'],
        fecha=fecha,
        horarios_disponibles=horarios_disponibles
    )

#Obtener horarios disponibles de un negocio en una fecha con filtro por servicio
async def get_available_times_by_service(
    pool: asyncpg.Pool,
    negocio_id: int,
    fecha: date,
    servicio_id: int
) -> AvailableTimesResponse:
    # Verificar que el servicio existe
    servicio = await repo.get_servicio_by_id(pool, servicio_id)
    if not servicio:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El servicio no existe"
        )
    
    return await get_available_times(pool, negocio_id, fecha, servicio_id)

#Obtener horarios disponibles de un negocio en una fecha
async def get_only_available_times(
    pool: asyncpg.Pool,
    negocio_id: int,
    fecha: date,
    servicio_id: Optional[int] = None
) -> List[AvailableTimes]:
    response = await get_available_times(pool, negocio_id, fecha, servicio_id)
    horarios_libres = [h for h in response.horarios_disponibles if h.disponible]
    
    if not horarios_libres:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No hay horarios disponibles para la fecha seleccionada"
        )
    
    return horarios_libres

#Obtener servicios de un negocio - CORREGIDO
async def get_services_by_negocio(
    pool: asyncpg.Pool,
    negocio_id: int
) -> List[ServiceView]:
    servicios = await repo.get_servicios_by_negocio(pool, negocio_id)
    if not servicios:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El negocio no tiene servicios registrados"
        )
    # CORRECCIÓN: Convertir cada fila a ServiceView, no a dict
    return [ServiceView(**dict(servicio)) for servicio in servicios]

# Crear una nueva reserva - CORREGIDO
async def create_reservation(
    pool: asyncpg.Pool,
    cliente_id: int,
    servicio_id: int,
    fecha: date,
    hora_inicio: time
) -> ReservationResponse:
    # 1. Verificar que el servicio existe
    servicio = await repo.get_servicio_by_id(pool, servicio_id)
    if not servicio:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El servicio no existe"
        )

    duracion = servicio['duracion_minutos'] or SLOT_MINUTES
    hora_fin = _to_time(_to_minutes(hora_inicio) + duracion)

    # 2. Verificar que el horario está disponible
    negocio_id = servicio['negocio_id']
    disponible = await check_availability(
        pool, negocio_id, fecha, hora_inicio, duracion
    )
    
    if not disponible:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El horario seleccionado no está disponible"
        )
    
    # 3. Crear la reserva
    reserva = await repo.create_reserva(
        pool, cliente_id, servicio_id, fecha, hora_inicio, hora_fin
    )
    
    if not reserva:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error al crear la reserva"
        )
    
    # CORRECCIÓN: Convertir a ReservationResponse
    return ReservationResponse(**dict(reserva))

#  Verificar si un horario específico está disponible
async def check_availability(
    pool: asyncpg.Pool,
    negocio_id: int,
    fecha: date,
    hora_inicio: time,
    duracion_minutos: int
) -> bool:
    inicio = _to_minutes(hora_inicio)
    fin = inicio + duracion_minutos

    dia_nombre = DIAS_MAP.get(fecha.weekday())
    if not dia_nombre:
        return False

    horarios = await repo.get_horarios_by_negocio_dia(
        pool, negocio_id, dia_nombre.value
    )
    if not horarios:
        return False

    dentro_de_horario = False
    for horario in horarios:
        apertura = _to_minutes(horario['hora_apertura'])
        cierre = _to_minutes(horario['hora_cierre'])
        if cierre <= apertura or inicio < apertura or fin > cierre:
            continue

        descanso = (
            _to_minutes(horario['hora_descanso'])
            if horario['hora_descanso'] is not None
            else None
        )
        if (
            descanso is None
            or not _overlaps(inicio, fin, descanso, descanso + BREAK_MINUTES)
        ):
            dentro_de_horario = True
            break

    if not dentro_de_horario:
        return False

    reservas = await repo.get_reservas_by_negocio_fecha(pool, negocio_id, fecha)

    for reserva in reservas:
        reserva_inicio = _to_minutes(reserva['hora_inicio'])
        if reserva['hora_fin'] is not None:
            reserva_fin = _to_minutes(reserva['hora_fin'])
        else:
            reserva_fin = reserva_inicio + (
                reserva['duracion_minutos'] or SLOT_MINUTES
            )
        if _overlaps(inicio, fin, reserva_inicio, reserva_fin):
            return False
    
    return True