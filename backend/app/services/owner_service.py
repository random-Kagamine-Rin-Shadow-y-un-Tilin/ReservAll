from fastapi import HTTPException, status
from datetime import date, timedelta
from typing import Optional

import asyncpg

from app.models.owner import (
    ClientListOut,
    OwnerClientDetailOut,
    OwnerClientOut,
    OwnerReportOut,
    OwnerReservationOut,
    ReportDailyPoint,
    ReportHourItem,
    ReportProfessionalItem,
    ReportRange,
    ReportServiceItem,
    ReportStatusItem,
    ReportTotals,
    ReportWeekdayItem,
    ReservationListOut,
    ReservationSummary,
)
from app.repositories import owner_repository as repo

DEFAULT_REPORT_DAYS = 30
MAX_REPORT_DAYS = 366

WEEKDAY_LABELS = {
    1: "Lunes",
    2: "Martes",
    3: "Miércoles",
    4: "Jueves",
    5: "Viernes",
    6: "Sábado",
    7: "Domingo",
}

ALLOWED_TRANSITIONS = {
    "pendiente": {"confirmada", "cancelada"},
    "confirmada": {"completada", "cancelada"},
    "cancelada": set(),
    "completada": set(),
}

TRANSITION_ERRORS = {
    "cancelada": "Una reserva cancelada ya no se puede modificar.",
    "completada": "Una reserva completada ya no se puede modificar.",
}


async def _ensure_shop(pool: asyncpg.Pool, shop_id: int, current_user_id: int):
    shop = await repo.get_shop_owner(pool, shop_id)
    if not shop:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND, "Negocio no encontrado."
        )
    if shop["dueno_id"] != current_user_id:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN, "No tienes permiso sobre este negocio."
        )
    return shop


def _status_value(value) -> str:
    return value.value if hasattr(value, "value") else str(value)


def _summary(items: list) -> ReservationSummary:
    summary = ReservationSummary(total=len(items))
    for item in items:
        estado = _status_value(item["estado"])
        if estado == "pendiente":
            summary.pendientes += 1
        elif estado == "confirmada":
            summary.confirmadas += 1
        elif estado == "completada":
            summary.completadas += 1
            summary.ingresos += float(item["precio"] or 0)
        elif estado == "cancelada":
            summary.canceladas += 1
    summary.ingresos = round(summary.ingresos, 2)
    return summary


async def list_reservations(
    pool: asyncpg.Pool,
    shop_id: int,
    current_user_id: int,
    fecha_desde: Optional[date] = None,
    fecha_hasta: Optional[date] = None,
    estado: Optional[str] = None,
    profesional_id: Optional[int] = None,
    search: Optional[str] = None,
):
    await _ensure_shop(pool, shop_id, current_user_id)

    if fecha_desde and fecha_hasta and fecha_desde > fecha_hasta:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "La fecha inicial no puede ser posterior a la final.",
        )

    rows = await repo.get_reservations(
        pool,
        shop_id,
        fecha_desde=fecha_desde,
        fecha_hasta=fecha_hasta,
        estado=estado,
        profesional_id=profesional_id,
        search=search,
    )

    items = [OwnerReservationOut(**dict(row)) for row in rows]
    return ReservationListOut(items=items, summary=_summary(rows))


async def get_reservation(
    pool: asyncpg.Pool, shop_id: int, reservation_id: int, current_user_id: int
):
    await _ensure_shop(pool, shop_id, current_user_id)
    row = await repo.get_reservation(pool, shop_id, reservation_id)
    if not row:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND, "Reserva no encontrada."
        )
    return OwnerReservationOut(**dict(row))


MAX_RESERVATION_TEXT = 500


def _validate_motivo(motivo: Optional[str]) -> Optional[str]:
    if motivo is None:
        return None
    motivo = motivo.strip()
    if not motivo:
        return None
    if len(motivo) > MAX_RESERVATION_TEXT:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"El motivo no puede superar los {MAX_RESERVATION_TEXT} caracteres.",
        )
    return motivo


