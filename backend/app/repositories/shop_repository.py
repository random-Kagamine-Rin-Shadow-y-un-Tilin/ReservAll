import asyncpg

async def create_shop(pool: asyncpg.Pool, id_owner: int, name: str, description: str,
                      category: int, shop_img: str = "null"):
    query = """
        INSERT INTO negocios (dueno_id, nombre, descripcion, fecha_creacion, imagen_negocio,
        fk_categoria) VALUES($1, $2, $3, now(), $4, $5)
        RETURNING id
    """
    async with pool.acquire() as conn:
        shop = await conn.fetchrow(query, id_owner, name, description, shop_img, category)
        
    query = "SELECT * FROM negocios_view WHERE id = $1"
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, int(shop['id']))
    
async def get_shops_by_owner(pool: asyncpg.Pool, id_owner: int):
    query = """
        SELECT *
        FROM negocios_view
        WHERE dueno_id = $1
        ORDER BY fecha_creacion DESC
    """
    
    async with pool.acquire() as conn:
        return await conn.fetch(query, id_owner)
    
async def get_shop_by_id(pool: asyncpg.Pool, shop_id: int):
    query = """
        SELECT *
        FROM negocios_view
        WHERE id = $1
    """
    
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, shop_id)
    

async def edit_basic_shop(pool: asyncpg.Pool, id_shop: int, name: str, description: str,
                          category: str, shop_img: str = "null"):
    query = """
        UPDATE negocios SET nombre = $1, descripcion = $2, imagen_negocio = $3,
        fk_categoria = $4 WHERE id = $5
    """
    
    async with pool.acquire() as conn:
        await conn.fetchrow(query, name, description, shop_img, category, id_shop)
    
    query = "SELECT * FROM negocios_view WHERE id = $1"
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, id_shop)