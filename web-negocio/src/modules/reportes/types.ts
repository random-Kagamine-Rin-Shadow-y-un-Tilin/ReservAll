import type { ReservationStatus } from "../reservas/types";

export interface ReportTotals {
  reservas: number;
  completadas: number;
  canceladas: number;
  pendientes: number;
  confirmadas: number;
  ingresos: number;
  ticket_promedio: number;
  tasa_cancelacion: number;
  clientes_unicos: number;
}

export interface ReportRange {
  desde: string;
  hasta: string;
  dias: number;
}

export interface ReportDailyPoint {
  fecha: string;
  total: number;
  completadas: number;
  canceladas: number;
  ingresos: number;
}

export interface ReportServiceItem {
  servicio_id: number;
  nombre: string;
  reservas: number;
  completadas: number;
  ingresos: number;
}

export interface ReportProfessionalItem {
  profesional_id: number;
  nombre: string;
  reservas: number;
  completadas: number;
  ingresos: number;
}

export interface ReportStatusItem {
  estado: ReservationStatus;
  total: number;
}

export interface ReportWeekdayItem {
  dia: number;
  label: string;
  total: number;
  ingresos: number;
}

export interface ReportHourItem {
  hora: number;
  total: number;
}

export interface Report {
  rango: ReportRange;
  totales: ReportTotals;
  comparacion: ReportTotals;
  diario: ReportDailyPoint[];
  servicios_top: ReportServiceItem[];
  profesionales_top: ReportProfessionalItem[];
  estados: ReportStatusItem[];
  dias_semana: ReportWeekdayItem[];
  horas_pico: ReportHourItem[];
}