async def update_reservation_status(
    pool: asyncpg.Pool,
    shop_id: int,
    reservation_id: int,
    current_user_id: int,
    nuevo_estado: str,
    motivo: Optional[str] = None,
):
    await _ensure_shop(pool, shop_id, current_user_id)
    motivo = _validate_motivo(motivo)

    row = await repo.get_reservation(pool, shop_id, reservation_id)
    if not row:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND, "Reserva no encontrada."
        )

    estado_actual = _status_value(row["estado"])
    if estado_actual == nuevo_estado:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"La reserva ya está en estado «{nuevo_estado}».",
        )

    permitidos = ALLOWED_TRANSITIONS.get(estado_actual, set())
    if nuevo_estado not in permitidos:
        detalle = TRANSITION_ERRORS.get(
            estado_actual,
            f"No se puede pasar de «{estado_actual}» a «{nuevo_estado}».",
        )
        raise HTTPException(status.HTTP_409_CONFLICT, detalle)

    updated = await repo.update_reservation_status(
        pool,
        shop_id,
        reservation_id,
        nuevo_estado,
        motivo,
        expected_estado=estado_actual,
    )
    if not updated:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "La reserva cambió de estado. Vuelve a intentarlo.",
        )

    refreshed = await repo.get_reservation(pool, shop_id, reservation_id)
    return OwnerReservationOut(**dict(refreshed))


# HU_44: confirmar una reserva pendiente
async def confirm_reservation(
    pool: asyncpg.Pool,
    shop_id: int,
    reservation_id: int,
    current_user_id: int,
):
    return await update_reservation_status(
        pool,
        shop_id,
        reservation_id,
        current_user_id,
        "confirmada",
    )


# HU_45: rechazar una reserva pendiente (se libera el horario)
async def reject_reservation(
    pool: asyncpg.Pool,
    shop_id: int,
    reservation_id: int,
    current_user_id: int,
    motivo: Optional[str] = None,
):
    await _ensure_shop(pool, shop_id, current_user_id)

    row = await repo.get_reservation(pool, shop_id, reservation_id)
    if not row:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND, "Reserva no encontrada."
        )

    estado_actual = _status_value(row["estado"])
    if estado_actual != "pendiente":
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Solo se pueden rechazar reservas pendientes.",
        )

    return await update_reservation_status(
        pool,
        shop_id,
        reservation_id,
        current_user_id,
        "cancelada",
        motivo,
    )


# HU_52: completar una reserva confirmada
async def complete_reservation(
    pool: asyncpg.Pool,
    shop_id: int,
    reservation_id: int,
    current_user_id: int,
):
    return await update_reservation_status(
        pool,
        shop_id,
        reservation_id,
        current_user_id,
        "completada",
    )


# HU_53: historial de reservas del negocio
async def list_reservation_history(
    pool: asyncpg.Pool,
    shop_id: int,
    current_user_id: int,
    fecha_desde: Optional[date] = None,
    fecha_hasta: Optional[date] = None,
    estado: Optional[str] = None,
    profesional_id: Optional[int] = None,
    search: Optional[str] = None,
):
    await _ensure_shop(pool, shop_id, current_user_id)

    if fecha_desde and fecha_hasta and fecha_desde > fecha_hasta:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "La fecha inicial no puede ser posterior a la final.",
        )

    estados = [estado] if estado else ["completada", "cancelada"]
    rows = await repo.get_reservations(
        pool,
        shop_id,
        fecha_desde=fecha_desde,
        fecha_hasta=fecha_hasta,
        estados=estados,
        profesional_id=profesional_id,
        search=search,
    )

    items = [OwnerReservationOut(**dict(row)) for row in rows]
    return ReservationListOut(items=items, summary=_summary(rows))


async def list_clients(
    pool: asyncpg.Pool,
    shop_id: int,
    current_user_id: int,
    search: Optional[str] = None,
):
    await _ensure_shop(pool, shop_id, current_user_id)
    rows = await repo.get_clients(pool, shop_id, search=search)
    items = [OwnerClientOut(**dict(row)) for row in rows]
    return ClientListOut(items=items, total=len(items))


async def get_client(
    pool: asyncpg.Pool,
    shop_id: int,
    client_id: int,
    current_user_id: int,
):
    await _ensure_shop(pool, shop_id, current_user_id)

    row = await repo.get_client(pool, shop_id, client_id)
    if not row:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "Este cliente no tiene reservas en tu negocio.",
        )

    history = await repo.get_reservations(
        pool, shop_id, cliente_id=client_id
    )

    data = dict(row)
    data["reservas"] = [OwnerReservationOut(**dict(item)) for item in history]
    return OwnerClientDetailOut(**data)


# Reportes -------------------------------------------------------------------


