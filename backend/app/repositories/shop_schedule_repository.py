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
        return await conn.fetchrow(query, shop_id, day)  # 👈 FALTABA return
    
async def create_schedule(pool: asyncpg.Pool, shop_id: int, day: str, 
                          open_hour: str, close_hour: str):
    query = '''
        INSERT INTO horarios (negocio_id, dia, hora_apertura, hora_cierre)
        VALUES($1,$2,$3,$4)
        RETURNING id_horario, dia, hora_apertura, hora_cierre
    '''
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, shop_id, day, open_hour, close_hour)
    
async def get_schedule_by_id(pool: asyncpg.Pool, schedule_id: int):
    query = """
        SELECT id_horario, negocio_id, dia, hora_apertura, hora_cierre, hora_descanso, estado_horario
        FROM horarios WHERE id_horario = $1
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, schedule_id)

async def update_schedule(
    pool: asyncpg.Pool, 
    schedule_id: int, 
    hora_apertura: str | None, 
    hora_cierre: str | None, 
    hora_descanso: str | None,
    estado_horario: bool | None
):
    query = """
        UPDATE horarios
        SET hora_apertura = COALESCE($1, hora_apertura),
            hora_cierre = COALESCE($2, hora_cierre),
            hora_descanso = COALESCE($3, hora_descanso),
            estado_horario = COALESCE($4, estado_horario)
        WHERE id_horario = $5
        RETURNING id_horario, dia, hora_apertura, hora_cierre, hora_descanso, estado_horario
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(
            query, hora_apertura, hora_cierre, hora_descanso, estado_horario, schedule_id
        )

async def delete_schedule(pool: asyncpg.Pool, schedule_id: int):
    query = """
        DELETE FROM horarios WHERE id_horario = $1 RETURNING id_horario
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, schedule_id)