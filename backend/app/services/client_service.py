from fastapi import HTTPException, status
from app.models.client import ShopView, ShopSchedules, AvailableTimes, AvailableTimesResponse, DiaSemana, ReservationResponse, ServiceView
from app.repositories import client_repository as repo
from typing import Optional, List, Dict, Any  # Agregar Dict y Any
from datetime import date, time, datetime, timedelta
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
            detail=f"No hay horarios disponibles para el negocio en {dia_nombre}"
        )
    
    # 4. Obtener reservas existentes para esa fecha
    reservas = await repo.get_reservas_by_negocio_fecha(pool, negocio_id, fecha)
    
    # 5. Crear set de horarios ocupados
    reservas_set = set()
    for reserva in reservas:
        hora_inicio = reserva['hora_inicio']
        duracion = reserva['duracion_minutos']
        hora_fin = (datetime.combine(fecha, hora_inicio) + timedelta(minutes=duracion)).time()
        
        # Marcar todas las horas ocupadas durante la duración del servicio
        current = hora_inicio
        while current < hora_fin:
            reservas_set.add(current.strftime('%H:%M'))
            # Avanzar en intervalos de 30 minutos (o según tu lógica)
            current = (datetime.combine(fecha, current) + timedelta(minutes=30)).time()
    
    # 6. Procesar y filtrar horarios disponibles
    horarios_disponibles = []
    
    for horario in horarios:
        hora_inicio = horario['hora_inicio']
        hora_fin = horario['hora_fin']
        
        # Verificar si este horario está ocupado
        hora_inicio_str = hora_inicio.strftime('%H:%M')
        hora_fin_str = hora_fin.strftime('%H:%M')
        
        # Verificar si alguna parte del horario está ocupada
        ocupado = False
        current = hora_inicio
        while current < hora_fin:
            if current.strftime('%H:%M') in reservas_set:
                ocupado = True
                break
            current = (datetime.combine(fecha, current) + timedelta(minutes=30)).time()
        
        # Si se especificó un servicio, verificar que la duración quepa
        if servicio_id and not ocupado:
            servicio = await repo.get_servicio_by_id(pool, servicio_id)
            if servicio:
                duracion = servicio['duracion_minutos']
                # Verificar que la duración del servicio quepa en el horario
                inicio_dt = datetime.combine(fecha, hora_inicio)
                fin_dt = datetime.combine(fecha, hora_fin)
                if (fin_dt - inicio_dt).total_seconds() / 60 < duracion:
                    ocupado = True  # No cabe el servicio en este horario
        
        available_time = AvailableTimes(
            id_horario=horario['id_horario'],
            dia=horario['dia'],
            hora_inicio=hora_inicio,
            hora_fin=hora_fin,
            disponible=not ocupado
        )
        horarios_disponibles.append(available_time)
    
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
    
    # 2. Verificar que el horario está disponible
    negocio_id = servicio['negocio_id']
    disponible = await check_availability(
        pool, negocio_id, fecha, hora_inicio, servicio['duracion_minutos']
    )
    
    if not disponible:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El horario seleccionado no está disponible"
        )
    
    # 3. Crear la reserva
    reserva = await repo.create_reserva(
        pool, cliente_id, servicio_id, fecha, hora_inicio
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
    # Calcular hora fin
    hora_fin = (datetime.combine(fecha, hora_inicio) + timedelta(minutes=duracion_minutos)).time()
    
    # Verificar si hay reservas que se crucen
    reservas = await repo.get_reservas_by_negocio_fecha(pool, negocio_id, fecha)
    
    for reserva in reservas:
        reserva_inicio = reserva['hora_inicio']
        reserva_duracion = reserva['duracion_minutos']
        reserva_fin = (datetime.combine(fecha, reserva_inicio) + timedelta(minutes=reserva_duracion)).time()
        
        # Verificar si hay cruce de horarios
        if hora_inicio < reserva_fin and hora_fin > reserva_inicio:
            return False
    
    return True