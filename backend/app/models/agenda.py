from datetime import date, datetime, time
from typing import List, Optional

from pydantic import BaseModel, Field, model_validator

from app.models.owner import OwnerReservationOut
from app.models.shop_schedule import ShopScheduleOut


class BlockCreate(BaseModel):
    """Bloqueo de agenda.

    - Sin ``hora_inicio`` ni ``hora_fin`` bloquea el día completo (HU_22).
    - Con ambas horas bloquea únicamente ese rango (HU_24).
    """

    fecha: date
    hora_inicio: Optional[time] = None
    hora_fin: Optional[time] = None
    motivo: Optional[str] = Field(default=None, max_length=255)

    @model_validator(mode="after")
    def _validate_times(self):
        if (self.hora_inicio is None) != (self.hora_fin is None):
            raise ValueError(
                "Debes indicar hora_inicio y hora_fin, o ninguna de las dos "
                "para bloquear el día completo."
            )
        if (
            self.hora_inicio is not None
            and self.hora_fin is not None
            and self.hora_inicio >= self.hora_fin
        ):
            raise ValueError(
                "La hora de inicio del bloqueo debe ser menor que la hora de fin."
            )
        return self


class BlockOut(BaseModel):
    id_bloqueo: int
    negocio_id: int
    fecha: date
    hora_inicio: Optional[time] = None
    hora_fin: Optional[time] = None
    motivo: Optional[str] = None
    fecha_creacion: Optional[datetime] = None


class BlockListOut(BaseModel):
    items: List[BlockOut]
    total: int


class AgendaSlotOut(BaseModel):
    hora_inicio: time
    hora_fin: time
    disponible: bool
    motivo: Optional[str] = None


class AgendaDayOut(BaseModel):
    fecha: date
    dia_semana: str
    abierto: bool
    bloqueado: bool
    horario: Optional[ShopScheduleOut] = None
    reservas: List[OwnerReservationOut] = Field(default_factory=list)
    bloqueos: List[BlockOut] = Field(default_factory=list)
    disponibilidad: List[AgendaSlotOut] = Field(default_factory=list)


class AgendaSummaryOut(BaseModel):
    total_reservas: int = 0
    pendientes: int = 0
    confirmadas: int = 0
    completadas: int = 0
    canceladas: int = 0
    dias_abiertos: int = 0
    dias_bloqueados: int = 0
    dias_cerrados: int = 0


class AgendaRangeOut(BaseModel):
    desde: date
    hasta: date
    dias: int


class OwnerAgendaOut(BaseModel):
    negocio_id: int
    rango: AgendaRangeOut
    horarios: List[ShopScheduleOut]
    dias: List[AgendaDayOut]
    resumen: AgendaSummaryOut
