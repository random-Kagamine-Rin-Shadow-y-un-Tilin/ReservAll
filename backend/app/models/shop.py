from pydantic import BaseModel
from typing import Optional
from datetime import time

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
    
class ShopContactOut(BaseModel):
    nombre_red: str
    url: str
    
class ShopScheduleOut(BaseModel):
    id_horario: int
    dia: str
    hora_apertura: time
    hora_cierre : time
    
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