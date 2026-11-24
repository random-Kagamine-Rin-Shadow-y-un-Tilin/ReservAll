import asyncpg

async def get_user_by_email(pool: asyncpg.Pool, email: str) -> asyncpg.Record | None:
    query = "SELECT id, nombre, correo, password_hash, rol FROM usuarios WHERE correo = $1"
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, email)

async def get_user_by_id(pool: asyncpg.Pool, user_id: int) -> asyncpg.Record | None:
    query = "SELECT id, nombre, correo, rol FROM usuarios WHERE id = $1"
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, user_id)

async def get_password_hash_by_id(pool: asyncpg.Pool, user_id: int) -> str | None:
    query = "SELECT password_hash FROM usuarios WHERE id = $1"
    async with pool.acquire() as conn:
        row = await conn.fetchrow(query, user_id)
    return row["password_hash"] if row else None

async def create_user(
    pool: asyncpg.Pool, name: str, email: str, password_hash: str, rol:str = "cliente"
) -> asyncpg.Record:
    query = """
        INSERT INTO usuarios (nombre, correo, password_hash, rol, fecha_registro)
        VALUES ($1, $2, $3, $4, now())
        RETURNING id, nombre, correo, rol
  """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, name, email, password_hash, rol)


async def update_user(
    pool: asyncpg.Pool,
    user_id: int,
    fields: dict,
) -> asyncpg.Record | None:
    """Actualiza solo las columnas permitidas del perfil."""

    allowed = {"nombre", "correo", "password_hash"}
    sets: list[str] = []
    values: list[object] = []
    for key, value in fields.items():
        if key not in allowed:
            continue
        values.append(value)
        sets.append(f"{key} = ${len(values)}")
    if not sets:
        return await get_user_by_id(pool, user_id)

    values.append(user_id)
    query = f"""
        UPDATE usuarios
        SET {', '.join(sets)}
        WHERE id = ${len(values)}
        RETURNING id, nombre, correo, rol
    """
    async with pool.acquire() as conn:
        return await conn.fetchrow(query, *values)


async def email_exists_for_other_user(
    pool: asyncpg.Pool, email: str, user_id: int
) -> bool:
    query = "SELECT EXISTS(SELECT 1 FROM usuarios WHERE correo = $1 AND id <> $2) AS existe"
    async with pool.acquire() as conn:
        row = await conn.fetchrow(query, email, user_id)
    return bool(row["existe"])
