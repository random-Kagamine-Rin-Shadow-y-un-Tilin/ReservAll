from pydantic import BaseModel, field_validator
from typing import Optional
from datetime import time

from app.core.schedule_utils import normalize_day


class ShopRegisterSchedule(BaseModel):
    dia: str
    hora_apertura: time
    hora_cierre: time
    hora_descanso: Optional[time] = None

    @field_validator("dia")
    @classmethod
    def _validar_dia(cls, value: str) -> str:
        return normalize_day(value)


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
