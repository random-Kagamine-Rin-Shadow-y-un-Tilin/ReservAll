import asyncpg

async def create_professional(pool, negocio_id: int, data: dict):
    query = """
        INSERT INTO profesionales (negocio_id, nombre, especialidad)
        VALUES ($1, $2, $3)
        RETURNING id_profesional, negocio_id, nombre, especialidad, activo, fecha_creacion
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(
            query, negocio_id, data['nombre'], data.get('especialidad')
        )

async def get_professionals_by_shop(pool, shop_id: int):
    query = """
        SELECT id_profesional, negocio_id, nombre, especialidad , activo, fecha_creacion
        FROM profesionales
        WHERE negocio_id = $1 AND activo = true
        ORDER BY nombre
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query, shop_id)

async def get_professional_by_id(pool, professional_id: int):
    query = "SELECT * FROM profesionales WHERE id_profesional = $1"
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, professional_id)

async def update_professional(pool, professional_id: int, data: dict):
    fields = []
    values = []
    idx = 1
    for key, value in data.items():
        if value is not None:
            fields.append(f"{key} = ${idx}")
            values.append(value)
            idx += 1

    if not fields:
        return await get_professional_by_id(pool, professional_id)

    values.append(professional_id)
    query = f"""
        UPDATE profesionales SET {', '.join(fields)}
        WHERE id_profesional = ${idx}
        RETURNING *
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, *values)

async def deactivate_professional(pool, professional_id: int):
    query = """
        UPDATE profesionales SET activo = false
        WHERE id_profesional = $1
        RETURNING id_profesional, nombre
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, professional_id)