def _totals(row) -> ReportTotals:
    reservas = int(row["reservas"] or 0)
    completadas = int(row["completadas"] or 0)
    canceladas = int(row["canceladas"] or 0)
    ingresos = float(row["ingresos"] or 0)
    ticket = ingresos / completadas if completadas else 0.0
    tasa = (canceladas / reservas * 100) if reservas else 0.0

    return ReportTotals(
        reservas=reservas,
        completadas=completadas,
        canceladas=canceladas,
        pendientes=int(row["pendientes"] or 0),
        confirmadas=int(row["confirmadas"] or 0),
        ingresos=round(ingresos, 2),
        ticket_promedio=round(ticket, 2),
        tasa_cancelacion=round(tasa, 1),
        clientes_unicos=int(row["clientes_unicos"] or 0),
    )


async def get_report(
    pool: asyncpg.Pool,
    shop_id: int,
    current_user_id: int,
    fecha_desde: Optional[date] = None,
    fecha_hasta: Optional[date] = None,
):
    await _ensure_shop(pool, shop_id, current_user_id)

    hasta = fecha_hasta or date.today()
    desde = fecha_desde or (hasta - timedelta(days=DEFAULT_REPORT_DAYS - 1))

    if desde > hasta:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "La fecha inicial no puede ser posterior a la final.",
        )

    dias = (hasta - desde).days + 1
    if dias > MAX_REPORT_DAYS:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"El rango no puede superar los {MAX_REPORT_DAYS} días.",
        )

    previous_hasta = desde - timedelta(days=1)
    previous_desde = previous_hasta - timedelta(days=dias - 1)

    totals_row = await repo.get_report_totals(pool, shop_id, desde, hasta)
    previous_row = await repo.get_report_totals(
        pool, shop_id, previous_desde, previous_hasta
    )
    daily_rows = await repo.get_report_daily(pool, shop_id, desde, hasta)
    service_rows = await repo.get_top_services(pool, shop_id, desde, hasta)
    professional_rows = await repo.get_top_professionals(
        pool, shop_id, desde, hasta
    )
    weekday_rows = await repo.get_report_weekdays(pool, shop_id, desde, hasta)
    hour_rows = await repo.get_report_hours(pool, shop_id, desde, hasta)

    totals = _totals(totals_row)

    daily_map = {row["fecha"]: row for row in daily_rows}
    daily = []
    for offset in range(dias):
        current = desde + timedelta(days=offset)
        row = daily_map.get(current)
        daily.append(
            ReportDailyPoint(
                fecha=current,
                total=int(row["total"]) if row else 0,
                completadas=int(row["completadas"]) if row else 0,
                canceladas=int(row["canceladas"]) if row else 0,
                ingresos=round(float(row["ingresos"]), 2) if row else 0.0,
            )
        )

    services = [
        ReportServiceItem(
            servicio_id=row["id_servicio"],
            nombre=row["nombre"],
            reservas=int(row["reservas"]),
            completadas=int(row["completadas"]),
            ingresos=round(float(row["ingresos"] or 0), 2),
        )
        for row in service_rows
    ]

    professionals = [
        ReportProfessionalItem(
            profesional_id=row["id_profesional"],
            nombre=row["nombre"],
            reservas=int(row["reservas"]),
            completadas=int(row["completadas"]),
            ingresos=round(float(row["ingresos"] or 0), 2),
        )
        for row in professional_rows
    ]

    weekday_map = {row["dia"]: row for row in weekday_rows}
    weekdays = [
        ReportWeekdayItem(
            dia=day,
            label=label,
            total=int(weekday_map[day]["total"]) if day in weekday_map else 0,
            ingresos=round(float(weekday_map[day]["ingresos"] or 0), 2)
            if day in weekday_map
            else 0.0,
        )
        for day, label in WEEKDAY_LABELS.items()
    ]

    hours = [
        ReportHourItem(hora=row["hora"], total=int(row["total"]))
        for row in hour_rows
    ]

    return OwnerReportOut(
        rango=ReportRange(desde=desde, hasta=hasta, dias=dias),
        totales=totals,
        comparacion=_totals(previous_row),
        diario=daily,
        servicios_top=services,
        profesionales_top=professionals,
        estados=[
            ReportStatusItem(estado="pendiente", total=totals.pendientes),
            ReportStatusItem(estado="confirmada", total=totals.confirmadas),
            ReportStatusItem(estado="completada", total=totals.completadas),
            ReportStatusItem(estado="cancelada", total=totals.canceladas),
        ],
        dias_semana=weekdays,
        horas_pico=hours,
    )
