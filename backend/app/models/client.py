from __future__ import annotations

from pydantic import BaseModel, Field
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
    descripcion: Optional[str] = None
    imagen_negocio: Optional[str] = None
    categoria_negocio: Optional[str] = None
    id_categoria: Optional[int] = None
    direccion: Optional[str] = None
    ciudad: Optional[str] = None
    estado_direccion: Optional[str] = None
    pais: Optional[str] = None
    latitud: Optional[float] = None
    longitud: Optional[float] = None
    # HU_37 (valoración) está marcada como WON'T: se expone el campo en None
    # para que el contrato quede listo cuando exista el módulo de reseñas.
    valoracion: Optional[float] = None
    precio_minimo: Optional[float] = None
    precio_maximo: Optional[float] = None
    servicios_count: int = 0
    servicios: List[str] = []
    reservas_count: int = 0
    distancia_km: Optional[float] = None
    disponible: Optional[bool] = None


class CategoryView(BaseModel):
    id_categoria: int
    nombre_categoria: str
    negocios_count: int = 0


class ShopAddressView(BaseModel):
    id_direccion: Optional[int] = None
    direccion_calle: Optional[str] = None
    ciudad: Optional[str] = None
    estado: Optional[str] = None
    codigo_postal: Optional[str] = None
    pais: Optional[str] = None
    latitud: Optional[float] = None
    longitud: Optional[float] = None
    osm_id: Optional[str] = None
    numero_local: Optional[str] = None
    numero_interior: Optional[str] = None


class ShopScheduleView(BaseModel):
    id_horario: int
    dia: str
    hora_apertura: time
    hora_cierre: time
    hora_descanso: Optional[time] = None
    estado_horario: Optional[bool] = True


class ShopDetailView(BaseModel):
    general: ShopView
    direccion: Optional[ShopAddressView] = None
    horarios: List[ShopScheduleView] = []
    servicios: List[ServiceView] = []


class ShopSearchParams(BaseModel):
    q: Optional[str] = None
    nombre: Optional[str] = None
    categoria: Optional[str] = None
    categoria_id: Optional[int] = None
    ciudad: Optional[str] = None
    lat: Optional[float] = None
    lng: Optional[float] = None
    radio_km: Optional[float] = None
    precio_min: Optional[float] = None
    precio_max: Optional[float] = None
    fecha: Optional[date] = None
    hora: Optional[time] = None
    servicio_id: Optional[int] = None
    orden: str = "relevancia"
    limit: int = 50
    offset: int = 0
    
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
    motivo: Optional[str] = None

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
    bloqueado: bool = False
    motivo_bloqueo: Optional[str] = None
    
# Modelo para crear reserva (HU_43)
class CreateReservationRequest(BaseModel):
    negocio_id: Optional[int] = Field(
        None, ge=1, description="ID del negocio seleccionado por el cliente"
    )
    servicio_id: int = Field(..., ge=1)
    fecha: date
    hora_inicio: time
    cliente_id: Optional[int] = None
    hora_fin: Optional[time] = None
    profesional_id: Optional[int] = Field(None, ge=1)
    comentario: Optional[str] = Field(
        None, max_length=500, description="Comentario adicional (opcional)"
    )

# Modelo de respuesta de una reserva vista por el cliente (HU_43, HU_47, HU_49)
class ClientReservationOut(BaseModel):
    id_reserva: int
    cliente_id: int
    negocio_id: int
    negocio_nombre: str
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
    comentario: Optional[str] = None
    motivo: Optional[str] = None
    fecha_creacion: Optional[datetime] = None
    fecha_actualizacion: Optional[datetime] = None

# Se mantiene el nombre anterior para no romper el contrato existente.
class ReservationResponse(ClientReservationOut):
    pass

class ClientReservationListOut(BaseModel):
    items: List[ClientReservationOut]
    total: int
    filtro: Optional[str] = None

# HU_46: cancelación por parte del cliente
class ClientReservationCancel(BaseModel):
    motivo: Optional[str] = Field(
        None, max_length=500, description="Motivo de cancelación (opcional)"
    )

# HU_50: reprogramación por parte del cliente
class ClientReservationReschedule(BaseModel):
    fecha: date
    hora_inicio: time
    profesional_id: Optional[int] = Field(None, ge=1)
    motivo: Optional[str] = Field(
        None, max_length=500, description="Motivo del cambio (opcional)"
    )

# Modelo para servicio
class ServiceView(BaseModel):
    id_servicio: int
    negocio_id: int
    nombre: str
    duracion_minutos: int
    precio: float