import asyncpg

async def get_contact_by_shop(pool: asyncpg.Pool, shop_id: int):
    query ="""
        SELECT id_social, nombre_red, url
        FROM redes_sociales
        WHERE negocio_id = $1
        ORDER BY nombre_red
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query, shop_id)
    
async def get_contact_by_shop_and_red(pool: asyncpg.Pool, shop_id: int, red_name: str):
    query = """
        SELECT id_social, nombre_red, url
        FROM redes_sociales
        WHERE negocio_id = $1 AND nombre_red = $2
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, shop_id, red_name)
    
async def create_contact(pool: asyncpg.Pool, shop_id: int, red_name: str, url: str):
    query = """
        INSERT INTO redes_sociales (negocio_id, nombre_red, url)
        VALUES ($1, $2, $3)
        RETURNING id_social, nombre_red, url
    """
    async with pool.acquire() as conn:
            return await conn.fetchrow(query, shop_id, red_name, url)
    
    