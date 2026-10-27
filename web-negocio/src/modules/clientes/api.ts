import { apiRequest, queryString } from "../../lib/request";
import type { ClientDetail, ClientListResponse } from "./types";

export function getClients(
  shopId: number,
  search?: string,
): Promise<ClientListResponse> {
  const query = queryString({ search });
  return apiRequest(
    `/owner/${shopId}/clients${query}`,
    {},
    "No pudimos cargar los clientes.",
  );
}

export function getClient(shopId: number, clientId: number): Promise<ClientDetail> {
  return apiRequest(
    `/owner/${shopId}/clients/${clientId}`,
    {},
    "No pudimos cargar el historial del cliente.",
  );
}
