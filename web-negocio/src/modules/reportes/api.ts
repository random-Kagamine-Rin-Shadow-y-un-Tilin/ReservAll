import { apiRequest, queryString } from "../../lib/request";
import type { Report } from "./types";

export function getReport(
  shopId: number,
  desde: string,
  hasta: string,
): Promise<Report> {
  const query = queryString({ fecha_desde: desde, fecha_hasta: hasta });
  return apiRequest(
    `/owner/${shopId}/reports/summary${query}`,
    {},
    "No pudimos generar el reporte.",
  );
}
