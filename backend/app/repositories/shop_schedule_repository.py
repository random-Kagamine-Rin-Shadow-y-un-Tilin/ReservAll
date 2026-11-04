import asyncpg
from typing import Optional


async def get_weekly_schedule(
    pool: asyncpg.Pool, shop_id: int, include_inactive: bool = True
):
    query = """
        SELECT id_horario, negocio_id, dia, hora_apertura, hora_cierre,
               hora_descanso, estado_horario
        FROM horarios
        WHERE negocio_id = $1
    """
    if not include_inactive:
        query += " AND estado_horario = TRUE"
    query += " ORDER BY dia"

    async with pool.acquire() as conn:
        return await conn.fetch(query, shop_id)


async def get_day_by_shop_and_day(pool: asyncpg.Pool, shop_id: int, day: str):
    query = """
        SELECT id_horario, dia
        FROM horarios
        WHERE negocio_id = $1
          AND dia = $2
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, shop_id, day)


async def create_schedule(
    pool: asyncpg.Pool,
    shop_id: int,
    day: str,
    open_hour: str,
    close_hour: str,
    break_hour: Optional[str] = None,
):
    query = """
        INSERT INTO horarios (
            negocio_id, dia, hora_apertura, hora_cierre, hora_descanso
        )
        VALUES ($1, $2, $3, $4, $5)
        RETURNING id_horario, dia, hora_apertura, hora_cierre,
                  hora_descanso, estado_horario
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(
            query, shop_id, day, open_hour, close_hour, break_hour
        )


async def get_schedule_by_id(pool: asyncpg.Pool, schedule_id: int):
    query = """
        SELECT id_horario, negocio_id, dia, hora_apertura, hora_cierre,
               hora_descanso, estado_horario
        FROM horarios
        WHERE id_horario = $1
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, schedule_id)


async def update_schedule(
    pool: asyncpg.Pool, schedule_id: int, fields: dict
):
    """Actualiza solo los campos enviados.

    Se usa un UPDATE dinámico para poder distinguir entre un campo omitido y
    un ``hora_descanso: null`` explícito (que debe borrar el descanso).
    """

    allowed = {"hora_apertura", "hora_cierre", "hora_descanso", "estado_horario"}
    sets: list[str] = []
    values: list[object] = []

    for key, value in fields.items():
        if key not in allowed:
            continue
        values.append(value)
        sets.append(f"{key} = ${len(values)}")

    if not sets:
        return await get_schedule_by_id(pool, schedule_id)

    values.append(schedule_id)
    query = f"""
        UPDATE horarios
        SET {', '.join(sets)}
        WHERE id_horario = ${len(values)}
        RETURNING id_horario, dia, hora_apertura, hora_cierre,
                  hora_descanso, estado_horario
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, *values)


async def delete_schedule(pool: asyncpg.Pool, schedule_id: int):
    query = """
        DELETE FROM horarios
        WHERE id_horario = $1
        RETURNING id_horario
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, schedule_id)
