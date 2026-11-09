from fastapi import HTTPException, status
from app.models.client import (
    AvailableTimes,
    AvailableTimesResponse,
    ClientReservationListOut,
    ClientReservationOut,
    DiaSemana,
    ReservationResponse,
    ServiceView,
)
from app.repositories import client_repository as repo
from app.repositories import agenda_repository as agenda_repo
from app.repositories import shop_address_repository as address_repo
from app.repositories import shop_schedule_repository as schedule_repo
from app.core.schedule_utils import (
    build_slots,
    day_for_date,
    overlaps,
    to_minutes,
    to_time,
)
from app.services import agenda_service
from typing import Optional, List
from datetime import date, datetime, time
import asyncpg

# mapeo de dias de la semana (compatibilidad con código existente)
DIAS_MAP = {
    0: DiaSemana.LUNES,
    1: DiaSemana.MARTES,
    2: DiaSemana.MIERCOLES,
    3: DiaSemana.JUEVES,
    4: DiaSemana.VIERNES,
    5: DiaSemana.SABADO,
    6: DiaSemana.DOMINGO,
}

ORDENES_VALIDOS = {
    "relevancia",
    "nombre",
    "precio_asc",
    "precio_desc",
    "distancia",
    "valoracion",
    "populares",
}


def _validate_search_filters(
    *,
    q: Optional[str],
    lat: Optional[float],
    lng: Optional[float],
    radio_km: Optional[float],
    precio_min: Optional[float],
    precio_max: Optional[float],
    orden: str,
) -> None:
    if q is not None and len(q.strip()) < 2:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El término de búsqueda debe tener al menos 2 caracteres",
        )

    if (lat is None) != (lng is None):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Debes enviar latitud y longitud juntas.",
        )

    if radio_km is not None:
        if lat is None or lng is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El radio de búsqueda requiere latitud y longitud.",
            )
        if radio_km <= 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El radio de búsqueda debe ser mayor que cero.",
            )

    if precio_min is not None and precio_min < 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El precio mínimo no puede ser negativo.",
        )

    if precio_max is not None and precio_max < 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El precio máximo no puede ser negativo.",
        )

    if (
        precio_min is not None
        and precio_max is not None
        and precio_min > precio_max
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El precio mínimo no puede ser mayor que el máximo.",
        )

    if orden not in ORDENES_VALIDOS:
        opciones = ", ".join(sorted(ORDENES_VALIDOS))
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Orden inválido. Usa uno de: {opciones}.",
        )

    if orden == "distancia" and (lat is None or lng is None):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El orden por distancia requiere latitud y longitud.",
        )


def _shop_to_dict(shop) -> dict:
    data = dict(shop)
    if not data.get("direccion"):
        data["direccion"] = None
    return data


async def _filter_by_availability(
    pool: asyncpg.Pool,
    shops: list[dict],
    fecha: date,
    hora: Optional[time],
    servicio_id: Optional[int],
) -> list[dict]:
    """Conserva los negocios con al menos un espacio libre.

    Reutiliza la misma lógica de disponibilidad que usa el flujo de reservas
    (horarios, descansos, bloqueos, reservas y duración del servicio). Es una
    comprobación por negocio, por lo que se aplica sobre la página ya filtrada.
    """

    disponibles: list[dict] = []
    for shop in shops:
        try:
            response = await get_available_times(
                pool,
                shop["id"],
                fecha,
                servicio_id=servicio_id,
            )
        except HTTPException:
            # Sin horarios para ese día, negocio bloqueado, servicio ajeno, etc.
            continue

        slots = [slot for slot in response.horarios_disponibles if slot.disponible]
        if hora is not None:
            slots = [
                slot
                for slot in slots
                if slot.hora_inicio <= hora < slot.hora_fin
            ]

        if slots:
            shop["disponible"] = True
            disponibles.append(shop)

    return disponibles


