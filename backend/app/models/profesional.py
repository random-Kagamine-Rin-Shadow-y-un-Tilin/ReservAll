from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class ProfessionalRegister(BaseModel):
    nombre: str
    especialidad: Optional[str] = None

class ProfessionalEdit(BaseModel):
    nombre: Optional[str] = None
    especialidad: Optional[str] = None
    activo: Optional[bool] = None

class ProfessionalOut(BaseModel):
    id_profesional: int
    negocio_id: int
    nombre: str
    especialidad: Optional[str] = None
    activo: bool
    fecha_creacion: Optional[datetime] = None