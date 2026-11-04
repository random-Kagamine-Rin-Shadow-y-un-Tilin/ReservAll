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
        SELECT
            n.id, n.dueno_id, n.nombre, n.descripcion, n.imagen_negocio,
            c.nombre_categoria AS categoria_negocio, n.estado_negocio,
            h.id_horario, h.dia, h.hora_apertura, h.hora_cierre,
            h.hora_descanso, h.estado_horario
        FROM negocios AS n
        INNER JOIN categorias AS c ON c.id_categoria = n.fk_categoria
        INNER JOIN horarios AS h ON h.negocio_id = n.id
        WHERE n.id = $1
            AND n.estado_negocio = true
            AND h.estado_horario = true
            AND LOWER(h.dia::text) = LOWER($2)
        ORDER BY h.hora_apertura
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query, negocio_id, dia)

# Obtener horarios libres para un negocio en una fecha específica
async def get_reservas_by_negocio_fecha(
    pool: asyncpg.Pool,
    negocio_id: int,
    fecha: date,
    profesional_id: Optional[int] = None,
):
    query = """
        SELECT
            r.id_reserva, r.cliente_id, r.servicio_id, r.fecha,
            r.hora_inicio, r.hora_fin, s.duracion_minutos, r.estado,
            r.fecha_creacion, r.profesional_id
        FROM reservas AS r
        INNER JOIN servicios AS s ON s.id_servicio = r.servicio_id
        WHERE s.negocio_id = $1
        AND r.fecha = $2 AND r.estado IN ('pendiente', 'confirmada')
    """
    params: list[object] = [negocio_id, fecha]
    if profesional_id is not None:
        params.append(profesional_id)
        query += (
            f" AND (r.profesional_id = ${len(params)}"
            " OR r.profesional_id IS NULL)"
        )
    query += " ORDER BY r.hora_inicio"

    async with pool.acquire() as conn:
        return await conn.fetch(query, *params)

# Verificar si un horario específico está reservado
async def get_reservas_by_negocio_fecha_hora(
    pool: asyncpg.Pool,
    negocio_id: int,
    fecha: date,
    hora_inicio: time
):
    query = """
        SELECT
            r.id_reserva, r.cliente_id, r.servicio_id, r.fecha,
            r.hora_inicio, s.duracion_minutos, r.estado
        FROM reservas AS r
        INNER JOIN servicios AS s ON s.id_servicio = r.servicio_id
        WHERE s.negocio_id = $1
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
          AND estado_servicio = true
        ORDER BY nombre
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query, negocio_id)

# Obtener un servicio por su ID
async def get_servicio_by_id(pool: asyncpg.Pool, servicio_id: int):
    query = """
        SELECT 
            id_servicio, negocio_id, nombre, duracion_minutos, precio,
            estado_servicio
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
    hora_inicio: time,
    hora_fin: time,
    profesional_id: Optional[int] = None,
):
    query = """
        INSERT INTO reservas (
            cliente_id, servicio_id, fecha, hora_inicio, hora_fin, estado,
            fecha_creacion, profesional_id
        ) VALUES ($1, $2, $3, $4, $5, 'pendiente', NOW(), $6)
        RETURNING id_reserva, cliente_id, servicio_id, fecha, hora_inicio,
                  hora_fin, estado, fecha_creacion, profesional_id
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(
            query,
            cliente_id,
            servicio_id,
            fecha,
            hora_inicio,
            hora_fin,
            profesional_id,
        )


async def create_reserva_atomic(
    pool: asyncpg.Pool,
    negocio_id: int,
    cliente_id: int,
    servicio_id: int,
    fecha: date,
    hora_inicio: time,
    hora_fin: time,
    profesional_id: Optional[int] = None,
):
    """Inserta la reserva solo si el espacio sigue libre.

    Se toma un lock por negocio para evitar que dos peticiones simultáneas
    pasen la validación y creen reservas duplicadas. La comprobación de
    solapamientos y la inserción ocurren en la misma transacción.
    """

    query = """
        WITH lock AS (
            SELECT pg_advisory_xact_lock($1::bigint) AS acquired
        )
        INSERT INTO reservas (
            cliente_id, servicio_id, fecha, hora_inicio, hora_fin, estado,
            fecha_creacion, profesional_id
        )
        SELECT $2, $3, $4, $5, $6, 'pendiente', NOW(), $7
        FROM lock
        WHERE NOT EXISTS (
            SELECT 1
            FROM reservas AS r
            INNER JOIN servicios AS s ON s.id_servicio = r.servicio_id
            WHERE s.negocio_id = $1::bigint
              AND r.fecha = $4
              AND r.estado IN ('pendiente', 'confirmada')
              AND r.hora_inicio < $6
              AND COALESCE(
                    r.hora_fin,
                    r.hora_inicio + make_interval(mins => s.duracion_minutos)
                  ) > $5
              AND ($7::int IS NULL OR r.profesional_id = $7 OR r.profesional_id IS NULL)
        )
        AND NOT EXISTS (
            SELECT 1
            FROM bloqueos_agenda AS b
            WHERE b.negocio_id = $1::bigint
              AND b.fecha = $4
              AND (
                    b.hora_inicio IS NULL
                    OR (b.hora_inicio < $6 AND b.hora_fin > $5)
                  )
        )
        RETURNING id_reserva, cliente_id, servicio_id, fecha, hora_inicio,
                  hora_fin, estado, fecha_creacion, profesional_id
    """
    async with pool.acquire() as conn:
        async with conn.transaction():
            return await conn.fetchrow(
                query,
                negocio_id,
                cliente_id,
                servicio_id,
                fecha,
                hora_inicio,
                hora_fin,
                profesional_id,
            )


# Profesionales --------------------------------------------------------------
async def get_profesional_by_id(pool: asyncpg.Pool, profesional_id: int):
    query = """
        SELECT id_profesional, negocio_id, nombre, especialidad, activo
        FROM profesionales
        WHERE id_profesional = $1
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, profesional_id)


async def get_profesionales_by_negocio(pool: asyncpg.Pool, negocio_id: int):
    query = """
        SELECT id_profesional, negocio_id, nombre, especialidad, activo
        FROM profesionales
        WHERE negocio_id = $1
          AND activo = true
        ORDER BY nombre
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query, negocio_id)


async def get_profesionales_for_service(
    pool: asyncpg.Pool, servicio_id: int
):
    query = """
        SELECT p.id_profesional, p.negocio_id, p.nombre, p.especialidad,
               p.activo
        FROM profesionales AS p
        INNER JOIN servicios_profesionales AS sp
            ON sp.profesional_id = p.id_profesional
        WHERE sp.servicio_id = $1
          AND p.activo = true
        ORDER BY p.nombre
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query, servicio_id)

# Obtener todos los horarios de un negocio
async def get_horarios_by_negocio(pool: asyncpg.Pool, negocio_id: int):
    query = """
        SELECT
            h.id_horario, h.negocio_id, h.dia, h.hora_apertura, h.hora_cierre,
            h.hora_descanso, h.estado_horario
        FROM horarios AS h
        WHERE h.negocio_id = $1
            AND h.estado_horario = true
        ORDER BY h.dia, h.hora_apertura
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query, negocio_id)