async def search_catalog(
    pool: asyncpg.Pool,
    *,
    q: Optional[str] = None,
    categoria_id: Optional[int] = None,
    categoria: Optional[str] = None,
    ciudad: Optional[str] = None,
    lat: Optional[float] = None,
    lng: Optional[float] = None,
    radio_km: Optional[float] = None,
    precio_min: Optional[float] = None,
    precio_max: Optional[float] = None,
    fecha: Optional[date] = None,
    hora: Optional[time] = None,
    servicio_id: Optional[int] = None,
    orden: str = "relevancia",
    limit: int = 50,
    offset: int = 0,
) -> list[dict]:
    """Búsqueda unificada del catálogo de negocios (HU_34 a HU_41)."""

    _validate_search_filters(
        q=q,
        lat=lat,
        lng=lng,
        radio_km=radio_km,
        precio_min=precio_min,
        precio_max=precio_max,
        orden=orden,
    )

    if hora is not None and fecha is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Debes indicar la fecha para filtrar por hora.",
        )

    shops = await repo.search_shops_catalog(
        pool,
        q=q.strip() if q else None,
        categoria_id=categoria_id,
        categoria=categoria.strip() if categoria else None,
        ciudad=ciudad.strip() if ciudad else None,
        lat=lat,
        lng=lng,
        radio_km=radio_km,
        precio_min=precio_min,
        precio_max=precio_max,
        orden=orden,
        limit=limit,
        offset=offset,
    )
    result = [_shop_to_dict(shop) for shop in shops]

    if fecha is not None:
        result = await _filter_by_availability(
            pool, result, fecha, hora, servicio_id
        )

    return result


async def list_categories(pool: asyncpg.Pool) -> list[dict]:
    categories = await repo.get_categories(pool)
    return [dict(category) for category in categories]


async def get_shop_detail(pool: asyncpg.Pool, negocio_id: int) -> dict:
    shop = await repo.get_negocio_by_id(pool, negocio_id)
    if not shop:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El negocio no existe o no está activo.",
        )

    address = await address_repo.get_shop_address(pool, negocio_id)
    schedule = await schedule_repo.get_weekly_schedule(
        pool, negocio_id, include_inactive=False
    )
    services = await repo.get_servicios_by_negocio(pool, negocio_id)

    return {
        "general": _shop_to_dict(shop),
        "direccion": dict(address) if address else None,
        "horarios": [dict(item) for item in schedule],
        "servicios": [dict(item) for item in services],
    }


# Listado normal (compatibilidad con /client/list-shops)
async def list_shops(
    pool: asyncpg.Pool,
    *,
    categoria_id: Optional[int] = None,
    categoria: Optional[str] = None,
    ciudad: Optional[str] = None,
    orden: str = "relevancia",
    limit: int = 50,
    offset: int = 0,
):
    return await search_catalog(
        pool,
        categoria_id=categoria_id,
        categoria=categoria,
        ciudad=ciudad,
        orden=orden,
        limit=limit,
        offset=offset,
    )


# Listado con filtro de nombre
async def search_shops_by_name(pool: asyncpg.Pool, search_term: str):
    return await search_catalog(pool, q=search_term)


# Listado con filtro de categoría
async def search_shops_by_category(pool: asyncpg.Pool, category: str):
    return await search_catalog(pool, categoria=category)


# Listado con filtro de nombre o categoría
async def search_shops(pool: asyncpg.Pool, search_term: str):
    return await search_catalog(pool, q=search_term)


# Disponibilidad --------------------------------------------------------------
SLOT_MINUTES = 30
BREAK_MINUTES = 60


def _validate_slot_params(intervalo_minutos: int, descanso_minutos: int) -> None:
    if intervalo_minutos < 5 or intervalo_minutos > 240:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "El intervalo de atención debe estar entre 5 y 240 minutos.",
        )
    if descanso_minutos < 0 or descanso_minutos > 240:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "La duración del descanso debe estar entre 0 y 240 minutos.",
        )


