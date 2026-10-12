from pydantic import BaseModel
from typing import Optional, List
from datetime import time, date, datetime
from enum import Enum

# Enum para días de la semana
class DiaSemana(str, Enum):
    LUNES = "Lunes"
    MARTES = "Martes"
    MIERCOLES = "Miércoles"
    JUEVES = "Jueves"
    VIERNES = "Viernes"
    SABADO = "Sábado"
    DOMINGO = "Domingo"
    
class EstadoReserva(str, Enum):
    PENDIENTE = "pendiente"
    CONFIRMADA = "confirmada"
    CANCELADA = "cancelada"
    COMPLETADA = "completada"

class ShopView(BaseModel):
    id: int
    nombre: str
    descripcion: str
    imagen_negocio: str
    categoria_negocio: str
    
class ShopSearchParams(BaseModel):
    nombre: Optional[str] = None
    categoria: Optional[str] = None
    # servicios: Optional[str] = None
    
class ShopSchedules(BaseModel):
    id: int
    dueno_id: int
    nombre: str
    descripcion: str
    imagen_negocio: str
    categoria_negocio: str
    estado_negocio: bool
    dia: DiaSemana
    hora_apertura: time
    hora_cierre: time
    estado_horario: bool
    hora_inicio: time
    hora_fin: time
    estado_hora: bool
    id_horario: int

class AvailableTimes(BaseModel):
    id_horario: int
    dia: str
    hora_inicio: time
    hora_fin: time
    disponible: bool

class ReservationRequest(BaseModel):
    negocio_id: int
    fecha: date
    servicio_id: Optional[int] = None
    hora_inicio: time
    hora_fin: time 

class AvailableTimesResponse(BaseModel):
    negocio_id: int
    nombre_negocio: str
    fecha: date
    horarios_disponibles: List[AvailableTimes]
    
# Modelo para crear reserva
class CreateReservationRequest(BaseModel):
    cliente_id: int
    servicio_id: int
    fecha: date
    hora_inicio: time
    hora_fin: time

# Modelo para respuesta de reserva
class ReservationResponse(BaseModel):
    id_reserva: int
    cliente_id: int
    servicio_id: int
    fecha: date
    hora_inicio: time
    estado: EstadoReserva
    fecha_creacion: datetime

# Modelo para servicio
class ServiceView(BaseModel):
    id_servicio: int
    negocio_id: int
    nombre: str
    duracion_minutos: int
    precio: float