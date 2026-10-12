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
    hora_cierre : time