def _reservation_intervals(reservas) -> list[tuple[int, int]]:
    intervals: list[tuple[int, int]] = []
    for reserva in reservas:
        inicio = to_minutes(reserva["hora_inicio"])
        if reserva["hora_fin"] is not None:
            fin = to_minutes(reserva["hora_fin"])
        else:
            fin = inicio + (reserva["duracion_minutos"] or SLOT_MINUTES)
        intervals.append((inicio, fin))
    return intervals


def _time_block_intervals(bloqueos) -> list[tuple[int, int]]:
    intervals: list[tuple[int, int]] = []
    for bloqueo in bloqueos:
        if bloqueo["hora_inicio"] is None or bloqueo["hora_fin"] is None:
            continue
        intervals.append(
            (
                to_minutes(bloqueo["hora_inicio"]),
                to_minutes(bloqueo["hora_fin"]),
            )
        )
    return intervals


def _map_slots(horario, slots) -> list[AvailableTimes]:
    return [
        AvailableTimes(
            id_horario=horario["id_horario"],
            dia=horario["dia"],
            hora_inicio=slot.hora_inicio,
            hora_fin=slot.hora_fin,
            disponible=slot.disponible,
            motivo=slot.motivo,
        )
        for slot in slots
    ]


async def _validate_professional_for_service(
    pool: asyncpg.Pool,
    negocio_id: int,
    servicio_id: int,
    profesional_id: int,
) -> None:
    profesional = await repo.get_profesional_by_id(pool, profesional_id)
    if not profesional or not profesional["activo"]:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "Profesional no encontrado o inactivo.",
        )
    if profesional["negocio_id"] != negocio_id:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "El profesional no pertenece a este negocio.",
        )

    vinculados = await repo.get_profesionales_for_service(pool, servicio_id)
    if vinculados and not any(
        item["id_profesional"] == profesional_id for item in vinculados
    ):
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "El profesional seleccionado no ofrece este servicio.",
        )


