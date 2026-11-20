from datetime import date, datetime, time, timedelta
from typing import Iterable, Optional

import asyncpg
from fastapi import HTTPException, status

from app.core.schedule_utils import (
    build_slots,
    day_for_date,
    day_label,
    to_minutes,
)
from app.models.agenda import (
    AgendaDayOut,
    AgendaRangeOut,
    AgendaSlotOut,
    AgendaSummaryOut,
    BlockCreate,
    BlockListOut,
    BlockOut,
    OwnerAgendaOut,
)
from app.models.owner import OwnerReservationOut
from app.models.shop_schedule import ShopScheduleOut
from app.repositories import agenda_repository as repo
from app.repositories import owner_repository as owner_repo
from app.repositories import shop_schedule_repository as schedule_repo


DEFAULT_AGENDA_DAYS = 7
DEFAULT_BLOCK_DAYS = 30
MAX_AGENDA_DAYS = 62
MAX_BLOCK_DAYS = 366
DEFAULT_INTERVAL_MINUTES = 30
DEFAULT_BREAK_MINUTES = 60


async def _ensure_shop(pool: asyncpg.Pool, shop_id: int, current_user_id: int):
    shop = await owner_repo.get_shop_owner(pool, shop_id)
    if not shop:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Negocio no encontrado.")
    if shop["dueno_id"] != current_user_id:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN, "No tienes permiso sobre este negocio."
        )
    return shop


def _validate_range(
    fecha_desde: Optional[date],
    fecha_hasta: Optional[date],
    *,
    default_days: int,
    max_days: int,
):
    hoy = date.today()
    desde = fecha_desde or hoy
    hasta = fecha_hasta or (desde + timedelta(days=default_days - 1))

    if desde > hasta:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "La fecha inicial no puede ser posterior a la final.",
        )

    dias = (hasta - desde).days + 1
    if dias > max_days:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"El rango no puede superar los {max_days} días.",
        )
    return desde, hasta, dias


def _validate_interval(intervalo_minutos: int, descanso_minutos: int):
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


def _reservation_intervals(reservas: Iterable) -> list[tuple[int, int]]:
    intervals: list[tuple[int, int]] = []
    for reserva in reservas:
        inicio = to_minutes(reserva["hora_inicio"])
        if reserva["hora_fin"] is not None:
            fin = to_minutes(reserva["hora_fin"])
        else:
            duracion = reserva.get("duracion_minutos") or DEFAULT_INTERVAL_MINUTES
            fin = inicio + int(duracion)
        intervals.append((inicio, fin))
    return intervals


def _block_intervals(bloqueos: Iterable) -> list[tuple[int, int]]:
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


def _is_full_day_block(bloqueos: Iterable) -> bool:
    return any(
        bloqueo["hora_inicio"] is None and bloqueo["hora_fin"] is None
        for bloqueo in bloqueos
    )


def _block_reason(bloqueos: Iterable) -> Optional[str]:
    for bloqueo in bloqueos:
        if bloqueo["hora_inicio"] is None and bloqueo["hora_fin"] is None:
            return bloqueo["motivo"] or "Día bloqueado por el negocio"
    return None


def _build_day_availability(
    horario,
    reservas: Iterable,
    bloqueos: Iterable,
    *,
    fecha: date,
    duracion_min: int,
    intervalo_min: int,
    descanso_min: int,
) -> list[AgendaSlotOut]:
    if horario is None or not horario["estado_horario"]:
        return []
    if _is_full_day_block(bloqueos):
        return []

    apertura = to_minutes(horario["hora_apertura"])
    cierre = to_minutes(horario["hora_cierre"])
    descanso = (
        to_minutes(horario["hora_descanso"])
        if horario["hora_descanso"] is not None
        else None
    )

    slots = build_slots(
        apertura_min=apertura,
        cierre_min=cierre,
        duracion_min=duracion_min,
        intervalo_min=intervalo_min,
        descanso_min=descanso,
        descanso_duracion_min=descanso_min,
        reservas=_reservation_intervals(reservas),
        bloqueos=_block_intervals(bloqueos),
    )
    ahora = datetime.now()
    limite = ahora.time() if fecha == ahora.date() else None
    if fecha < ahora.date():
        limite = time(23, 59, 59)

    return [
        AgendaSlotOut(
            hora_inicio=slot.hora_inicio,
            hora_fin=slot.hora_fin,
            disponible=slot.disponible and (limite is None or slot.hora_inicio > limite),
            motivo=(
                slot.motivo
                if slot.motivo is not None
                else ("pasado" if limite is not None and slot.hora_inicio <= limite else None)
            ),
        )
        for slot in slots
    ]


