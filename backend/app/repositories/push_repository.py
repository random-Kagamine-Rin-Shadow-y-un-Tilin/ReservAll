from datetime import datetime
from typing import Optional

import asyncpg


async def upsert_subscription(
    pool: asyncpg.Pool,
    user_id: int,
    endpoint: str,
    p256dh: str,
    auth: str,
    user_agent: Optional[str] = None,
):
    query = """
        INSERT INTO push_subscriptions (
            user_id, endpoint, p256dh, auth, user_agent
        )
        VALUES ($1, $2, $3, $4, $5)
        ON CONFLICT (endpoint) DO UPDATE SET
            user_id = EXCLUDED.user_id,
            p256dh = EXCLUDED.p256dh,
            auth = EXCLUDED.auth,
            user_agent = EXCLUDED.user_agent,
            updated_at = NOW()
        RETURNING id, user_id, endpoint
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(
            query, user_id, endpoint, p256dh, auth, user_agent
        )


async def delete_subscription(
    pool: asyncpg.Pool,
    user_id: int,
    endpoint: str,
) -> bool:
    query = """
        DELETE FROM push_subscriptions
        WHERE user_id = $1 AND endpoint = $2
        RETURNING id
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, user_id, endpoint) is not None


async def delete_subscription_by_endpoint(
    pool: asyncpg.Pool,
    endpoint: str,
) -> bool:
    query = """
        DELETE FROM push_subscriptions
        WHERE endpoint = $1
        RETURNING id
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, endpoint) is not None


async def count_subscriptions(pool: asyncpg.Pool, user_id: int) -> int:
    query = "SELECT COUNT(*)::int AS total FROM push_subscriptions WHERE user_id = $1"
    async with pool.acquire() as conn:
        row = await conn.fetchrow(query, user_id)
    return int(row["total"]) if row else 0


async def list_user_subscriptions(pool: asyncpg.Pool, user_id: int):
    query = """
        SELECT id, user_id, endpoint, p256dh, auth
        FROM push_subscriptions
        WHERE user_id = $1
        ORDER BY id
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query, user_id)


async def get_due_reservations(
    pool: asyncpg.Pool,
    window_start: datetime,
    window_end: datetime,
):
    query = """
        SELECT
            r.id_reserva,
            r.fecha,
            r.hora_inicio,
            r.estado::text AS estado,
            s.nombre AS servicio_nombre,
            n.id AS negocio_id,
            n.nombre AS negocio_nombre,
            n.dueno_id,
            u.nombre AS cliente_nombre
        FROM reservas AS r
        INNER JOIN servicios AS s ON s.id_servicio = r.servicio_id
        INNER JOIN negocios AS n ON n.id = s.negocio_id
        INNER JOIN usuarios AS u ON u.id = r.cliente_id
        WHERE r.estado IN ('pendiente', 'confirmada')
          AND (r.fecha + r.hora_inicio) >= $1
          AND (r.fecha + r.hora_inicio) <= $2
        ORDER BY r.fecha, r.hora_inicio, r.id_reserva
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query, window_start, window_end)


async def claim_notification(
    pool: asyncpg.Pool,
    reservation_id: int,
    kind: str = "reserva",
) -> bool:
    query = """
        INSERT INTO push_notifications_log (reserva_id, kind)
        VALUES ($1, $2)
        ON CONFLICT (reserva_id, kind) DO NOTHING
        RETURNING id
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, reservation_id, kind) is not None


async def release_notification(
    pool: asyncpg.Pool,
    reservation_id: int,
    kind: str = "reserva",
) -> None:
    query = """
        DELETE FROM push_notifications_log
        WHERE reserva_id = $1 AND kind = $2
    """
    async with pool.acquire() as conn:
        await conn.execute(query, reservation_id, kind)
