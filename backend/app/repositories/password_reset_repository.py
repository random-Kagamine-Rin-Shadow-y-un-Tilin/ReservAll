from datetime import UTC, datetime, timedelta

import asyncpg


class CodeNotConsumable(Exception):
    """El código dejó de ser válido antes de completar el cambio."""


async def invalidate_previous_codes(pool: asyncpg.Pool, user_id: int) -> None:
    query = """
        UPDATE password_reset_codes
        SET usado = TRUE
        WHERE user_id = $1 AND usado = FALSE
    """
    async with pool.acquire() as conn:
        await conn.execute(query, user_id)


async def create_code(
    pool: asyncpg.Pool,
    user_id: int,
    code_hash: str,
    ttl_minutes: int,
) -> asyncpg.Record:
    expires_at = datetime.now(UTC) + timedelta(minutes=ttl_minutes)
    query = """
        INSERT INTO password_reset_codes (user_id, code_hash, expires_at)
        VALUES ($1, $2, $3)
        RETURNING id, expires_at
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, user_id, code_hash, expires_at)


async def get_valid_code(
    pool: asyncpg.Pool,
    user_id: int,
    code_hash: str,
    max_intentos: int = 5,
) -> asyncpg.Record | None:
    query = """
        SELECT id, user_id, expires_at, intentos
        FROM password_reset_codes
        WHERE user_id = $1
          AND code_hash = $2
          AND usado = FALSE
          AND expires_at > now()
          AND intentos < $3
        ORDER BY expires_at DESC
        LIMIT 1
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, user_id, code_hash, max_intentos)


async def register_failed_attempt(
    pool: asyncpg.Pool,
    user_id: int,
    code_hash: str,
    max_intentos: int = 5,
) -> None:
    """Contabiliza intentos fallidos para limitar la fuerza bruta del código."""

    query = """
        UPDATE password_reset_codes
        SET intentos = intentos + 1
        WHERE user_id = $1
          AND code_hash = $2
          AND usado = FALSE
          AND expires_at > now()
          AND intentos < $3
    """
    async with pool.acquire() as conn:
        await conn.execute(query, user_id, code_hash, max_intentos)


async def consume_code_and_change_password(
    pool: asyncpg.Pool, code_id: int, user_id: int, password_hash: str
):
    """Consume el código y cambia la contraseña en una sola transacción.

    El ``UPDATE`` condicional garantiza que un código solo pueda usarse una vez
    aunque dos peticiones lo validen al mismo tiempo.
    """

    async with pool.acquire() as conn, conn.transaction():
        updated = await conn.fetchrow(
            """
                UPDATE usuarios
                SET password_hash = $2
                WHERE id = $1
                RETURNING id, nombre, correo, rol
                """,
            user_id,
            password_hash,
        )
        if updated is None:
            raise CodeNotConsumable

        consumido = await conn.fetchrow(
            """
                UPDATE password_reset_codes
                SET usado = TRUE, usado_en = now()
                WHERE id = $1
                  AND user_id = $2
                  AND usado = FALSE
                  AND expires_at > now()
                RETURNING user_id
                """,
            code_id,
            user_id,
        )
        if consumido is None:
            # Rollback: no se cambia la contraseña si el código ya se usó.
            raise CodeNotConsumable

        # Una vez cambiada la contraseña, invalidamos las sesiones previas.
        await conn.execute(
            "UPDATE refresh_tokens SET revoked = TRUE WHERE user_id = $1",
            user_id,
        )
    return updated
