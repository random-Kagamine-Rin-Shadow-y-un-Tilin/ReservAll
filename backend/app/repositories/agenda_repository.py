import asyncpg
from datetime import date, time
from typing import Optional


_BLOCK_FIELDS = """
    id_bloqueo, negocio_id, fecha, hora_inicio, hora_fin, motivo, fecha_creacion
"""


async def get_blocks(
    pool: asyncpg.Pool,
    shop_id: int,
    fecha_desde: Optional[date] = None,
    fecha_hasta: Optional[date] = None,
    block_id: Optional[int] = None,
):
    conditions = ["negocio_id = $1"]
    params: list[object] = [shop_id]

    if fecha_desde is not None:
        params.append(fecha_desde)
        conditions.append(f"fecha >= ${len(params)}::date")
    if fecha_hasta is not None:
        params.append(fecha_hasta)
        conditions.append(f"fecha <= ${len(params)}::date")
    if block_id is not None:
        params.append(block_id)
        conditions.append(f"id_bloqueo = ${len(params)}")

    query = f"""
        SELECT {_BLOCK_FIELDS}
        FROM bloqueos_agenda
        WHERE {' AND '.join(conditions)}
        ORDER BY fecha, hora_inicio NULLS FIRST, id_bloqueo
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query, *params)


async def get_blocks_by_date(pool: asyncpg.Pool, shop_id: int, fecha: date):
    query = f"""
        SELECT {_BLOCK_FIELDS}
        FROM bloqueos_agenda
        WHERE negocio_id = $1
          AND fecha = $2
        ORDER BY hora_inicio NULLS FIRST, id_bloqueo
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query, shop_id, fecha)


async def get_block_by_id(pool: asyncpg.Pool, block_id: int):
    query = f"""
        SELECT {_BLOCK_FIELDS}
        FROM bloqueos_agenda
        WHERE id_bloqueo = $1
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, block_id)


async def create_block(
    pool: asyncpg.Pool,
    shop_id: int,
    fecha: date,
    hora_inicio: Optional[time],
    hora_fin: Optional[time],
    motivo: Optional[str],
):
    query = f"""
        INSERT INTO bloqueos_agenda (
            negocio_id, fecha, hora_inicio, hora_fin, motivo
        )
        VALUES ($1, $2, $3, $4, $5)
        RETURNING {_BLOCK_FIELDS}
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(
            query, shop_id, fecha, hora_inicio, hora_fin, motivo
        )


async def delete_block(pool: asyncpg.Pool, block_id: int):
    query = """
        DELETE FROM bloqueos_agenda
        WHERE id_bloqueo = $1
        RETURNING id_bloqueo
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, block_id)


async def get_overlapping_blocks(
    pool: asyncpg.Pool,
    shop_id: int,
    fecha: date,
    hora_inicio: Optional[time],
    hora_fin: Optional[time],
):
    """Bloqueos que se solapan con el rango indicado.

    Si ``hora_inicio`` es ``None`` se considera un bloqueo de día completo y
    cualquier bloqueo existente ese día se reporta como solapado.
    """

    query = f"""
        SELECT {_BLOCK_FIELDS}
        FROM bloqueos_agenda
        WHERE negocio_id = $1
          AND fecha = $2
          AND (
                hora_inicio IS NULL
                OR $3::time IS NULL
                OR (hora_inicio < $4 AND hora_fin > $3)
              )
        ORDER BY hora_inicio NULLS FIRST, id_bloqueo
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query, shop_id, fecha, hora_inicio, hora_fin)


async def get_overlapping_reservations(
    pool: asyncpg.Pool,
    shop_id: int,
    fecha: date,
    hora_inicio: Optional[time],
    hora_fin: Optional[time],
    profesional_id: Optional[int] = None,
):
    """Reservas activas que se solapan con el rango indicado.

    Si ``hora_inicio`` es ``None`` se consideran todas las reservas activas del
    día (bloqueo de día completo).
    """

    query = """
        SELECT
            r.id_reserva,
            r.cliente_id,
            r.profesional_id,
            r.hora_inicio,
            COALESCE(
                r.hora_fin,
                r.hora_inicio + make_interval(mins => s.duracion_minutos)
            ) AS hora_fin
        FROM reservas AS r
        INNER JOIN servicios AS s ON s.id_servicio = r.servicio_id
        WHERE s.negocio_id = $1
          AND r.fecha = $2
          AND r.estado IN ('pendiente', 'confirmada')
          AND (
                $3::time IS NULL
                OR (
                    r.hora_inicio < $4
                    AND COALESCE(
                        r.hora_fin,
                        r.hora_inicio + make_interval(mins => s.duracion_minutos)
                    ) > $3
                )
              )
          AND ($5::int IS NULL OR r.profesional_id = $5 OR r.profesional_id IS NULL)
        ORDER BY r.hora_inicio
    """
    async with pool.acquire() as conn:
        return await conn.fetch(
            query, shop_id, fecha, hora_inicio, hora_fin, profesional_id
        )


async def get_service_by_id(pool: asyncpg.Pool, service_id: int):
    query = """
        SELECT id_servicio, negocio_id, nombre, duracion_minutos, precio,
               estado_servicio
        FROM servicios
        WHERE id_servicio = $1
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, service_id)


async def get_professional_by_id(pool: asyncpg.Pool, professional_id: int):
    query = """
        SELECT id_profesional, negocio_id, nombre, especialidad, activo
        FROM profesionales
        WHERE id_profesional = $1
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, professional_id)