async def get_available_times(
    pool: asyncpg.Pool,
    negocio_id: int,
    fecha: date,
    servicio_id: Optional[int] = None,
    profesional_id: Optional[int] = None,
    intervalo_minutos: int = SLOT_MINUTES,
    descanso_minutos: int = BREAK_MINUTES,
) -> AvailableTimesResponse:
    _validate_slot_params(intervalo_minutos, descanso_minutos)

    # 1. Verificar que el negocio existe y está activo
    negocio = await repo.get_negocio_by_id(pool, negocio_id)
    if not negocio:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El negocio no existe o no está activo",
        )

    # 2. Obtener el día de la semana
    dia_nombre = day_for_date(fecha)

    # 3. Servicio solicitado (define la duración de cada espacio)
    duracion = SLOT_MINUTES
    if servicio_id is not None:
        servicio = await repo.get_servicio_by_id(pool, servicio_id)
        if not servicio:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="El servicio no existe",
            )
        if servicio["negocio_id"] != negocio_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El servicio no pertenece a este negocio",
            )
        if not servicio.get("estado_servicio", True):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El servicio no está disponible",
            )
        duracion = servicio["duracion_minutos"] or SLOT_MINUTES

    if profesional_id is not None:
        if servicio_id is None:
            profesional = await repo.get_profesional_by_id(pool, profesional_id)
            if (
                not profesional
                or not profesional["activo"]
                or profesional["negocio_id"] != negocio_id
            ):
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Profesional no encontrado o inactivo en este negocio",
                )
        else:
            await _validate_professional_for_service(
                pool, negocio_id, servicio_id, profesional_id
            )

    # 4. Horarios del negocio para ese día
    horarios = await repo.get_horarios_by_negocio_dia(pool, negocio_id, dia_nombre)
    bloqueos = await agenda_repo.get_blocks_by_date(pool, negocio_id, fecha)
    full_day_block = agenda_service.is_full_day_blocked(bloqueos)

    if not horarios:
        if full_day_block:
            return AvailableTimesResponse(
                negocio_id=negocio_id,
                nombre_negocio=negocio["nombre"],
                fecha=fecha,
                horarios_disponibles=[],
                bloqueado=True,
                motivo_bloqueo=agenda_service.block_reason_for_date(bloqueos),
            )
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No hay horarios disponibles para el negocio en {dia_nombre}",
        )

    if full_day_block:
        return AvailableTimesResponse(
            negocio_id=negocio_id,
            nombre_negocio=negocio["nombre"],
            fecha=fecha,
            horarios_disponibles=[],
            bloqueado=True,
            motivo_bloqueo=agenda_service.block_reason_for_date(bloqueos),
        )

    # 5. Reservas existentes para esa fecha
    reservas = await repo.get_reservas_by_negocio_fecha(
        pool, negocio_id, fecha, profesional_id
    )
    reservas_min = _reservation_intervals(reservas)
    bloqueos_min = _time_block_intervals(bloqueos)

    # 6. Generar espacios dentro de cada horario
    horarios_disponibles: list[AvailableTimes] = []

    for horario in horarios:
        apertura = to_minutes(horario["hora_apertura"])
        cierre = to_minutes(horario["hora_cierre"])
        if cierre <= apertura:
            continue

        descanso = (
            to_minutes(horario["hora_descanso"])
            if horario["hora_descanso"] is not None
            else None
        )

        slots = build_slots(
            apertura_min=apertura,
            cierre_min=cierre,
            duracion_min=duracion,
            intervalo_min=intervalo_minutos,
            descanso_min=descanso,
            descanso_duracion_min=descanso_minutos,
            reservas=reservas_min,
            bloqueos=bloqueos_min,
        )
        horarios_disponibles.extend(_map_slots(horario, slots))

    # Los espacios ya pasados (hoy) o de fechas anteriores no son reservables.
    ahora = datetime.now()
    if fecha <= ahora.date():
        limite = ahora.time() if fecha == ahora.date() else time(23, 59, 59)
        horarios_disponibles = [
            slot
            if slot.hora_inicio > limite
            else slot.model_copy(update={"disponible": False, "motivo": "pasado"})
            for slot in horarios_disponibles
        ]

    if not horarios_disponibles:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No hay horarios disponibles para la fecha seleccionada",
        )

    return AvailableTimesResponse(
        negocio_id=negocio_id,
        nombre_negocio=negocio["nombre"],
        fecha=fecha,
        horarios_disponibles=horarios_disponibles,
    )


#Obtener horarios disponibles de un negocio en una fecha con filtro por servicio
async def get_available_times_by_service(
    pool: asyncpg.Pool,
    negocio_id: int,
    fecha: date,
    servicio_id: int,
    profesional_id: Optional[int] = None,
    intervalo_minutos: int = SLOT_MINUTES,
    descanso_minutos: int = BREAK_MINUTES,
) -> AvailableTimesResponse:
    servicio = await repo.get_servicio_by_id(pool, servicio_id)
    if not servicio:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El servicio no existe",
        )
    if servicio["negocio_id"] != negocio_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El servicio no pertenece a este negocio",
        )

    return await get_available_times(
        pool,
        negocio_id,
        fecha,
        servicio_id,
        profesional_id,
        intervalo_minutos,
        descanso_minutos,
    )


#Obtener horarios disponibles de un negocio en una fecha
async def get_only_available_times(
    pool: asyncpg.Pool,
    negocio_id: int,
    fecha: date,
    servicio_id: Optional[int] = None,
    profesional_id: Optional[int] = None,
    intervalo_minutos: int = SLOT_MINUTES,
    descanso_minutos: int = BREAK_MINUTES,
) -> List[AvailableTimes]:
    response = await get_available_times(
        pool,
        negocio_id,
        fecha,
        servicio_id,
        profesional_id,
        intervalo_minutos,
        descanso_minutos,
    )
    horarios_libres = [h for h in response.horarios_disponibles if h.disponible]
    
    if not horarios_libres:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No hay horarios disponibles para la fecha seleccionada"
        )
    
    return horarios_libres


