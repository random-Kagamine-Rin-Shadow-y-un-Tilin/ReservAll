from app.core.dependencies import get_current_user
from app.models.user import PasswordResetRequestOut
from app.services import category_service, password_service, profile_service


def test_patch_perfil_toma_el_id_del_token(client, monkeypatch):
    visto = {}

    async def fake_update(pool, user_id, data):
        visto["user_id"] = user_id
        visto["nombre"] = data.nombre
        return {
            "id": user_id,
            "nombre": data.nombre,
            "correo": "negocio@reservall.local",
            "rol": "negocio",
        }

    monkeypatch.setattr(profile_service, "update_profile", fake_update)
    client.app.dependency_overrides[get_current_user] = lambda: {
        "sub": "42",
        "rol": "negocio",
    }

    response = client.patch(
        "/api/v1/profile/me", json={"nombre": "Negocio Actualizado"}
    )

    assert response.status_code == 200
    assert response.json()["id"] == 42
    assert visto == {"user_id": 42, "nombre": "Negocio Actualizado"}


def test_patch_perfil_rechaza_peticion_sin_cambios(client):
    client.app.dependency_overrides[get_current_user] = lambda: {
        "sub": "42",
        "rol": "negocio",
    }
    response = client.patch("/api/v1/profile/me", json={})
    assert response.status_code == 422


def test_recuperacion_de_password_expone_los_dos_pasos(client, monkeypatch):
    visto = {}

    async def fake_request(pool, correo):
        visto["correo_solicitud"] = correo
        return PasswordResetRequestOut(
            mensaje="Si el correo está registrado, se ha enviado un código.",
            expira_en_minutos=15,
        )

    async def fake_confirm(pool, correo, codigo, nueva_password):
        visto.update(
            correo_confirmacion=correo,
            codigo=codigo,
            nueva_password=nueva_password,
        )
        return {
            "id": 7,
            "nombre": "Cliente",
            "correo": correo,
            "rol": "cliente",
        }

    monkeypatch.setattr(password_service, "request_password_reset", fake_request)
    monkeypatch.setattr(password_service, "confirm_password_reset", fake_confirm)

    solicitud = client.post(
        "/api/v1/auth/forgot-password", json={"correo": "cliente@example.com"}
    )
    assert solicitud.status_code == 200
    assert solicitud.json()["expira_en_minutos"] == 15

    confirmacion = client.post(
        "/api/v1/auth/reset-password",
        json={
            "correo": "cliente@example.com",
            "codigo": "123456",
            "nueva_password": "ClaveSegura123",
            "confirm_password": "ClaveSegura123",
        },
    )
    assert confirmacion.status_code == 200
    assert visto["correo_solicitud"] == "cliente@example.com"
    assert visto["correo_confirmacion"] == "cliente@example.com"
    assert visto["codigo"] == "123456"
    assert visto["nueva_password"] == "ClaveSegura123"


def test_categorias_requieren_admin(client):
    client.app.dependency_overrides[get_current_user] = lambda: {
        "sub": "1",
        "rol": "negocio",
    }
    response = client.get("/api/v1/categories")
    assert response.status_code == 403


def test_admin_puede_crear_categoria(client, monkeypatch):
    async def fake_create(pool, data):
        return {
            "id_categoria": 10,
            "nombre_categoria": data.nombre_categoria,
            "descripcion": data.descripcion,
            "estado": data.estado,
            "negocios_count": 0,
        }

    monkeypatch.setattr(category_service, "create_category", fake_create)
    client.app.dependency_overrides[get_current_user] = lambda: {
        "sub": "1",
        "rol": "admin",
    }

    response = client.post(
        "/api/v1/categories",
        json={"nombre_categoria": "Belleza", "descripcion": "Salones y spa"},
    )

    assert response.status_code == 201
    assert response.json()["nombre_categoria"] == "Belleza"
    assert response.json()["negocios_count"] == 0


def test_openapi_incluye_los_nuevos_contratos(client):
    schema = client.get("/openapi.json").json()
    paths = schema["paths"]

    assert "/api/v1/auth/forgot-password" in paths
    assert "/api/v1/auth/reset-password" in paths
    assert "/api/v1/categories" in paths
    assert "/api/v1/client/shops/page" in paths
    assert "patch" in paths["/api/v1/profile/me"]
