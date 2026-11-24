import asyncio
from datetime import date, time

import pytest
from fastapi import HTTPException
from pydantic import ValidationError

from app.core.schedule_utils import normalize_day
from app.models.client import CategoryUpdate
from app.models.shop import ShopOut, ShopRegister
from app.models.shop_schedule import ShopRegisterSchedule
from app.models.user import PasswordResetConfirm, ProfileUpdate, UserRegister
from app.services import client_service, owner_service, password_service, shop_service


def test_registro_publico_no_acepta_admin():
    with pytest.raises(ValidationError):
        UserRegister(
            nombre="Admin",
            correo="admin@example.com",
            password="ClaveSegura123",
            confirm_password="ClaveSegura123",
            rol="admin",
        )


def test_perfil_obliga_a_validar_cambios_sensibles():
    with pytest.raises(ValidationError):
        ProfileUpdate(correo="nuevo@reservall.local", password_actual=None)

    with pytest.raises(ValidationError):
        ProfileUpdate(password_nueva="ClaveSegura123", confirm_password="OtraClave123")

    perfil = ProfileUpdate(nombre="Nombre Nuevo")
    assert perfil.nombre == "Nombre Nuevo"


def test_reset_registra_intentos_fallidos(monkeypatch):
    visto = {}

    async def fake_user(pool, correo):
        return {"id": 1}

    async def fake_get_valid(pool, user_id, code_hash, max_intentos):
        return None

    async def fake_register(pool, user_id, code_hash, max_intentos):
        visto["intentos"] = max_intentos

    monkeypatch.setattr(password_service.user_repo, "get_user_by_email", fake_user)
    monkeypatch.setattr(password_service.reset_repo, "get_valid_code", fake_get_valid)
    monkeypatch.setattr(
        password_service.reset_repo, "register_failed_attempt", fake_register
    )

    with pytest.raises(HTTPException) as exc:
        asyncio.run(
            password_service.confirm_password_reset(
                None, "cliente@example.com", "123456", "ClaveSegura123"
            )
        )

    assert exc.value.status_code == 400
    assert visto["intentos"] == password_service.MAX_RESET_ATTEMPTS


def test_categoria_permite_limpiar_descripcion():
    with pytest.raises(ValidationError):
        CategoryUpdate()

    update = CategoryUpdate(descripcion=None)
    assert "descripcion" in update.model_fields_set


def test_codigo_de_reseteo_es_de_seis_digitos():
    valido = PasswordResetConfirm(
        correo="cliente@example.com",
        codigo=" 123456 ",
        nueva_password="ClaveSegura123",
        confirm_password="ClaveSegura123",
    )
    assert valido.codigo == "123456"

    with pytest.raises(ValidationError):
        PasswordResetConfirm(
            correo="cliente@example.com",
            codigo="abc123",
            nueva_password="ClaveSegura123",
            confirm_password="ClaveSegura123",
        )


def test_dias_se_normalizan_a_enum_de_base_de_datos():
    assert normalize_day("Miércoles") == "miercoles"
    assert normalize_day("SABADO") == "sabado"


def test_horario_acepta_turnos_partidos_pero_rechaza_solapes():
    existente = {
        "hora_apertura": time(9, 0),
        "hora_cierre": time(13, 0),
        "estado_horario": True,
    }

    shop_service._validate_no_overlap(
        {"hora_apertura": time(13, 0), "hora_cierre": time(18, 0)},
        [existente],
    )

    with pytest.raises(HTTPException) as exc:
        shop_service._validate_no_overlap(
            {"hora_apertura": time(12, 30), "hora_cierre": time(18, 0)},
            [existente],
        )
    assert exc.value.status_code == 409


def test_descanso_no_puede_terminar_despues_del_cierre():
    with pytest.raises(HTTPException) as exc:
        shop_service._validate_schedule_hours(
            time(9, 0), time(13, 30), time(13, 0), 60
        )
    assert exc.value.status_code == 400

    shop_service._validate_schedule_hours(time(9, 0), time(18, 0), time(13, 0), 60)


def test_horario_expone_duracion_del_descanso():
    horario = ShopRegisterSchedule(
        dia="Lunes",
        hora_apertura=time(9, 0),
        hora_cierre=time(18, 0),
        hora_descanso=time(13, 0),
        descanso_duracion_min=45,
    )
    assert horario.descanso_duracion_min == 45


def test_negocio_no_puede_usar_categoria_desactivada(monkeypatch):
    async def categoria_desactivada(pool, categoria_id):
        return {"id_categoria": categoria_id, "estado": False}

    monkeypatch.setattr(
        shop_service.category_repo, "get_category_by_id", categoria_desactivada
    )

    datos = ShopRegister(
        nombre="Negocio",
        descripcion="Descripción",
        categoria_negocio=1,
    )
    with pytest.raises(HTTPException) as exc:
        asyncio.run(shop_service.register_shop(None, datos, 1, "negocio"))
    assert exc.value.status_code == 400


def test_shop_out_incluye_estado_del_negocio():
    negocio = ShopOut(
        id=1,
        nombre="Negocio",
        descripcion="Descripción",
        imagen_negocio="null",
        categoria_negocio="Belleza",
        id_categoria=1,
        estado_negocio=False,
    )
    assert negocio.estado_negocio is False


def test_paginacion_catalogo_cuenta_solo_disponibles(monkeypatch):
    candidatos = [
        {"id": i, "nombre": f"Negocio {i}", "disponible": True}
        for i in range(1, 4)
    ]

    async def fake_search(pool, **filtros):
        assert filtros["limit"] is None
        assert filtros["offset"] == 0
        return candidatos

    async def fake_count(*args, **kwargs):
        raise AssertionError("Con fecha se cuenta después del filtro de disponibilidad")

    monkeypatch.setattr(client_service, "search_catalog", fake_search)
    monkeypatch.setattr(client_service.repo, "count_shops_catalog", fake_count)

    resultado = asyncio.run(
        client_service.search_catalog_page(
            None, fecha=date(2026, 1, 15), limit=2, offset=2
        )
    )

    assert resultado.total == 3
    assert resultado.pages == 2
    assert [item.id for item in resultado.items] == [3]


def test_paginacion_calcula_total_y_paginas(monkeypatch):
    reserva = {
        "id_reserva": 1,
        "cliente_id": 2,
        "cliente_nombre": "Cliente",
        "cliente_correo": "cliente@example.com",
        "servicio_id": 3,
        "servicio_nombre": "Corte",
        "duracion_minutos": 30,
        "precio": 20.0,
        "fecha": date(2026, 1, 15),
        "hora_inicio": time(10, 0),
        "estado": "confirmada",
    }

    async def sin_permisos(*args, **kwargs):
        return None

    async def get_reservations(pool, shop_id, **kwargs):
        cantidad = 2 if "limit" in kwargs else 3
        return [dict(reserva) for _ in range(cantidad)]

    async def count_reservations(pool, shop_id, **kwargs):
        return 3

    monkeypatch.setattr(owner_service, "_ensure_shop", sin_permisos)
    monkeypatch.setattr(owner_service.repo, "get_reservations", get_reservations)
    monkeypatch.setattr(owner_service.repo, "count_reservations", count_reservations)

    resultado = asyncio.run(
        owner_service.list_reservations(None, 1, 1, limit=2, offset=1)
    )
    assert len(resultado.items) == 2
    assert resultado.page.total == 3
    assert resultado.page.pages == 2
    assert resultado.summary.total == 3