#Obtener servicios de un negocio
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
    return [ServiceView(**dict(servicio)) for servicio in servicios]


# Reservas -------------------------------------------------------------------

MAX_RESERVATION_TEXT = 500
RESERVATION_FILTERS = {"proximas", "historial", "canceladas", "todas"}


def _clean_text(value: Optional[str]) -> Optional[str]:
    if value is None:
        return None
    value = value.strip()
    return value or None


def _validate_reservation_text(
    value: Optional[str], label: str = "comentario"
) -> Optional[str]:
    text = _clean_text(value)
    if text is not None and len(text) > MAX_RESERVATION_TEXT:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"El {label} no puede superar los "
                f"{MAX_RESERVATION_TEXT} caracteres"
            ),
        )
    return text


def _reservation_out(row) -> ClientReservationOut:
    return ClientReservationOut(**dict(row))


def _status_value(value) -> str:
    return value.value if hasattr(value, "value") else str(value)


def _normalize_filter(filtro: Optional[str]) -> Optional[str]:
    if filtro is None:
        return None
    value = filtro.strip().lower()
    if value in ("", "todas"):
        return None
    if value not in RESERVATION_FILTERS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Filtro inválido. Usa: proximas, historial, canceladas o todas"
            ),
        )
    return value


# Crear una nueva reserva (HU_43)
async def create_reservation(
    pool: asyncpg.Pool,
    cliente_id: int,
    servicio_id: int,
    fecha: date,
    hora_inicio: time,
    profesional_id: Optional[int] = None,
    negocio_id: Optional[int] = None,
    comentario: Optional[str] = None,
) -> ReservationResponse:
    comentario = _validate_reservation_text(comentario, "comentario")

    # 1. Verificar que el servicio existe y está activo
    servicio = await repo.get_servicio_by_id(pool, servicio_id)
    if not servicio:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El servicio no existe",
        )
    if not servicio.get("estado_servicio", True):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El servicio no está disponible",
        )

    negocio_servicio_id = servicio["negocio_id"]
    if negocio_id is not None and negocio_id != negocio_servicio_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El servicio no pertenece al negocio seleccionado",
        )

    negocio = await repo.get_negocio_by_id(pool, negocio_servicio_id)
    if not negocio:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El negocio no existe o no está activo",
        )

    duracion = servicio["duracion_minutos"] or SLOT_MINUTES
    if duracion <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La duración del servicio no es válida",
        )

    inicio = to_minutes(hora_inicio)
    if inicio + duracion >= 24 * 60:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La reserva no puede terminar a medianoche o después",
        )

    ahora = datetime.now()
    if fecha < ahora.date() or (
        fecha == ahora.date() and hora_inicio <= ahora.time()
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No se puede reservar en una fecha u hora pasada",
        )

    if profesional_id is not None:
        await _validate_professional_for_service(
            pool, negocio_servicio_id, servicio_id, profesional_id
        )

    # 2. Verificar que el horario está disponible
    disponible = await check_availability(
        pool,
        negocio_servicio_id,
        fecha,
        hora_inicio,
        duracion,
        profesional_id=profesional_id,
    )
    if not disponible:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El horario seleccionado no está disponible",
        )

    # 3. Crear la reserva de forma atómica (evita duplicados concurrentes)
    reserva = await repo.create_reserva_atomic(
        pool,
        negocio_servicio_id,
        cliente_id,
        servicio_id,
        fecha,
        hora_inicio,
        to_time(inicio + duracion),
        profesional_id,
        comentario,
    )
    if not reserva:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El horario seleccionado ya no está disponible",
        )

    detalle = await repo.get_client_reservation(
        pool, cliente_id, reserva["id_reserva"]
    )
    if detalle:
        return ReservationResponse(**dict(detalle))

    data = dict(reserva)
    data.update(
        {
            "negocio_id": negocio_servicio_id,
            "negocio_nombre": negocio["nombre"],
            "servicio_nombre": servicio["nombre"],
            "duracion_minutos": duracion,
            "precio": float(servicio["precio"]),
        }
    )
    return ReservationResponse(**data)


