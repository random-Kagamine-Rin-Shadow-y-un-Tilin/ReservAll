from pydantic import BaseModel
from datetime import time

class ShopRegisterSchedule(BaseModel):
    dia: str
    hora_apertura: time
    hora_cierre: time
    
class ShopScheduleOut(BaseModel):
    id_horario: int
    dia: str
    hora_apertura: time
    hora_cierre: time
    hora_descanso: time | None = None
    estado_horario: bool | None = True

class ShopScheduleUpdate(BaseModel):
    hora_apertura: time | None = None
    hora_cierre: time | None = None
    hora_descanso: time | None = None
    estado_horario: bool | None = None