import type { Schedule } from "../negocio/types";
import type { Reservation } from "../reservas/types";

export interface AgendaSlot {
  hora_inicio: string;
  hora_fin: string;
  disponible: boolean;
  motivo: string | null;
}

export interface AgendaBlock {
  id_bloqueo: number;
  negocio_id: number;
  fecha: string;
  hora_inicio: string | null;
  hora_fin: string | null;
  motivo: string | null;
  fecha_creacion: string | null;
}

export interface AgendaDay {
  fecha: string;
  dia_semana: string;
  abierto: boolean;
  bloqueado: boolean;
  horario: Schedule | null;
  reservas: Reservation[];
  bloqueos: AgendaBlock[];
  disponibilidad: AgendaSlot[];
}

export interface AgendaRange {
  desde: string;
  hasta: string;
  dias: number;
}

export interface AgendaSummary {
  total_reservas: number;
  pendientes: number;
  confirmadas: number;
  completadas: number;
  canceladas: number;
  dias_abiertos: number;
  dias_bloqueados: number;
  dias_cerrados: number;
}

export interface AgendaResponse {
  negocio_id: number;
  rango: AgendaRange;
  horarios: Schedule[];
  dias: AgendaDay[];
  resumen: AgendaSummary;
}

export interface AgendaFilters {
  fecha_desde?: string;
  fecha_hasta?: string;
  servicio_id?: number;
  profesional_id?: number;
  intervalo_minutos?: number;
  descanso_minutos?: number;
}

export interface BlockListResponse {
  items: AgendaBlock[];
  total: number;
}

export interface BlockPayload {
  fecha: string;
  hora_inicio?: string | null;
  hora_fin?: string | null;
  motivo?: string | null;
}