# HU_47 / HU_53: reservas e historial del cliente
async def list_my_reservations(
    pool: asyncpg.Pool,
    cliente_id: int,
    filtro: Optional[str] = None,
    fecha_desde: Optional[date] = None,
    fecha_hasta: Optional[date] = None,
    estado: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
) -> ClientReservationListOut:
    filtro = _normalize_filter(filtro)

    if fecha_desde and fecha_hasta and fecha_desde > fecha_hasta:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La fecha inicial no puede ser posterior a la final",
        )

    rows, total = await repo.get_client_reservations(
        pool,
        cliente_id,
        filtro=filtro,
        fecha_desde=fecha_desde,
        fecha_hasta=fecha_hasta,
        estado=estado,
        limit=limit,
        offset=offset,
    )

    return ClientReservationListOut(
        items=[_reservation_out(row) for row in rows],
        total=total,
        filtro=filtro,
    )


# HU_49: detalle de una reserva del cliente
async def get_my_reservation(
    pool: asyncpg.Pool, cliente_id: int, reservation_id: int
) -> ClientReservationOut:
    row = await repo.get_client_reservation(pool, cliente_id, reservation_id)
    if not row:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reserva no encontrada",
        )
    return _reservation_out(row)


# HU_46: cancelar una reserva propia
async def cancel_my_reservation(
    pool: asyncpg.Pool,
    cliente_id: int,
    reservation_id: int,
    motivo: Optional[str] = None,
) -> ClientReservationOut:
    motivo = _validate_reservation_text(motivo, "motivo")

    row = await repo.get_client_reservation(pool, cliente_id, reservation_id)
    if not row:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reserva no encontrada",
        )

    estado_actual = _status_value(row["estado"])
    if estado_actual not in ("pendiente", "confirmada"):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                f"Una reserva en estado «{estado_actual}» "
                "ya no se puede cancelar"
            ),
        )

    updated = await repo.cancel_client_reservation(
        pool, cliente_id, reservation_id, motivo
    )
    if not updated:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="La reserva ya no se puede cancelar",
        )
    return _reservation_out(updated)


# HU_50: reprogramar una reserva propia
async def reschedule_my_reservation(
    pool: asyncpg.Pool,
    cliente_id: int,
    reservation_id: int,
    fecha: date,
    hora_inicio: time,
    profesional_id: Optional[int] = None,
    motivo: Optional[str] = None,
) -> ClientReservationOut:
    motivo = _validate_reservation_text(motivo, "motivo")

    row = await repo.get_client_reservation(pool, cliente_id, reservation_id)
    if not row:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reserva no encontrada",
        )

    estado_actual = _status_value(row["estado"])
    if estado_actual not in ("pendiente", "confirmada"):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                f"Una reserva en estado «{estado_actual}» "
                "ya no se puede modificar"
            ),
        )

    negocio_id = row["negocio_id"]
    servicio_id = row["servicio_id"]
    duracion = row["duracion_minutos"] or SLOT_MINUTES
    if duracion <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La duración del servicio no es válida",
        )

    inicio = to_minutes(hora_inicio)
    if inicio + duracion >= 24 * 60:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La reserva no puede terminar a medianoche o después",
        )

    ahora = datetime.now()
    if fecha < ahora.date() or (
        fecha == ahora.date() and hora_inicio <= ahora.time()
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No se puede reprogramar a una fecha u hora pasada",
        )

    if profesional_id is None:
        profesional_id = row["profesional_id"]

    if profesional_id is not None:
        await _validate_professional_for_service(
            pool, negocio_id, servicio_id, profesional_id
        )

    disponible = await check_availability(
        pool,
        negocio_id,
        fecha,
        hora_inicio,
        duracion,
        profesional_id=profesional_id,
        exclude_reservation_id=reservation_id,
    )
    if not disponible:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El nuevo horario no está disponible",
        )

    updated = await repo.reschedule_reserva_atomic(
        pool,
        negocio_id,
        cliente_id,
        reservation_id,
        fecha,
        hora_inicio,
        to_time(inicio + duracion),
        profesional_id,
        motivo,
    )
    if not updated:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El nuevo horario ya no está disponible",
        )
    return _reservation_out(updated)


