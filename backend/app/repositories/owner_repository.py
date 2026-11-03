import asyncpg
from datetime import date
from typing import Optional, List, Tuple


async def get_shop_owner(pool: asyncpg.Pool, shop_id: int):
    query = """
        SELECT id, dueno_id, nombre, estado_negocio
        FROM negocios
        WHERE id = $1
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, shop_id)


# Reservas -------------------------------------------------------------------

_RESERVATION_SELECT = """
    SELECT
        r.id_reserva,
        r.cliente_id,
        u.nombre  AS cliente_nombre,
        u.correo  AS cliente_correo,
        r.servicio_id,
        s.nombre  AS servicio_nombre,
        s.duracion_minutos,
        s.precio,
        r.profesional_id,
        p.nombre  AS profesional_nombre,
        r.fecha,
        r.hora_inicio,
        COALESCE(
            r.hora_fin,
            r.hora_inicio + make_interval(mins => s.duracion_minutos)
        ) AS hora_fin,
        r.estado,
        r.fecha_creacion
    FROM reservas AS r
    INNER JOIN servicios AS s ON s.id_servicio = r.servicio_id
    INNER JOIN usuarios  AS u ON u.id = r.cliente_id
    LEFT  JOIN profesionales AS p ON p.id_profesional = r.profesional_id
"""


async def get_reservations(
    pool: asyncpg.Pool,
    shop_id: int,
    fecha_desde: Optional[date] = None,
    fecha_hasta: Optional[date] = None,
    estado: Optional[str] = None,
    profesional_id: Optional[int] = None,
    search: Optional[str] = None,
    cliente_id: Optional[int] = None,
    reservation_id: Optional[int] = None,
    limit: Optional[int] = None,
):
    conditions = ["s.negocio_id = $1"]
    params: List[object] = [shop_id]

    def add(condition: str, value: object) -> None:
        params.append(value)
        index = len(params)
        conditions.append(condition.format(n=index))

    if fecha_desde is not None:
        add("r.fecha >= ${n}::date", fecha_desde)
    if fecha_hasta is not None:
        add("r.fecha <= ${n}::date", fecha_hasta)
    if estado is not None:
        add("r.estado::text = ${n}", estado)
    if profesional_id is not None:
        add("r.profesional_id = ${n}", profesional_id)
    if search:
        term = f"%{search.strip()}%"
        params.append(term)
        index = len(params)
        conditions.append(f"(u.nombre ILIKE ${index} OR u.correo ILIKE ${index})")
    if cliente_id is not None:
        add("r.cliente_id = ${n}", cliente_id)
    if reservation_id is not None:
        add("r.id_reserva = ${n}", reservation_id)

    query = (
        _RESERVATION_SELECT
        + " WHERE "
        + " AND ".join(conditions)
        + " ORDER BY r.fecha DESC, r.hora_inicio DESC"
    )

    if limit is not None:
        params.append(limit)
        query += f" LIMIT ${len(params)}"

    async with pool.acquire() as conn:
        return await conn.fetch(query, *params)


async def get_reservation(
    pool: asyncpg.Pool, shop_id: int, reservation_id: int
):
    rows = await get_reservations(
        pool, shop_id, reservation_id=reservation_id, limit=1
    )
    return rows[0] if rows else None


async def update_reservation_status(
    pool: asyncpg.Pool, shop_id: int, reservation_id: int, estado: str
):
    query = """
        UPDATE reservas AS r
        SET estado = $3::estado_reserva
        FROM servicios AS s
        WHERE r.servicio_id = s.id_servicio
          AND s.negocio_id = $1
          AND r.id_reserva = $2
        RETURNING r.id_reserva, r.estado::text AS estado
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, shop_id, reservation_id, estado)


# Clientes -------------------------------------------------------------------

_CLIENT_AGGREGATE = """
    SELECT
        u.id AS cliente_id,
        u.nombre,
        u.correo,
        COUNT(r.id_reserva)::int AS total_reservas,
        COUNT(*) FILTER (WHERE r.estado = 'completada')::int AS completadas,
        COUNT(*) FILTER (WHERE r.estado = 'cancelada')::int AS canceladas,
        COUNT(*) FILTER (
            WHERE r.estado IN ('pendiente', 'confirmada')
        )::int AS activas,
        MIN(r.fecha) AS primera_reserva,
        MAX(r.fecha) AS ultima_reserva,
        COALESCE(
            SUM(s.precio) FILTER (WHERE r.estado = 'completada'), 0
        ) AS total_gastado,
        MODE() WITHIN GROUP (ORDER BY s.nombre) AS servicio_favorito
    FROM reservas AS r
    INNER JOIN servicios AS s ON s.id_servicio = r.servicio_id
    INNER JOIN usuarios  AS u ON u.id = r.cliente_id
    WHERE s.negocio_id = $1
"""


async def get_clients(
    pool: asyncpg.Pool,
    shop_id: int,
    search: Optional[str] = None,
    cliente_id: Optional[int] = None,
):
    conditions: List[str] = []
    params: List[object] = [shop_id]

    if search:
        params.append(f"%{search.strip()}%")
        index = len(params)
        conditions.append(f"(u.nombre ILIKE ${index} OR u.correo ILIKE ${index})")
    if cliente_id is not None:
        params.append(cliente_id)
        conditions.append(f"u.id = ${len(params)}")

    query = _CLIENT_AGGREGATE
    if conditions:
        query += " AND " + " AND ".join(conditions)
    query += " GROUP BY u.id, u.nombre, u.correo ORDER BY ultima_reserva DESC, u.nombre"

    async with pool.acquire() as conn:
        return await conn.fetch(query, *params)


