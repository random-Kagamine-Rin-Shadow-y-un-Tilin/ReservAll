import type { Reservation } from "../reservas/types";

export interface Client {
  cliente_id: number;
  nombre: string;
  correo: string;
  total_reservas: number;
  completadas: number;
  canceladas: number;
  activas: number;
  primera_reserva: string | null;
  ultima_reserva: string | null;
  total_gastado: number;
  servicio_favorito: string | null;
}

export interface ClientListResponse {
  items: Client[];
  total: number;
}

export interface ClientDetail extends Client {
  reservas: Reservation[];
}
