import asyncpg
from typing import Optional


# Se lee con to_jsonb para que las consultas sigan funcionando en bases donde
# todavía no se aplicó la migración 005 (columna `descanso_duracion_min`).
_SCHEDULE_COLUMNS = """
    id_horario, negocio_id, dia, hora_apertura, hora_cierre,
    hora_descanso,
    COALESCE((to_jsonb(horarios)->>'descanso_duracion_min')::int, 60)
        AS descanso_duracion_min,
    estado_horario
"""

# En INSERT/UPDATE RETURNING también se usa la expresión anterior: funciona
# tanto con la columna presente como sin ella.
_SCHEDULE_RETURNING = """
    id_horario, dia, hora_apertura, hora_cierre, hora_descanso,
    COALESCE((to_jsonb(horarios)->>'descanso_duracion_min')::int, 60)
        AS descanso_duracion_min,
    estado_horario
"""


async def _has_break_duration_column(conn: asyncpg.Connection) -> bool:
    """Indica si la BD tiene la columna añadida por la migración 005."""
    return bool(
        await conn.fetchval(
            """
            SELECT EXISTS (
                SELECT 1
                FROM information_schema.columns
                WHERE table_schema = 'public'
                  AND table_name = 'horarios'
                  AND column_name = 'descanso_duracion_min'
            )
            """
        )
    )


async def get_weekly_schedule(
    pool: asyncpg.Pool, shop_id: int, include_inactive: bool = True
):
    query = f"""
        SELECT {_SCHEDULE_COLUMNS}
        FROM horarios
        WHERE negocio_id = $1
    """
    if not include_inactive:
        query += " AND estado_horario = TRUE"
    query += " ORDER BY dia, hora_apertura"

    async with pool.acquire() as conn:
        return await conn.fetch(query, shop_id)


async def get_schedules_by_shop_and_day(pool: asyncpg.Pool, shop_id: int, day: str):
    query = f"""
        SELECT {_SCHEDULE_COLUMNS}
        FROM horarios
        WHERE negocio_id = $1 AND dia = $2
        ORDER BY hora_apertura
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query, shop_id, day)


async def create_schedule(
    pool: asyncpg.Pool,
    shop_id: int,
    day: str,
    open_hour,
    close_hour,
    break_hour: Optional[object] = None,
    break_duration_min: int = 60,
    estado_horario: bool = True,
):
    async with pool.acquire() as conn:
        if await _has_break_duration_column(conn):
            query = f"""
                INSERT INTO horarios (
                    negocio_id, dia, hora_apertura, hora_cierre, hora_descanso,
                    descanso_duracion_min, estado_horario
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7)
                RETURNING {_SCHEDULE_RETURNING}
            """
            args = (
                shop_id,
                day,
                open_hour,
                close_hour,
                break_hour,
                break_duration_min,
                estado_horario,
            )
        else:
            # Base sin migrar: se guarda el resto del horario y se devuelve la
            # duración por defecto para no romper la respuesta de la API.
            query = f"""
                INSERT INTO horarios (
                    negocio_id, dia, hora_apertura, hora_cierre, hora_descanso,
                    estado_horario
                )
                VALUES ($1, $2, $3, $4, $5, $6)
                RETURNING {_SCHEDULE_RETURNING}
            """
            args = (
                shop_id,
                day,
                open_hour,
                close_hour,
                break_hour,
                estado_horario,
            )
        return await conn.fetchrow(query, *args)


async def get_schedule_by_id(pool: asyncpg.Pool, schedule_id: int):
    query = f"""
        SELECT {_SCHEDULE_COLUMNS}
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

    allowed = {
        "hora_apertura",
        "hora_cierre",
        "hora_descanso",
        "descanso_duracion_min",
        "estado_horario",
    }

    async with pool.acquire() as conn:
        if not await _has_break_duration_column(conn):
            allowed.discard("descanso_duracion_min")

        sets: list[str] = []
        values: list[object] = []

        for key, value in fields.items():
            if key not in allowed:
                continue
            values.append(value)
            sets.append(f"{key} = ${len(values)}")

        if not sets:
            return await conn.fetchrow(
                f"""
                SELECT {_SCHEDULE_COLUMNS}
                FROM horarios
                WHERE id_horario = $1
                """,
                schedule_id,
            )

        values.append(schedule_id)
        query = f"""
            UPDATE horarios
            SET {', '.join(sets)}
            WHERE id_horario = ${len(values)}
            RETURNING {_SCHEDULE_RETURNING}
        """
        return await conn.fetchrow(query, *values)


async def delete_schedule(pool: asyncpg.Pool, schedule_id: int):
    query = """
        DELETE FROM horarios
        WHERE id_horario = $1
        RETURNING id_horario
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, schedule_id)