async def get_client(
    pool: asyncpg.Pool, shop_id: int, cliente_id: int
):
    rows = await get_clients(pool, shop_id, cliente_id=cliente_id)
    return rows[0] if rows else None


# Reportes -------------------------------------------------------------------

_REPORT_FROM = """
    FROM reservas AS r
    INNER JOIN servicios AS s ON s.id_servicio = r.servicio_id
    WHERE s.negocio_id = $1
      AND r.fecha BETWEEN $2 AND $3
"""


async def get_report_totals(
    pool: asyncpg.Pool, shop_id: int, fecha_desde: date, fecha_hasta: date
):
    query = f"""
        SELECT
            COUNT(r.id_reserva)::int AS reservas,
            COUNT(*) FILTER (WHERE r.estado = 'completada')::int AS completadas,
            COUNT(*) FILTER (WHERE r.estado = 'cancelada')::int AS canceladas,
            COUNT(*) FILTER (WHERE r.estado = 'pendiente')::int AS pendientes,
            COUNT(*) FILTER (WHERE r.estado = 'confirmada')::int AS confirmadas,
            COALESCE(
                SUM(s.precio) FILTER (WHERE r.estado = 'completada'), 0
            ) AS ingresos,
            COUNT(DISTINCT r.cliente_id)::int AS clientes_unicos
        {_REPORT_FROM}
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, shop_id, fecha_desde, fecha_hasta)


async def get_report_daily(
    pool: asyncpg.Pool, shop_id: int, fecha_desde: date, fecha_hasta: date
):
    query = f"""
        SELECT
            r.fecha,
            COUNT(r.id_reserva)::int AS total,
            COUNT(*) FILTER (WHERE r.estado = 'completada')::int AS completadas,
            COUNT(*) FILTER (WHERE r.estado = 'cancelada')::int AS canceladas,
            COALESCE(
                SUM(s.precio) FILTER (WHERE r.estado = 'completada'), 0
            ) AS ingresos
        {_REPORT_FROM}
        GROUP BY r.fecha
        ORDER BY r.fecha
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query, shop_id, fecha_desde, fecha_hasta)


async def get_top_services(
    pool: asyncpg.Pool, shop_id: int, fecha_desde: date, fecha_hasta: date, limit: int = 5
):
    query = f"""
        SELECT
            s.id_servicio,
            s.nombre,
            COUNT(r.id_reserva)::int AS reservas,
            COUNT(*) FILTER (WHERE r.estado = 'completada')::int AS completadas,
            COALESCE(
                SUM(s.precio) FILTER (WHERE r.estado = 'completada'), 0
            ) AS ingresos
        {_REPORT_FROM}
        GROUP BY s.id_servicio, s.nombre
        ORDER BY reservas DESC, ingresos DESC, s.nombre
        LIMIT $4
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query, shop_id, fecha_desde, fecha_hasta, limit)


async def get_top_professionals(
    pool: asyncpg.Pool, shop_id: int, fecha_desde: date, fecha_hasta: date, limit: int = 5
):
    query = """
        SELECT
            p.id_profesional,
            p.nombre,
            COUNT(r.id_reserva)::int AS reservas,
            COUNT(*) FILTER (WHERE r.estado = 'completada')::int AS completadas,
            COALESCE(
                SUM(s.precio) FILTER (WHERE r.estado = 'completada'), 0
            ) AS ingresos
        FROM reservas AS r
        INNER JOIN servicios AS s ON s.id_servicio = r.servicio_id
        INNER JOIN profesionales AS p ON p.id_profesional = r.profesional_id
        WHERE s.negocio_id = $1
          AND r.fecha BETWEEN $2 AND $3
          AND r.profesional_id IS NOT NULL
        GROUP BY p.id_profesional, p.nombre
        ORDER BY reservas DESC, ingresos DESC, p.nombre
        LIMIT $4
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query, shop_id, fecha_desde, fecha_hasta, limit)


async def get_report_weekdays(
    pool: asyncpg.Pool, shop_id: int, fecha_desde: date, fecha_hasta: date
):
    query = f"""
        SELECT
            EXTRACT(ISODOW FROM r.fecha)::int AS dia,
            COUNT(r.id_reserva)::int AS total,
            COALESCE(
                SUM(s.precio) FILTER (WHERE r.estado = 'completada'), 0
            ) AS ingresos
        {_REPORT_FROM}
        GROUP BY dia
        ORDER BY dia
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query, shop_id, fecha_desde, fecha_hasta)


async def get_report_hours(
    pool: asyncpg.Pool, shop_id: int, fecha_desde: date, fecha_hasta: date
):
    query = f"""
        SELECT
            EXTRACT(HOUR FROM r.hora_inicio)::int AS hora,
            COUNT(r.id_reserva)::int AS total
        {_REPORT_FROM}
        GROUP BY hora
        ORDER BY hora
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query, shop_id, fecha_desde, fecha_hasta)
