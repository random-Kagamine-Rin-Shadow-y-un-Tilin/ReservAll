import asyncio
import json
import logging
from datetime import datetime, timedelta
from typing import Optional

import asyncpg

from app.core.config import settings
from app.core.database import get_pool
from app.repositories import push_repository as repo

logger = logging.getLogger(__name__)

try:
    from pywebpush import WebPushException, webpush
except ImportError:  # pragma: no cover - se avisa al arrancar
    WebPushException = None  # type: ignore[assignment]
    webpush = None  # type: ignore[assignment]

_missing_schema_logged = False


def is_available() -> bool:
    return webpush is not None and settings.push_configured


def public_key() -> Optional[str]:
    return settings.vapid_public_key


def _send_sync(subscription, payload: dict) -> str:
    """Envía una notificación Web Push. Devuelve sent/gone/failed."""

    if webpush is None:
        return "failed"

    try:
        webpush(
            subscription_info={
                "endpoint": subscription["endpoint"],
                "keys": {
                    "p256dh": subscription["p256dh"],
                    "auth": subscription["auth"],
                },
            },
            data=json.dumps(payload, ensure_ascii=False),
            vapid_private_key=settings.vapid_private_key,
            vapid_claims={"sub": settings.vapid_subject},
            timeout=15,
        )
        return "sent"
    except WebPushException as exc:  # type: ignore[misc]
        status = getattr(getattr(exc, "response", None), "status_code", None)
        if status in (404, 410):
            return "gone"
        logger.warning("No se pudo enviar la notificación push: %s", exc)
        return "failed"
    except Exception as exc:  # pragma: no cover - errores de red inesperados
        logger.warning("Error inesperado enviando notificación push: %s", exc)
        return "failed"


async def subscribe(pool: asyncpg.Pool, user_id: int, data) -> dict:
    row = await repo.upsert_subscription(
        pool,
        user_id,
        data.endpoint,
        data.keys.p256dh,
        data.keys.auth,
        data.user_agent,
    )
    return {"id": row["id"], "endpoint": row["endpoint"]}


async def unsubscribe(pool: asyncpg.Pool, user_id: int, endpoint: str) -> bool:
    return await repo.delete_subscription(pool, user_id, endpoint)


async def subscription_count(pool: asyncpg.Pool, user_id: int) -> int:
    return await repo.count_subscriptions(pool, user_id)


async def send_to_user(pool: asyncpg.Pool, user_id: int, payload: dict) -> int:
    subscriptions = await repo.list_user_subscriptions(pool, user_id)
    if not subscriptions:
        return 0

    sent = 0
    for subscription in subscriptions:
        result = await asyncio.to_thread(_send_sync, subscription, payload)
        if result == "sent":
            sent += 1
        elif result == "gone":
            await repo.delete_subscription_by_endpoint(
                pool, subscription["endpoint"]
            )

    return sent


def _reservation_payload(row, now: datetime) -> dict:
    start = datetime.combine(row["fecha"], row["hora_inicio"])
    minutes = round((start - now).total_seconds() / 60)
    hora = row["hora_inicio"].strftime("%H:%M")

    if settings.push_lead_minutes > 0 and minutes > 0:
        title = f"Reserva en {minutes} min"
    else:
        title = "Tu reserva empieza ahora"

    body = (
        f"{row['cliente_nombre']} · {row['servicio_nombre']} · {hora} · "
        f"{row['negocio_nombre']}"
    )

    return {
        "title": title,
        "body": body,
        "url": "/agenda",
        "tag": f"reservall-reserva-{row['id_reserva']}",
        "icon": "/icons/icon-192.png",
        "badge": "/icons/icon-192.png",
    }


async def notify_due_reservations(
    pool: asyncpg.Pool,
    now: Optional[datetime] = None,
) -> int:
    if not is_available():
        return 0

    now = now or datetime.now()
    window_start = now - timedelta(minutes=2)
    window_end = now + timedelta(minutes=max(0, settings.push_lead_minutes))

    reservations = await repo.get_due_reservations(pool, window_start, window_end)
    total_sent = 0

    for reservation in reservations:
        owner_id = int(reservation["dueno_id"])
        if await repo.count_subscriptions(pool, owner_id) == 0:
            continue

        # La clave incluye fecha y hora: si la reserva se reprograma, se vuelve
        # a avisar en el nuevo horario.
        kind = (
            f"reserva:{reservation['fecha'].isoformat()}:"
            f"{reservation['hora_inicio'].strftime('%H:%M')}"
        )
        claimed = await repo.claim_notification(
            pool, int(reservation["id_reserva"]), kind
        )
        if not claimed:
            continue

        payload = _reservation_payload(reservation, now)
        sent = await send_to_user(pool, owner_id, payload)

        if sent == 0:
            # Permite reintentar en la siguiente revisión si fue un fallo temporal.
            await repo.release_notification(
                pool, int(reservation["id_reserva"]), kind
            )
        else:
            total_sent += sent

    return total_sent


async def send_test_notification(pool: asyncpg.Pool, user_id: int) -> int:
    return await send_to_user(
        pool,
        user_id,
        {
            "title": "Notificaciones activadas",
            "body": "Recibirás un aviso cuando empiece una reserva.",
            "url": "/agenda",
            "tag": "reservall-prueba",
            "icon": "/icons/icon-192.png",
            "badge": "/icons/icon-192.png",
        },
    )


async def scheduler_loop() -> None:
    global _missing_schema_logged

    if not is_available():
        logger.info(
            "Planificador push desactivado: falta pywebpush o las claves VAPID."
        )
        return

    logger.info(
        "Planificador push iniciado (cada %ss, aviso con %s min de antelación).",
        settings.push_check_interval_seconds,
        settings.push_lead_minutes,
    )

    while True:
        try:
            await notify_due_reservations(get_pool())
            _missing_schema_logged = False
        except asyncpg.UndefinedTableError:
            if not _missing_schema_logged:
                logger.warning(
                    "Faltan las tablas de notificaciones push. Aplica "
                    "migrations/007_push_notifications.sql."
                )
                _missing_schema_logged = True
        except asyncio.CancelledError:
            raise
        except Exception as exc:  # pragma: no cover - se reintenta siempre
            logger.warning("Error revisando reservas para push: %s", exc)

        await asyncio.sleep(max(5, settings.push_check_interval_seconds))
