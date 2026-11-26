import asyncpg
from fastapi import HTTPException, status

from app.core.security import hash_password, verify_password
from app.models.user import ProfileUpdate
from app.repositories import refresh_token_repository as refresh_repo
from app.repositories import user_repository as user_repo


async def update_profile(
    pool: asyncpg.Pool, user_id: int, data: ProfileUpdate
):
    """HU_05: actualiza únicamente el perfil del usuario autenticado."""

    current = await user_repo.get_user_by_id(pool, user_id)
    if not current:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Usuario no encontrado.")

    cambios: dict = {}

    if data.nombre is not None and data.nombre != current["nombre"]:
        cambios["nombre"] = data.nombre

    if data.correo is not None and data.correo != current["correo"]:
        if await user_repo.email_exists_for_other_user(pool, data.correo, user_id):
            raise HTTPException(
                status.HTTP_409_CONFLICT,
                "Ese correo ya está asociado a otra cuenta.",
            )
        cambios["correo"] = data.correo

    if data.password_nueva is not None:
        cambios["password_hash"] = hash_password(data.password_nueva)

    if data.correo is not None or data.password_nueva is not None:
        hash_actual = await user_repo.get_password_hash_by_id(pool, user_id)
        if not hash_actual or not verify_password(data.password_actual or "", hash_actual):
            raise HTTPException(
                status.HTTP_403_FORBIDDEN,
                "La contraseña actual no es correcta.",
            )

    if not cambios:
        return dict(current)

    updated = await user_repo.update_user(pool, user_id, cambios)
    if "password_hash" in cambios:
        # Las sesiones renovables anteriores dejan de ser válidas.
        await refresh_repo.revoke_all_user_tokens(pool, user_id)
    return dict(updated)
