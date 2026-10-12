import asyncpg
from datetime import datetime, timedelta, timezone

async def save_refresh_token(pool: asyncpg.Pool, user_id: int, token_hash: str, expire_days: int):
    expires_at = datetime.now(timezone.utc) + timedelta(days=expire_days)
    query = """
        INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
        VALUES ($1, $2, $3)
    """
    async with pool.acquire() as conn:
        await conn.execute(query, user_id, token_hash, expires_at)
        
async def get_valid_refresh_token(pool: asyncpg.Pool, token_hash: str) -> asyncpg.Record | None:
    query = """
        SELECT id, user_id, expires_at, revoked
        FROM refresh_tokens
        WHERE token_hash = $1 AND revoked = false AND expires_at > now()
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, token_hash)
    
async def revoke_all_user_tokens(pool: asyncpg.Pool, user_id: int):
    query = "UPDATE refresh_tokens SET revoked = true WHERE user_id = $1"
    async with pool.acquire() as conn:
        await conn.execute(query, user_id)