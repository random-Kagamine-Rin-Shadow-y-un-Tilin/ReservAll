import asyncpg

async def get_shop_address(pool: asyncpg.Pool, shop_id: int):
    query = """
    SELECT * FROM direcciones_negocio
    WHERE negocio_id = $1
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, shop_id)
        
async def register_address(
    pool: asyncpg.Pool,
    shop_id: int,
    direccion_calle: str,
    ciudad: str,
    estado: str,
    codigo_postal: str,
    pais: str,
    latitud: float,
    longitud: float,
    osm_id: str,
    numero_local: str,
    numero_interior: str = 'Sin Número',
):
    query = """
    INSERT INTO direcciones_negocio 
    (negocio_id, direccion_calle, ciudad, estado, codigo_postal, pais, latitud, 
    longitud, osm_id, numero_local, numero_interior, fecha_creacion, fecha_actualizacion) 
    VALUES
    ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, now(), now())
    RETURNING id_direccion, direccion_calle, ciudad, estado, codigo_postal, pais, latitud, 
    longitud, osm_id, numero_local, numero_interior
    """
    
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, shop_id, direccion_calle, ciudad, estado,
                                   codigo_postal, pais, latitud, longitud, osm_id,
                                   numero_local, numero_interior)
    