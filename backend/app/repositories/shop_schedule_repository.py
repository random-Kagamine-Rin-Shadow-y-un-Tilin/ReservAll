import asyncpg

async def get_weekly_schedule(pool: asyncpg.Pool, shop_id: int):
    query = """
        SELECT * FROM horarios
        WHERE negocio_id = $1
        AND estado_horario = TRUE
    """
    
    async with pool.acquire() as conn:
        return await conn.fetch(query, shop_id)
 
async def get_day_by_shop_and_day(pool: asyncpg.Pool, shop_id: int, day: str):
    query = """
        SELECT id_horario, dia
        FROM horarios WHERE negocio_id = $1 
        AND dia = $2
    """
    async with pool.acquire() as conn:
        conn.fetchrow(query, shop_id, day)
    
   
async def create_schedule(pool: asyncpg.Pool, shop_id: int, day: str, 
                          open_hour: str, close_hour: str):
    query = '''
        INSERT INTO horarios (negocio_id, dia, hora_apertura, hora_cierre)
        VALUES($1,$2,$3,$4)
        RETURNING id_horario, dia, hora_apertura, hora_cierre
    '''
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, shop_id, day, open_hour, close_hour)
    