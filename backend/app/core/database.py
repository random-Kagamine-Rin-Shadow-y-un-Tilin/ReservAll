import asyncpg
from app.core.config import settings

pool: asyncpg.Pool | None = None

async def connect_db():
    global pool
    pool = await asyncpg.create_pool(
        dsn=settings.database_url,
        min_size=1,
        max_size=10,
        command_timeout= 60,
    )
    
async def close_db():
    global pool
    if pool:
        await pool.close()

def get_pool() -> asyncpg.Pool:
    if pool is None:
        raise RuntimeError("El pool de la base de datos no esta inicializado.")
    return pool