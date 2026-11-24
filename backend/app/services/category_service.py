import asyncpg
from fastapi import HTTPException, status

from app.repositories import category_repository as repo


async def list_categories(pool: asyncpg.Pool, incluir_inactivas: bool = False):
    rows = await repo.list_categories(pool, solo_activas=not incluir_inactivas)
    return [dict(row) for row in rows]


async def get_category(pool: asyncpg.Pool, categoria_id: int):
    row = await repo.get_category_by_id(pool, categoria_id)
    if not row:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Categoría no encontrada.")
    return dict(row)


async def create_category(pool: asyncpg.Pool, data):
    existe = await repo.get_category_by_name(pool, data.nombre_categoria)
    if existe:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Ya existe una categoría con ese nombre.",
        )
    try:
        row = await repo.create_category(
            pool,
            data.nombre_categoria,
            data.descripcion,
            data.estado,
        )
    except asyncpg.exceptions.UniqueViolationError as exc:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Ya existe una categoría con ese nombre.",
        ) from exc
    return dict(row)


async def update_category(pool: asyncpg.Pool, categoria_id: int, data):
    await get_category(pool, categoria_id)
    fields = data.model_dump(exclude_unset=True)

    if "nombre_categoria" in fields:
        existe = await repo.get_category_by_name(
            pool, fields["nombre_categoria"], exclude_id=categoria_id
        )
        if existe:
            raise HTTPException(
                status.HTTP_409_CONFLICT,
                "Ya existe una categoría con ese nombre.",
            )

    try:
        row = await repo.update_category(pool, categoria_id, fields)
    except asyncpg.exceptions.UniqueViolationError as exc:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Ya existe una categoría con ese nombre.",
        ) from exc
    if not row:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Categoría no encontrada.")
    return dict(row)


async def delete_category(pool: asyncpg.Pool, categoria_id: int):
    categoria = await get_category(pool, categoria_id)

    if await repo.has_shops(pool, categoria_id):
        # No se puede borrar una categoría en uso sin romper la FK de negocios:
        # se desactiva y deja de mostrarse en el catálogo público.
        await repo.update_category(pool, categoria_id, {"estado": False})
        return {
            "message": (
                "La categoría tiene negocios asociados, por lo que se desactivó "
                "en lugar de eliminarse."
            ),
            "desactivada": True,
        }

    await repo.delete_category(pool, categoria_id)
    return {
        "message": "Categoría eliminada correctamente.",
        "desactivada": False,
        "categoria": dict(categoria),
    }
