import asyncpg

_CATEGORY_SELECT = """
    SELECT
        c.id_categoria,
        c.nombre_categoria,
        NULLIF(to_jsonb(c)->>'descripcion', '') AS descripcion,
        COALESCE((to_jsonb(c)->>'estado')::boolean, TRUE) AS estado,
        COUNT(n.id) FILTER (WHERE n.estado_negocio = TRUE)::int AS negocios_count
    FROM categorias AS c
    LEFT JOIN negocios AS n ON n.fk_categoria = c.id_categoria
"""


async def list_categories(pool: asyncpg.Pool, solo_activas: bool = True):
    query = _CATEGORY_SELECT
    if solo_activas:
        query += " WHERE COALESCE((to_jsonb(c)->>'estado')::boolean, TRUE) = TRUE"
    query += """
        GROUP BY c.id_categoria, c.nombre_categoria
        ORDER BY c.nombre_categoria, c.id_categoria
    """
    async with pool.acquire() as conn:
        return await conn.fetch(query)


async def get_category_by_id(pool: asyncpg.Pool, categoria_id: int):
    query = _CATEGORY_SELECT + """
        WHERE c.id_categoria = $1
        GROUP BY c.id_categoria, c.nombre_categoria
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, categoria_id)


async def get_category_by_name(pool: asyncpg.Pool, nombre: str, exclude_id: int | None = None):
    query = """
        SELECT id_categoria, nombre_categoria
        FROM categorias
        WHERE LOWER(TRIM(nombre_categoria)) = LOWER(TRIM($1))
    """
    params: list[object] = [nombre]
    if exclude_id is not None:
        params.append(exclude_id)
        query += " AND id_categoria <> $2"
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, *params)


async def create_category(
    pool: asyncpg.Pool, nombre: str, descripcion: str | None, estado: bool
):
    query = """
        INSERT INTO categorias (nombre_categoria, descripcion, estado)
        VALUES ($1, $2, $3)
        RETURNING id_categoria
    """
    async with pool.acquire() as conn:
        row = await conn.fetchrow(query, nombre.strip(), descripcion, estado)
    return await get_category_by_id(pool, int(row["id_categoria"]))


async def update_category(
    pool: asyncpg.Pool, categoria_id: int, fields: dict
):
    allowed = {"nombre_categoria", "descripcion", "estado"}
    sets: list[str] = []
    values: list[object] = []
    for key, value in fields.items():
        if key not in allowed:
            continue
        values.append(value.strip() if key == "nombre_categoria" and isinstance(value, str) else value)
        sets.append(f"{key} = ${len(values)}")
    if not sets:
        return await get_category_by_id(pool, categoria_id)

    values.append(categoria_id)
    query = f"""
        UPDATE categorias
        SET {', '.join(sets)}
        WHERE id_categoria = ${len(values)}
        RETURNING id_categoria
    """
    async with pool.acquire() as conn:
        row = await conn.fetchrow(query, *values)
    if row is None:
        return None
    return await get_category_by_id(pool, categoria_id)


async def delete_category(pool: asyncpg.Pool, categoria_id: int) -> None:
    query = "DELETE FROM categorias WHERE id_categoria = $1"
    async with pool.acquire() as conn:
        await conn.execute(query, categoria_id)


async def has_shops(pool: asyncpg.Pool, categoria_id: int) -> bool:
    query = "SELECT EXISTS(SELECT 1 FROM negocios WHERE fk_categoria = $1) AS existe"
    async with pool.acquire() as conn:
        row = await conn.fetchrow(query, categoria_id)
    return bool(row["existe"])
