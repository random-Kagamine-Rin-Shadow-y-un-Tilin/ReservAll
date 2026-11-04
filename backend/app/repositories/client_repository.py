import asyncpg
from typing import Optional
from datetime import date, time

# Catálogo de negocios -------------------------------------------------------
#
# La búsqueda se construye sobre una única consulta enriquecida. Así todos los
# filtros (texto, categoría, ubicación, precio, orden) comparten la misma
# información y no hay que mantener cuatro SQL distintos que se desincronicen.

_SHOP_SELECT = """
    SELECT
        n.id,
        n.nombre,
        n.descripcion,
        n.imagen_negocio,
        c.id_categoria,
        c.nombre_categoria AS categoria_negocio,
        NULLIF(
            CONCAT_WS(
                ', ',
                NULLIF(
                    TRIM(
                        CONCAT_WS(
                            ' ',
                            d.direccion_calle,
                            d.numero_local,
                            d.numero_interior
                        )
                    ),
                    ''
                ),
                NULLIF(d.ciudad, ''),
                NULLIF(d.estado, '')
            ),
            ''
        ) AS direccion,
        d.ciudad,
        d.estado AS estado_direccion,
        d.pais,
        d.latitud,
        d.longitud,
        ss.precio_minimo,
        ss.precio_maximo,
        COALESCE(ss.servicios_count, 0) AS servicios_count,
        COALESCE(ss.servicios_nombres, ARRAY[]::text[]) AS servicios,
        COALESCE(pop.reservas_count, 0) AS reservas_count,
        NULL::double precision AS valoracion
        {distance_select}
    FROM negocios AS n
    INNER JOIN categorias AS c ON c.id_categoria = n.fk_categoria
    LEFT JOIN direcciones_negocio AS d ON d.negocio_id = n.id
    LEFT JOIN (
        SELECT
            negocio_id,
            MIN(precio) AS precio_minimo,
            MAX(precio) AS precio_maximo,
            COUNT(*) AS servicios_count,
            array_agg(nombre ORDER BY nombre) AS servicios_nombres
        FROM servicios
        WHERE estado_servicio = TRUE
        GROUP BY negocio_id
    ) AS ss ON ss.negocio_id = n.id
    LEFT JOIN (
        SELECT s.negocio_id, COUNT(r.id_reserva) AS reservas_count
        FROM servicios AS s
        INNER JOIN reservas AS r ON r.servicio_id = s.id_servicio
        WHERE r.estado IN ('pendiente', 'confirmada', 'completada')
        GROUP BY s.negocio_id
    ) AS pop ON pop.negocio_id = n.id
    WHERE n.estado_negocio = TRUE
"""

_DISTANCE_SELECT = """
        ,
        CASE
            WHEN {lat}::double precision IS NOT NULL
             AND {lng}::double precision IS NOT NULL
             AND d.latitud IS NOT NULL
             AND d.longitud IS NOT NULL
            THEN 6371 * 2 * asin(
                sqrt(
                    power(
                        sin(
                            radians(
                                d.latitud::double precision
                                - {lat}::double precision
                            ) / 2
                        ),
                        2
                    )
                    + cos(radians({lat}::double precision))
                      * cos(radians(d.latitud::double precision))
                      * power(
                            sin(
                                radians(
                                    d.longitud::double precision
                                    - {lng}::double precision
                                ) / 2
                            ),
                            2
                        )
                )
            )
        END AS distancia_km
"""

_ORDER_BY = {
    "relevancia": "nombre ASC",
    "nombre": "nombre ASC",
    "precio_asc": "precio_minimo ASC NULLS LAST, nombre ASC",
    "precio_desc": "precio_minimo DESC NULLS LAST, nombre ASC",
    "distancia": "distancia_km ASC NULLS LAST, nombre ASC",
    # HU_37 (filtrar/ordenar por valoración) está marcada como WON'T. Se deja
    # el criterio aceptado para cuando exista la tabla de reseñas.
    "valoracion": "valoracion DESC NULLS LAST, nombre ASC",
    "populares": "reservas_count DESC, nombre ASC",
}


def _build_shop_query(lat: Optional[float], lng: Optional[float]):
    """Devuelve el SELECT base y los parámetros de latitud/longitud."""

    params: list[object] = []
    distance_select = ""
    if lat is not None and lng is not None:
        params.extend([float(lat), float(lng)])
        distance_select = _DISTANCE_SELECT.format(lat="$1", lng="$2")
    return _SHOP_SELECT.format(distance_select=distance_select), params


