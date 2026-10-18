from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from .profesional import ProfessionalOut

class ServiceRegister(BaseModel):
    nombre: str
    descripcion: Optional[str] = None
    duracion_minutos: int = 60
    precio: float = 0
    categoria_servicio: Optional[str] = 'servicio'
    cantidad_servicio: Optional[int] = 1
    estado_servicio: Optional[bool] = True
    profesional_ids: Optional[List[int]] = []

class ServiceEdit(BaseModel):
    nombre: Optional[str] = None
    descripcion: Optional[str] = None
    duracion_minutos: Optional[int] = None
    precio: Optional[float] = None
    categoria_servicio: Optional[str] = None
    cantidad_servicio: Optional[int] = None
    estado_servicio: Optional[bool] = None
    profesional_ids: Optional[List[int]] = None

class ServiceOut(BaseModel):
    id_servicio: int
    negocio_id: int
    nombre: str
    descripcion: Optional[str] = None
    duracion_minutos: int
    precio: float
    categoria_servicio: Optional[str] = None
    cantidad_servicio: int
    estado_servicio: bool
    fecha_creacion: Optional[datetime] = None
    profesionales: Optional[List[ProfessionalOut]] = []