import { apiRequest, jsonRequest, queryString } from "../../lib/request";
import type {
  Reservation,
  ReservationFilters,
  ReservationListResponse,
  ReservationStatus,
} from "./types";

export function getReservations(
  shopId: number,
  filters: ReservationFilters = {},
): Promise<ReservationListResponse> {
  const query = queryString({
    fecha_desde: filters.fecha_desde,
    fecha_hasta: filters.fecha_hasta,
    estado: filters.estado,
    profesional_id: filters.profesional_id,
    search: filters.search,
  });

  return apiRequest(
    `/owner/${shopId}/reservations${query}`,
    {},
    "No pudimos cargar las reservas.",
  );
}

export function getReservation(
  shopId: number,
  reservationId: number,
): Promise<Reservation> {
  return apiRequest(
    `/owner/${shopId}/reservations/${reservationId}`,
    {},
    "No pudimos cargar la reserva.",
  );
}

export function updateReservationStatus(
  shopId: number,
  reservationId: number,
  estado: ReservationStatus,
): Promise<Reservation> {
  return jsonRequest(
    `/owner/${shopId}/reservations/${reservationId}/status`,
    "PATCH",
    { estado },
    "No pudimos actualizar la reserva.",
  );
}
