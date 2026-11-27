from fastapi import APIRouter, Depends, HTTPException, status
import asyncpg

from app.core.config import settings
from app.core.dependencies import get_current_user, get_db_pool, verify_api_key
from app.models.push import (
    PushPublicKeyOut,
    PushSubscriptionCreate,
    PushSubscriptionStatusOut,
    PushTestOut,
    PushUnsubscribeRequest,
)
from app.services import push_service

router = APIRouter(
    prefix="/push",
    tags=["push"],
    dependencies=[Depends(verify_api_key)],
)


def _ensure_configured() -> None:
    if not settings.push_configured or not push_service.is_available():
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            "Las notificaciones push no están configuradas en el servidor.",
        )


@router.get("/public-key", response_model=PushPublicKeyOut)
async def get_public_key():
    _ensure_configured()
    return PushPublicKeyOut(publicKey=push_service.public_key() or "")


@router.post("/subscribe", response_model=PushSubscriptionStatusOut)
async def subscribe(
    data: PushSubscriptionCreate,
    current_user: dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    _ensure_configured()
    await push_service.subscribe(pool, int(current_user["sub"]), data)
    count = await push_service.subscription_count(pool, int(current_user["sub"]))
    return PushSubscriptionStatusOut(subscribed=True, count=count)


@router.post("/unsubscribe", response_model=PushSubscriptionStatusOut)
async def unsubscribe(
    data: PushUnsubscribeRequest,
    current_user: dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    user_id = int(current_user["sub"])
    await push_service.unsubscribe(pool, user_id, data.endpoint)
    count = await push_service.subscription_count(pool, user_id)
    return PushSubscriptionStatusOut(subscribed=count > 0, count=count)


@router.get("/status", response_model=PushSubscriptionStatusOut)
async def get_status(
    current_user: dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    user_id = int(current_user["sub"])
    count = await push_service.subscription_count(pool, user_id)
    return PushSubscriptionStatusOut(subscribed=count > 0, count=count)


@router.post("/test", response_model=PushTestOut)
async def send_test(
    current_user: dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    _ensure_configured()
    sent = await push_service.send_test_notification(
        pool, int(current_user["sub"])
    )
    if sent == 0:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "No hay ninguna suscripción push activa en este dispositivo.",
        )
    return PushTestOut(sent=sent)
