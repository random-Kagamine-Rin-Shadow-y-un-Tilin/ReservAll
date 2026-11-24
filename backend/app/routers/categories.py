import asyncpg
from fastapi import APIRouter, Depends, Query

from app.core.dependencies import get_current_admin, get_db_pool
from app.models.client import CategoryCreate, CategoryUpdate, CategoryView
from app.services import category_service

router = APIRouter(
    prefix="/categories",
    tags=["categorias"],
    dependencies=[Depends(get_current_admin)],
)


@router.get("", response_model=list[CategoryView])
async def list_categories(
    incluir_inactivas: bool = Query(
        False, description="Incluye categorías desactivadas (solo administración)"
    ),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    return await category_service.list_categories(pool, incluir_inactivas)


@router.get("/{categoria_id}", response_model=CategoryView)
async def get_category(
    categoria_id: int,
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    return await category_service.get_category(pool, categoria_id)


@router.post("", response_model=CategoryView, status_code=201)
async def create_category(
    data: CategoryCreate,
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    return await category_service.create_category(pool, data)


@router.put("/{categoria_id}", response_model=CategoryView)
async def update_category(
    categoria_id: int,
    data: CategoryUpdate,
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    return await category_service.update_category(pool, categoria_id, data)


@router.delete("/{categoria_id}")
async def delete_category(
    categoria_id: int,
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    return await category_service.delete_category(pool, categoria_id)
