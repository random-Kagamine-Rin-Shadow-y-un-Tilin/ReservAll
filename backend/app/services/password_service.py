import asyncio
import secrets
import smtplib
from email.message import EmailMessage

import asyncpg
from fastapi import HTTPException, status

from app.core.config import settings
from app.core.security import hash_password, hash_refresh_token
from app.models.user import PasswordResetRequestOut
from app.repositories import password_reset_repository as reset_repo
from app.repositories import user_repository as user_repo

MAX_RESET_ATTEMPTS = 5


def _smtp_configured() -> bool:
    return bool(settings.smtp_host and settings.smtp_from)


def _build_message(correo: str, codigo: str) -> EmailMessage:
    msg = EmailMessage()
    msg["Subject"] = "ReservAll - Código para recuperar tu contraseña"
    msg["From"] = settings.smtp_from
    msg["To"] = correo
    msg.set_content(
        "Hemos recibido una solicitud para recuperar tu contraseña.\n\n"
        f"Tu código de verificación es: {codigo}\n\n"
        f"Válido durante {settings.password_reset_code_ttl_minutes} minutos.\n"
        "Si no fuiste tú, ignora este mensaje.\n"
    )
    return msg


def _send_email_sync(correo: str, codigo: str) -> None:
    msg = _build_message(correo, codigo)
    with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=10) as smtp:
        if settings.smtp_use_tls:
            smtp.starttls()
        if settings.smtp_user and settings.smtp_password:
            smtp.login(settings.smtp_user, settings.smtp_password)
        smtp.send_message(msg)


async def request_password_reset(
    pool: asyncpg.Pool, correo: str
) -> PasswordResetRequestOut:
    """HU_03, paso 1: verificar el correo y emitir un código de 6 dígitos.

    La respuesta es genérica para no revelar qué correos están registrados.
    El código se devuelve solo cuando `PASSWORD_RESET_RETURN_CODE=true`
    (desarrollo), nunca en producción.
    """

    # La comprobación va antes de buscar al usuario: si solo se hiciera para
    # correos registrados, el 503 revelaría qué cuentas existen.
    if not settings.password_reset_return_code and not _smtp_configured():
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            "La recuperación de contraseña no está configurada en este entorno.",
        )

    user = await user_repo.get_user_by_email(pool, correo)
    mensaje = "Si el correo está registrado, se ha enviado un código de verificación."

    if not user:
        return PasswordResetRequestOut(
            mensaje=mensaje,
            expira_en_minutos=settings.password_reset_code_ttl_minutes,
        )

    codigo = f"{secrets.randbelow(1_000_000):06d}"
    await reset_repo.invalidate_previous_codes(pool, int(user["id"]))
    await reset_repo.create_code(
        pool,
        int(user["id"]),
        hash_refresh_token(codigo),
        settings.password_reset_code_ttl_minutes,
    )

    if not settings.password_reset_return_code:
        try:
            await asyncio.to_thread(_send_email_sync, correo, codigo)
        except Exception as exc:  # pragma: no cover - depende del proveedor SMTP
            raise HTTPException(
                status.HTTP_502_BAD_GATEWAY,
                "No se pudo enviar el código de verificación.",
            ) from exc

    return PasswordResetRequestOut(
        mensaje=mensaje,
        expira_en_minutos=settings.password_reset_code_ttl_minutes,
        codigo=codigo if settings.password_reset_return_code else None,
    )


async def confirm_password_reset(
    pool: asyncpg.Pool,
    correo: str,
    codigo: str,
    nueva_password: str,
):
    """HU_03, paso 2: validar el código y guardar la nueva contraseña."""

    user = await user_repo.get_user_by_email(pool, correo)
    if not user:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "El código no es válido o ha expirado.",
        )

    code_hash = hash_refresh_token(codigo)
    row = await reset_repo.get_valid_code(
        pool, int(user["id"]), code_hash, MAX_RESET_ATTEMPTS
    )
    if not row:
        await reset_repo.register_failed_attempt(
            pool, int(user["id"]), code_hash, MAX_RESET_ATTEMPTS
        )
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "El código no es válido o ha expirado.",
        )

    try:
        updated = await reset_repo.consume_code_and_change_password(
            pool,
            int(row["id"]),
            int(user["id"]),
            hash_password(nueva_password),
        )
    except reset_repo.CodeNotConsumable as exc:
        # Otra petición consumió el código entre la lectura y la escritura.
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "El código no es válido o ha expirado.",
        ) from exc
    return dict(updated)