def _agenda_summary(
    dias: list[AgendaDayOut], reservas: list[OwnerReservationOut]
) -> AgendaSummaryOut:
    summary = AgendaSummaryOut(total_reservas=len(reservas))
    for reserva in reservas:
        estado = (
            reserva.estado.value
            if hasattr(reserva.estado, "value")
            else str(reserva.estado)
        )
        if estado == "pendiente":
            summary.pendientes += 1
        elif estado == "confirmada":
            summary.confirmadas += 1
        elif estado == "completada":
            summary.completadas += 1
        elif estado == "cancelada":
            summary.canceladas += 1

    for dia in dias:
        if dia.bloqueado:
            summary.dias_bloqueados += 1
        elif dia.abierto:
            summary.dias_abiertos += 1
        else:
            summary.dias_cerrados += 1

    return summary


async def get_agenda(
    pool: asyncpg.Pool,
    shop_id: int,
    current_user_id: int,
    fecha_desde: Optional[date] = None,
    fecha_hasta: Optional[date] = None,
    servicio_id: Optional[int] = None,
    profesional_id: Optional[int] = None,
    intervalo_minutos: int = DEFAULT_INTERVAL_MINUTES,
    descanso_minutos: int = DEFAULT_BREAK_MINUTES,
) -> OwnerAgendaOut:
    await _ensure_shop(pool, shop_id, current_user_id)
    _validate_interval(intervalo_minutos, descanso_minutos)
    desde, hasta, dias = _validate_range(
        fecha_desde,
        fecha_hasta,
        default_days=DEFAULT_AGENDA_DAYS,
        max_days=MAX_AGENDA_DAYS,
    )

    if profesional_id is not None:
        profesional = await repo.get_professional_by_id(pool, profesional_id)
        if (
            not profesional
            or profesional["negocio_id"] != shop_id
            or not profesional["activo"]
        ):
            raise HTTPException(
                status.HTTP_404_NOT_FOUND,
                "Profesional no encontrado o inactivo en este negocio.",
            )

    duracion_min = intervalo_minutos
    if servicio_id is not None:
        servicio = await repo.get_service_by_id(pool, servicio_id)
        if not servicio or servicio["negocio_id"] != shop_id:
            raise HTTPException(
                status.HTTP_404_NOT_FOUND,
                "Servicio no encontrado en este negocio.",
            )
        duracion_min = servicio["duracion_minutos"] or intervalo_minutos

    schedule_rows = await schedule_repo.get_weekly_schedule(
        pool, shop_id, include_inactive=True
    )
    schedule_by_day = {row["dia"]: row for row in schedule_rows}

    # Se traen todas las reservas del rango para poder mostrar solo las del
    # profesional filtrado, pero bloqueando también las que no tienen
    # profesional asignado (igual que la disponibilidad del cliente).
    reservations = await owner_repo.get_reservations(
        pool,
        shop_id,
        fecha_desde=desde,
        fecha_hasta=hasta,
    )
    blocks = await repo.get_blocks(pool, shop_id, desde, hasta)

    reservations_by_date: dict[date, list] = {}
    for reserva in reservations:
        reservations_by_date.setdefault(reserva["fecha"], []).append(reserva)

    blocks_by_date: dict[date, list] = {}
    for bloqueo in blocks:
        blocks_by_date.setdefault(bloqueo["fecha"], []).append(bloqueo)

    agenda_days: list[AgendaDayOut] = []
    all_reservations: list[OwnerReservationOut] = []

    for offset in range(dias):
        current = desde + timedelta(days=offset)
        dia_key = day_for_date(current)
        horario = schedule_by_day.get(dia_key)
        day_blocks = blocks_by_date.get(current, [])
        all_day_reservations = sorted(
            reservations_by_date.get(current, []),
            key=lambda row: row["hora_inicio"],
        )
        blocking_reservations = [
            reserva
            for reserva in all_day_reservations
            if profesional_id is None
            or reserva["profesional_id"] in (None, profesional_id)
        ]
        day_reservations = [
            reserva
            for reserva in all_day_reservations
            if profesional_id is None
            or reserva["profesional_id"] == profesional_id
        ]

        full_day_block = _is_full_day_block(day_blocks)
        horario_valido = (
            horario is not None
            and to_minutes(horario["hora_cierre"])
            > to_minutes(horario["hora_apertura"])
        )
        abierto = bool(
            horario_valido
            and horario["estado_horario"]
            and not full_day_block
        )

        reservas_out = [
            OwnerReservationOut(**dict(reserva)) for reserva in day_reservations
        ]
        all_reservations.extend(reservas_out)

        agenda_days.append(
            AgendaDayOut(
                fecha=current,
                dia_semana=day_label(dia_key),
                abierto=abierto,
                bloqueado=full_day_block,
                horario=ShopScheduleOut(**dict(horario)) if horario else None,
                reservas=reservas_out,
                bloqueos=[BlockOut(**dict(b)) for b in day_blocks],
                disponibilidad=_build_day_availability(
                    horario,
                    blocking_reservations,
                    day_blocks,
                    fecha=current,
                    duracion_min=duracion_min,
                    intervalo_min=intervalo_minutos,
                    descanso_min=descanso_minutos,
                ),
            )
        )

    return OwnerAgendaOut(
        negocio_id=shop_id,
        rango=AgendaRangeOut(desde=desde, hasta=hasta, dias=dias),
        horarios=[ShopScheduleOut(**dict(row)) for row in schedule_rows],
        dias=agenda_days,
        resumen=_agenda_summary(agenda_days, all_reservations),
    )


