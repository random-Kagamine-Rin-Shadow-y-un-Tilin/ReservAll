from pydantic import BaseModel
from typing import Optional

# Una sola definición de horario para todos los contratos de negocio.
# Antes había dos `ShopScheduleOut` distintos (uno aquí y otro en
# `shop_schedule.py`), lo que generaba respuestas inconsistentes.
from app.models.shop_schedule import ShopScheduleOut  # noqa: F401


class ShopRegister(BaseModel):
    nombre: str
    descripcion: str
    imagen_negocio: Optional[str] = 'null'
    categoria_negocio: int

class ShopEdit(BaseModel):
    nombre: str
    descripcion: str
    imagen_negocio: Optional[str] = 'null'
    fk_categoria: int

class ShopOut(BaseModel):
    id: int
    nombre: str
    descripcion: str
    imagen_negocio: str
    categoria_negocio: str | int
    id_categoria: int
    # HU_12: el propietario necesita conocer el estado real devuelto por
    # `negocios_view`. El default mantiene compatibilidad con vistas antiguas.
    estado_negocio: bool = True

class ShopContactOut(BaseModel):
    nombre_red: str
    url: str

class ShopAddressOut(BaseModel):
    id_direccion: int
    direccion_calle: str
    ciudad: str
    estado: str
    codigo_postal: str
    pais: str
    latitud: float
    longitud: float
    osm_id: str
    numero_local: str
    numero_interior: str | None

class ShopFullProfileOut(BaseModel):
    general: ShopOut
    contacto: list[ShopContactOut] = []
    horario: list[ShopScheduleOut] = []
    direccion: ShopAddressOut | None = None

class ShopStatusUpdate(BaseModel):
    estado_negocio: bool
