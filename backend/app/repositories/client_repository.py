import asyncpg
from typing import Optional, List
from datetime import date, time, datetime

# Consulta de todos los negocios-------------------------------------------
async def get_all_shops(pool: asyncpg.Pool):
    query = """
        SELECT id, nombre, descripcion, imagen_negocio, c.nombre_categoria as categoria_negocio
        FROM negocios 
        INNER JOIN categorias AS c ON id_categoria = fk_categoria
        where estado_negocio = true
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query)

# Busqueda de negocio por nombre -------------------------------------------
async def search_shops_by_name(pool: asyncpg.Pool, search_term: str):
    query = """
        SELECT id, nombre, descripcion, imagen_negocio, c.nombre_categoria as categoria_negocio
        FROM negocios 
        INNER JOIN categorias AS c ON id_categoria = fk_categoria
        WHERE estado_negocio = true 
        AND LOWER(nombre) LIKE LOWER($1)
        ORDER BY nombre
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query, f"%{search_term}%")

# Busqueda de negocio por categoria ----------------------------------------
async def search_shops_by_category(pool: asyncpg.Pool, category: str):
    query = """
        SELECT n.id, n.nombre, n.descripcion, n.imagen_negocio, c.nombre_categoria as categoria_negocio
        FROM negocios AS n
        INNER JOIN categorias AS c ON c.id_categoria = n.fk_categoria
        WHERE n.estado_negocio = true 
        AND LOWER(c.nombre_categoria) LIKE LOWER($1)
        ORDER BY n.nombre
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query, f"%{category}%")
    
#Busqueda de negocio por nombre y categoria --------------------------------
async def search_shops(pool: asyncpg.Pool, search_term: str):
    query = """
        SELECT id, nombre, descripcion, imagen_negocio, categoria_negocio, c.nombre_categoria as categoria_negocio
        FROM negocios 
        INNER JOIN categorias AS c ON c.id_categoria = fk_categoria
        WHERE estado_negocio = true 
        AND (
            LOWER(nombre) LIKE LOWER($1) 
            OR LOWER(descripcion) LIKE LOWER($1)
            OR LOWER(c.nombre_categoria) LIKE LOWER($1)
        )
        ORDER BY nombre
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query, f"%{search_term}%")

# Obtener un negocio por su ID
async def get_negocio_by_id(pool: asyncpg.Pool, negocio_id: int):
    query = """
        SELECT id, nombre, descripcion, imagen_negocio, c.nombre_categoria as categoria_negocio
        FROM negocios
        INNER JOIN categorias AS c ON id_categoria = fk_categoria
        WHERE id = $1 AND estado_negocio = true
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, negocio_id)

#Obtener horarios de un negocio para un día específico
async def get_horarios_by_negocio_dia(pool: asyncpg.Pool, negocio_id: int, dia: str):
    query = """
        SELECT  n.id, n.dueno_id, n.nombre, n.descripcion, n.imagen_negocio, c.nombre_categoria as categoria_negocio,
        n.estado_negocio, h.id_horario, h.dia, h.hora_apertura, h.hora_cierre, h.estado_horario,
        ho.id_hora, ho.hora_inicio, ho.hora_fin, ho.estado_hora
        FROM negocios AS n
        INNER JOIN categorias AS c ON id_categoria = fk_categoria
        INNER JOIN horarios AS h ON h.negocio_id = n.id
        INNER JOIN horas AS ho ON ho.horario_id = h.id_horario
        WHERE n.id = $1 
            AND n.estado_negocio = true AND h.estado_horario = true 
            AND ho.estado_hora = true AND LOWER(h.dia) = LOWER($2)
        ORDER BY ho.hora_inicio
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query, negocio_id, dia)

# Obtener horarios libres para un negocio en una fecha específica
async def get_reservas_by_negocio_fecha(pool: asyncpg.Pool, negocio_id: int, fecha: date):
    query = """
        SELECT 
            r.id_reserva, r.cliente_id, r.servicios_id, r.fecha,
            r.hora_inicio, s.duracion_minutos, r.estado, r.fecha_creacion
        FROM reservas AS r
        INNER JOIN servicios AS s ON s.id_servicio = r.servicios_id
        WHERE r.servicios_id IN (
            SELECT id_servicio FROM servicios WHERE negocio_id = $1
        )
        AND r.fecha = $2 AND r.estado IN ('pendiente', 'confirmada')
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query, negocio_id, fecha)

# Verificar si un horario específico está reservado
async def get_reservas_by_negocio_fecha_hora(
    pool: asyncpg.Pool, 
    negocio_id: int, 
    fecha: date,
    hora_inicio: time
):
    query = """
        SELECT 
            r.id_reserva, r.cliente_id, r.servicios_id, r.fecha, 
            r.hora_inicio, s.duracion_minutos, r.estado
        FROM reservas AS r
        INNER JOIN servicios AS s ON s.id_servicio = r.servicios_id
        WHERE r.servicios_id IN (
            SELECT id_servicio FROM servicios WHERE negocio_id = $1
        )
        AND r.fecha = $2 
        AND r.hora_inicio = $3
        AND r.estado IN ('pendiente', 'confirmada')
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, negocio_id, fecha, hora_inicio)

# Obtener servicios de un negocio
async def get_servicios_by_negocio(pool: asyncpg.Pool, negocio_id: int):
    query = """
        SELECT 
            id_servicio, negocio_id, nombre, duracion_minutos, precio
        FROM servicios
        WHERE negocio_id = $1
        ORDER BY nombre
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query, negocio_id)

# Obtener un servicio por su ID
async def get_servicio_by_id(pool: asyncpg.Pool, servicio_id: int):
    query = """
        SELECT 
            id_servicio, negocio_id, nombre, duracion_minutos, precio
        FROM servicios
        WHERE id_servicio = $1
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, servicio_id)

# Crear una nueva reserva
async def create_reserva(
    pool: asyncpg.Pool,
    cliente_id: int,
    servicio_id: int,
    fecha: date,
    hora_inicio: time
):
    query = """
        INSERT INTO reservas (
            clientes_id, servicios_id, fecha, hora_inicio, estado, fecha_creacion
        ) VALUES ($1, $2, $3, $4, 'pendiente', NOW())
        RETURNING id_reserva, clientes_id, servicios_id, fecha, hora_inicio, estado, fecha_creacion
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, cliente_id, servicio_id, fecha, hora_inicio)

# Obtener todos los horarios de un negocio
async def get_horarios_by_negocio(pool: asyncpg.Pool, negocio_id: int):
    query = """
        SELECT 
            h.id_horario, h.negocio_id, h.dia, h.hora_apertura, h.hora_cierre,
            h.estado_horario, ho.id_hora, ho.hora_inicio, ho.hora_fin, ho.estado_hora
        FROM horarios AS h
        INNER JOIN horas AS ho ON ho.horario_id = h.id_horario
        WHERE h.negocio_id = $1 
            AND h.estado_horario = true 
            AND ho.estado_hora = true
        ORDER BY h.dia, ho.hora_inicio
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query, negocio_id)