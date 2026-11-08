import { apiRequest, jsonRequest, queryString } from "../../lib/request";
import type {
  AgendaFilters,
  AgendaResponse,
  BlockListResponse,
  BlockPayload,
  AgendaBlock,
} from "./types";

export function getAgenda(
  shopId: number,
  filters: AgendaFilters = {},
): Promise<AgendaResponse> {
  const query = queryString({
    fecha_desde: filters.fecha_desde,
    fecha_hasta: filters.fecha_hasta,
    servicio_id: filters.servicio_id,
    profesional_id: filters.profesional_id,
    intervalo_minutos: filters.intervalo_minutos,
    descanso_minutos: filters.descanso_minutos,
  });

  return apiRequest(
    `/owner/${shopId}/agenda${query}`,
    {},
    "No pudimos cargar la agenda.",
  );
}

export function getBlocks(
  shopId: number,
  filters: Pick<AgendaFilters, "fecha_desde" | "fecha_hasta"> = {},
): Promise<BlockListResponse> {
  const query = queryString({
    fecha_desde: filters.fecha_desde,
    fecha_hasta: filters.fecha_hasta,
  });

  return apiRequest(
    `/owner/${shopId}/blocks${query}`,
    {},
    "No pudimos cargar los bloqueos.",
  );
}

export function createBlock(
  shopId: number,
  payload: BlockPayload,
): Promise<AgendaBlock> {
  return jsonRequest(
    `/owner/${shopId}/blocks`,
    "POST",
    {
      fecha: payload.fecha,
      hora_inicio: payload.hora_inicio ?? null,
      hora_fin: payload.hora_fin ?? null,
      motivo: payload.motivo?.trim() || null,
    },
    "No pudimos crear el bloqueo.",
  );
}

export function deleteBlock(
  shopId: number,
  blockId: number,
): Promise<{ message: string }> {
  return apiRequest(
    `/owner/${shopId}/blocks/${blockId}`,
    { method: "DELETE" },
    "No pudimos eliminar el bloqueo.",
  );
}