async def list_blocks(
    pool: asyncpg.Pool,
    shop_id: int,
    current_user_id: int,
    fecha_desde: Optional[date] = None,
    fecha_hasta: Optional[date] = None,
) -> BlockListOut:
    await _ensure_shop(pool, shop_id, current_user_id)
    desde, hasta, _ = _validate_range(
        fecha_desde,
        fecha_hasta,
        default_days=DEFAULT_BLOCK_DAYS,
        max_days=MAX_BLOCK_DAYS,
    )
    rows = await repo.get_blocks(pool, shop_id, desde, hasta)
    items = [BlockOut(**dict(row)) for row in rows]
    return BlockListOut(items=items, total=len(items))


async def create_block(
    pool: asyncpg.Pool,
    shop_id: int,
    current_user_id: int,
    data: BlockCreate,
) -> BlockOut:
    await _ensure_shop(pool, shop_id, current_user_id)

    if data.fecha < date.today():
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "No se puede bloquear una fecha pasada.",
        )

    overlapping_blocks = await repo.get_overlapping_blocks(
        pool, shop_id, data.fecha, data.hora_inicio, data.hora_fin
    )
    if overlapping_blocks:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Ya existe un bloqueo que se solapa con ese horario.",
        )

    overlapping_reservations = await repo.get_overlapping_reservations(
        pool, shop_id, data.fecha, data.hora_inicio, data.hora_fin
    )
    if overlapping_reservations:
        cantidad = len(overlapping_reservations)
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"No se puede bloquear: hay {cantidad} reserva(s) activa(s) en ese "
            "horario. Cancélalas o reubícalas primero.",
        )

    row = await repo.create_block(
        pool,
        shop_id,
        data.fecha,
        data.hora_inicio,
        data.hora_fin,
        data.motivo,
    )
    return BlockOut(**dict(row))


async def delete_block(
    pool: asyncpg.Pool,
    shop_id: int,
    block_id: int,
    current_user_id: int,
):
    await _ensure_shop(pool, shop_id, current_user_id)

    block = await repo.get_block_by_id(pool, block_id)
    if not block or block["negocio_id"] != shop_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Bloqueo no encontrado.")

    await repo.delete_block(pool, block_id)
    return {"message": "Bloqueo eliminado correctamente."}


def block_reason_for_date(bloqueos: Iterable) -> Optional[str]:
    """Motivo del bloqueo de día completo, si existe.

    Se expone para que la disponibilidad del cliente pueda informar el motivo.
    """

    return _block_reason(bloqueos)


def is_full_day_blocked(bloqueos: Iterable) -> bool:
    return _is_full_day_block(bloqueos)
