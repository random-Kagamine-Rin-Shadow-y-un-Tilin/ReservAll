import asyncpg

async def create_service(pool, negocio_id: int, data: dict):
    query = """
        INSERT INTO servicios (
            negocio_id, nombre, descripcion, duracion_minutos, precio,
             categoria_servicio, cantidad_servicio, estado_servicio
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING *
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(
            query,
            negocio_id,
            data['nombre'],
            data.get('descripcion'),
            data.get('duracion_minutos', 60),
            data.get('precio', 0),
            data.get('categoria_servicio', 'servicio'),
            data.get('cantidad_servicio', 1),
            data.get('estado_servicio', True),
        )

async def assign_professionals(pool, service_id: int, professional_ids: list[int]):
    if not professional_ids:
        return
    query = """
        INSERT INTO servicios_profesionales (servicio_id, profesional_id)
        VALUES ($1, $2)
        ON CONFLICT DO NOTHING
    """
    async with pool.acquire() as conn:
        for pid in professional_ids:
            await conn.execute(query, service_id, pid)

async def get_professionals_for_service(pool, service_id: int):
    query = """
        SELECT p.id_profesional, p.negocio_id, p.nombre, p.especialidad, p.activo, p.fecha_creacion
        FROM profesionales p
        INNER JOIN servicios_profesionales sp ON sp.profesional_id = p.id_profesional
        WHERE sp.servicio_id = $1 AND p.activo = true
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query, service_id)

async def get_services_by_shop(pool, shop_id: int):
    query = """
        SELECT * FROM servicios
        WHERE negocio_id = $1
        ORDER BY estado_servicio DESC, nombre
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query, shop_id)

async def get_service_by_id(pool, service_id: int):
    query = "SELECT * FROM servicios WHERE id_servicio = $1"
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, service_id)