async def search_shops_catalog(
    pool: asyncpg.Pool,
    *,
    q: Optional[str] = None,
    categoria_id: Optional[int] = None,
    categoria: Optional[str] = None,
    ciudad: Optional[str] = None,
    lat: Optional[float] = None,
    lng: Optional[float] = None,
    radio_km: Optional[float] = None,
    precio_min: Optional[float] = None,
    precio_max: Optional[float] = None,
    orden: str = "relevancia",
    limit: int = 50,
    offset: int = 0,
    negocio_id: Optional[int] = None,
):
    inner, params = _build_shop_query(lat, lng)
    filters: list[str] = []

    if negocio_id is not None:
        params.append(int(negocio_id))
        filters.append(f"id = ${len(params)}")

    if q:
        params.append(f"%{q}%")
        idx = len(params)
        filters.append(
            "("
            f"nombre ILIKE ${idx} "
            f"OR COALESCE(descripcion, '') ILIKE ${idx} "
            f"OR COALESCE(categoria_negocio, '') ILIKE ${idx} "
            "OR EXISTS ("
            "    SELECT 1 FROM servicios AS s2 "
            "    WHERE s2.negocio_id = shop_data.id "
            "      AND s2.estado_servicio = TRUE "
            f"      AND s2.nombre ILIKE ${idx}"
            ")"
            ")"
        )

    if categoria_id is not None:
        params.append(int(categoria_id))
        filters.append(f"id_categoria = ${len(params)}")

    if categoria:
        params.append(f"%{categoria}%")
        filters.append(f"COALESCE(categoria_negocio, '') ILIKE ${len(params)}")

    if ciudad:
        params.append(f"%{ciudad}%")
        filters.append(f"COALESCE(ciudad, '') ILIKE ${len(params)}")

    if precio_min is not None:
        params.append(float(precio_min))
        filters.append(f"precio_maximo >= ${len(params)}")

    if precio_max is not None:
        params.append(float(precio_max))
        filters.append(f"precio_minimo <= ${len(params)}")

    if radio_km is not None:
        params.append(float(radio_km))
        filters.append(f"distancia_km <= ${len(params)}")

    where_clause = ""
    if filters:
        where_clause = " WHERE " + " AND ".join(filters)

    order_clause = _ORDER_BY.get(orden, _ORDER_BY["relevancia"])

    params.append(int(limit))
    limit_idx = len(params)
    params.append(int(offset))
    offset_idx = len(params)

    query = (
        f"WITH shop_data AS ({inner})"
        f" SELECT * FROM shop_data{where_clause}"
        f" ORDER BY {order_clause}"
        f" LIMIT ${limit_idx} OFFSET ${offset_idx}"
    )

    async with pool.acquire() as conn:
        return await conn.fetch(query, *params)


# Consulta de todos los negocios
async def get_all_shops(pool: asyncpg.Pool):
    return await search_shops_catalog(pool)


# Búsqueda de negocio por nombre
async def search_shops_by_name(pool: asyncpg.Pool, search_term: str):
    return await search_shops_catalog(pool, q=search_term)


# Búsqueda de negocio por categoría
async def search_shops_by_category(pool: asyncpg.Pool, category: str):
    return await search_shops_catalog(pool, categoria=category)


# Búsqueda general (nombre, descripción, categoría o servicio)
async def search_shops(pool: asyncpg.Pool, search_term: str):
    return await search_shops_catalog(pool, q=search_term)


# Obtener un negocio por su ID
async def get_negocio_by_id(pool: asyncpg.Pool, negocio_id: int):
    shops = await search_shops_catalog(pool, negocio_id=negocio_id, limit=1)
    return shops[0] if shops else None


async def get_categories(pool: asyncpg.Pool):
    query = """
        SELECT
            c.id_categoria,
            c.nombre_categoria,
            COUNT(n.id) FILTER (WHERE n.estado_negocio = TRUE) AS negocios_count
        FROM categorias AS c
        LEFT JOIN negocios AS n ON n.fk_categoria = c.id_categoria
        GROUP BY c.id_categoria, c.nombre_categoria
        ORDER BY c.nombre_categoria
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query)

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