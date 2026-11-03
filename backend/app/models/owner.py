from pydantic import BaseModel
from typing import Optional, List
from datetime import date, time, datetime

from app.models.client import EstadoReserva


class ReservationStatusUpdate(BaseModel):
    estado: EstadoReserva


class OwnerReservationOut(BaseModel):
    id_reserva: int
    cliente_id: int
    cliente_nombre: str
    cliente_correo: str
    servicio_id: int
    servicio_nombre: str
    duracion_minutos: int
    precio: float
    profesional_id: Optional[int] = None
    profesional_nombre: Optional[str] = None
    fecha: date
    hora_inicio: time
    hora_fin: Optional[time] = None
    estado: EstadoReserva
    fecha_creacion: Optional[datetime] = None


class ReservationSummary(BaseModel):
    total: int = 0
    pendientes: int = 0
    confirmadas: int = 0
    completadas: int = 0
    canceladas: int = 0
    ingresos: float = 0


class ReservationListOut(BaseModel):
    items: List[OwnerReservationOut]
    summary: ReservationSummary


class OwnerClientOut(BaseModel):
    cliente_id: int
    nombre: str
    correo: str
    total_reservas: int
    completadas: int
    canceladas: int
    activas: int
    primera_reserva: Optional[date] = None
    ultima_reserva: Optional[date] = None
    total_gastado: float
    servicio_favorito: Optional[str] = None


class ClientListOut(BaseModel):
    items: List[OwnerClientOut]
    total: int


class OwnerClientDetailOut(OwnerClientOut):
    reservas: List[OwnerReservationOut]


class ReportTotals(BaseModel):
    reservas: int = 0
    completadas: int = 0
    canceladas: int = 0
    pendientes: int = 0
    confirmadas: int = 0
    ingresos: float = 0
    ticket_promedio: float = 0
    tasa_cancelacion: float = 0
    clientes_unicos: int = 0


class ReportRange(BaseModel):
    desde: date
    hasta: date
    dias: int


class ReportDailyPoint(BaseModel):
    fecha: date
    total: int
    completadas: int
    canceladas: int
    ingresos: float


class ReportServiceItem(BaseModel):
    servicio_id: int
    nombre: str
    reservas: int
    completadas: int
    ingresos: float


class ReportProfessionalItem(BaseModel):
    profesional_id: int
    nombre: str
    reservas: int
    completadas: int
    ingresos: float


class ReportStatusItem(BaseModel):
    estado: EstadoReserva
    total: int


class ReportWeekdayItem(BaseModel):
    dia: int
    label: str
    total: int
    ingresos: float


class ReportHourItem(BaseModel):
    hora: int
    total: int


class OwnerReportOut(BaseModel):
    rango: ReportRange
    totales: ReportTotals
    comparacion: ReportTotals
    diario: List[ReportDailyPoint]
    servicios_top: List[ReportServiceItem]
    profesionales_top: List[ReportProfessionalItem]
    estados: List[ReportStatusItem]
    dias_semana: List[ReportWeekdayItem]
    horas_pico: List[ReportHourItem]
