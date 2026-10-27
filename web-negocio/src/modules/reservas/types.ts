export type ReservationStatus =
  | "pendiente"
  | "confirmada"
  | "completada"
  | "cancelada";

export interface Reservation {
  id_reserva: number;
  cliente_id: number;
  cliente_nombre: string;
  cliente_correo: string;
  servicio_id: number;
  servicio_nombre: string;
  duracion_minutos: number;
  precio: number;
  profesional_id: number | null;
  profesional_nombre: string | null;
  fecha: string;
  hora_inicio: string;
  hora_fin: string | null;
  estado: ReservationStatus;
  fecha_creacion: string | null;
}

export interface ReservationSummary {
  total: number;
  pendientes: number;
  confirmadas: number;
  completadas: number;
  canceladas: number;
  ingresos: number;
}

export interface ReservationListResponse {
  items: Reservation[];
  summary: ReservationSummary;
}

export interface ReservationFilters {
  fecha_desde?: string;
  fecha_hasta?: string;
  estado?: ReservationStatus;
  profesional_id?: number;
  search?: string;
}
