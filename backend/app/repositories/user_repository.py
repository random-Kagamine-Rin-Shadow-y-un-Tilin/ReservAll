import asyncpg

async def get_user_by_email(pool: asyncpg.Pool, email: str) -> asyncpg.Record | None:
    query = "SELECT id, nombre, correo, password_hash, rol FROM usuarios WHERE correo = $1"
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, email)

async def get_user_by_id(pool: asyncpg.Pool, user_id: int) -> asyncpg.Record | None:
    query = "SELECT id, nombre, correo, rol FROM usuarios WHERE id = $1"
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, user_id)

async def create_user(
    pool: asyncpg.Pool, name: str, email: str, password_hash: str, rol:str = "cliente"
) -> asyncpg.Record:
    query = """
        INSERT INTO usuarios (nombre, correo, password_hash, rol, fecha_registro)
        VALUES ($1, $2, $3, $4, now())
        RETURNING id, nombre, correo, rol
 """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, name, email, password_hash, rol)