# HU_53: historial del cliente (reservas finalizadas o anteriores)
async def get_my_reservation_history(
    pool: asyncpg.Pool,
    cliente_id: int,
    fecha_desde: Optional[date] = None,
    fecha_hasta: Optional[date] = None,
    estado: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
) -> ClientReservationListOut:
    return await list_my_reservations(
        pool,
        cliente_id,
        filtro="historial",
        fecha_desde=fecha_desde,
        fecha_hasta=fecha_hasta,
        estado=estado,
        limit=limit,
        offset=offset,
    )


#  Verificar si un horario específico está disponible
async def check_availability(
    pool: asyncpg.Pool,
    negocio_id: int,
    fecha: date,
    hora_inicio: time,
    duracion_minutos: int,
    profesional_id: Optional[int] = None,
    descanso_minutos: int = BREAK_MINUTES,
    exclude_reservation_id: Optional[int] = None,
) -> bool:
    if duracion_minutos <= 0:
        return False

    inicio = to_minutes(hora_inicio)
    fin = inicio + duracion_minutos
    if fin >= 24 * 60:
        return False

    ahora = datetime.now()
    if fecha < ahora.date() or (
        fecha == ahora.date() and hora_inicio <= ahora.time()
    ):
        return False

    dia_nombre = day_for_date(fecha)

    if profesional_id is not None:
        profesional = await repo.get_profesional_by_id(pool, profesional_id)
        if (
            not profesional
            or not profesional["activo"]
            or profesional["negocio_id"] != negocio_id
        ):
            return False

    horarios = await repo.get_horarios_by_negocio_dia(
        pool, negocio_id, dia_nombre
    )
    if not horarios:
        return False

    bloqueos = await agenda_repo.get_blocks_by_date(pool, negocio_id, fecha)
    if agenda_service.is_full_day_blocked(bloqueos):
        return False

    bloqueos_min = _time_block_intervals(bloqueos)
    if any(
        overlaps(inicio, fin, b_ini, b_fin) for b_ini, b_fin in bloqueos_min
    ):
        return False

    dentro_de_horario = False
    for horario in horarios:
        apertura = to_minutes(horario["hora_apertura"])
        cierre = to_minutes(horario["hora_cierre"])
        if cierre <= apertura or inicio < apertura or fin > cierre:
            continue

        descanso = (
            to_minutes(horario["hora_descanso"])
            if horario["hora_descanso"] is not None
            else None
        )
        if descanso is None or not overlaps(
            inicio, fin, descanso, descanso + descanso_minutos
        ):
            dentro_de_horario = True
            break

    if not dentro_de_horario:
        return False

    reservas = await repo.get_reservas_by_negocio_fecha(
        pool,
        negocio_id,
        fecha,
        profesional_id,
        exclude_reservation_id=exclude_reservation_id,
    )

    for reserva in reservas:
        reserva_inicio = to_minutes(reserva["hora_inicio"])
        if reserva["hora_fin"] is not None:
            reserva_fin = to_minutes(reserva["hora_fin"])
        else:
            reserva_fin = reserva_inicio + (
                reserva["duracion_minutos"] or SLOT_MINUTES
            )
        if overlaps(inicio, fin, reserva_inicio, reserva_fin):
            return False

    return True
