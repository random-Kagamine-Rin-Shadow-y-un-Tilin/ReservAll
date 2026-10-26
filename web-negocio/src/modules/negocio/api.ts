import { fetchWithAuth } from "../../lib/api";
import type { ShopContactInfo, ShopGeneralInfo } from "../shop/types";
import type {
  ApiMessage,
  Professional,
  ProfessionalEditPayload,
  ProfessionalPayload,
  Schedule,
  ScheduleEditPayload,
  SchedulePayload,
  Service,
  ServiceEditPayload,
  ServicePayload,
} from "./types";

const API_URL = import.meta.env.VITE_API_URL;

function errorMessage(detail: unknown, fallback: string): string {
  if (typeof detail === "string") return detail;
  if (Array.isArray(detail)) {
    return detail
      .map((item) => {
        if (item && typeof item === "object" && "msg" in item) {
          return String((item as { msg: unknown }).msg);
        }
        return String(item);
      })
      .join(" · ");
  }
  return fallback;
}

async function request<T>(
  path: string,
  options: RequestInit = {},
  fallbackError = "Ocurrió un error inesperado.",
): Promise<T> {
  const res = await fetchWithAuth(`${API_URL}${path}`, options);
  const raw = await res.text();
  let data: unknown = null;

  if (raw) {
    try {
      data = JSON.parse(raw);
    } catch {
      data = raw;
    }
  }

  if (!res.ok) {
    const detail =
      data && typeof data === "object" && "detail" in data
        ? (data as { detail: unknown }).detail
        : null;
    throw new Error(errorMessage(detail, fallbackError));
  }

  return data as T;
}

function jsonRequest<T>(
  path: string,
  method: string,
  body: unknown,
  fallbackError: string,
): Promise<T> {
  return request<T>(
    path,
    {
      method,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    },
    fallbackError,
  );
}

/* -------------------------------------------------------------------------- */
/* Servicios                                                                  */
/* -------------------------------------------------------------------------- */

export function getServices(shopId: number): Promise<Service[]> {
  return request(`/service/list/${shopId}`, {}, "No pudimos cargar los servicios.");
}

export function createService(
  shopId: number,
  payload: ServicePayload,
): Promise<Service> {
  return jsonRequest(
    `/service/register/${shopId}`,
    "POST",
    payload,
    "No pudimos registrar el servicio.",
  );
}

export function editService(
  shopId: number,
  serviceId: number,
  payload: ServiceEditPayload,
): Promise<Service> {
  return jsonRequest(
    `/service/edit/${shopId}/${serviceId}`,
    "PUT",
    payload,
    "No pudimos actualizar el servicio.",
  );
}

export function deleteService(
  shopId: number,
  serviceId: number,
): Promise<ApiMessage> {
  return request(
    `/service/delete/${shopId}/${serviceId}`,
    { method: "DELETE" },
    "No pudimos eliminar el servicio.",
  );
}

/* -------------------------------------------------------------------------- */
/* Profesionales                                                              */
/* -------------------------------------------------------------------------- */

export function getProfessionals(shopId: number): Promise<Professional[]> {
  return request(
    `/professional/list/${shopId}`,
    {},
    "No pudimos cargar el equipo.",
  );
}

export function createProfessional(
  shopId: number,
  payload: ProfessionalPayload,
): Promise<Professional> {
  return jsonRequest(
    `/professional/register/${shopId}`,
    "POST",
    payload,
    "No pudimos registrar al profesional.",
  );
}

export function editProfessional(
  shopId: number,
  professionalId: number,
  payload: ProfessionalEditPayload,
): Promise<Professional> {
  return jsonRequest(
    `/professional/edit/${shopId}/${professionalId}`,
    "PUT",
    payload,
    "No pudimos actualizar al profesional.",
  );
}

export function deleteProfessional(
  shopId: number,
  professionalId: number,
): Promise<ApiMessage> {
  return request(
    `/professional/delete/${shopId}/${professionalId}`,
    { method: "DELETE" },
    "No pudimos desactivar al profesional.",
  );
}

/* -------------------------------------------------------------------------- */
/* Horarios                                                                   */
/* -------------------------------------------------------------------------- */

export function getSchedule(shopId: number): Promise<Schedule[]> {
  return request(
    `/shop/get-schedule/${shopId}`,
    {},
    "No pudimos cargar los horarios.",
  );
}

export async function createSchedule(
  shopId: number,
  payload: SchedulePayload,
): Promise<Schedule> {
  const created = await jsonRequest<Schedule>(
    `/shop/register-schedule/${shopId}`,
    "POST",
    {
      dia: payload.dia,
      hora_apertura: payload.hora_apertura,
      hora_cierre: payload.hora_cierre,
    },
    "No pudimos registrar el horario.",
  );

  // El endpoint de alta no acepta hora de descanso; se aplica con la edición.
  if (payload.hora_descanso) {
    return editSchedule(shopId, created.id_horario, {
      hora_apertura: payload.hora_apertura,
      hora_cierre: payload.hora_cierre,
      hora_descanso: payload.hora_descanso,
    });
  }

  return created;
}

export function editSchedule(
  shopId: number,
  scheduleId: number,
  payload: ScheduleEditPayload,
): Promise<Schedule> {
  return jsonRequest(
    `/shop/edit-schedule/${shopId}/${scheduleId}`,
    "PUT",
    payload,
    "No pudimos actualizar el horario.",
  );
}

export function deleteSchedule(
  shopId: number,
  scheduleId: number,
): Promise<ApiMessage> {
  return request(
    `/shop/delete-schedule/${shopId}/${scheduleId}`,
    { method: "DELETE" },
    "No pudimos eliminar el horario.",
  );
}

/* -------------------------------------------------------------------------- */
/* Contactos y visibilidad                                                    */
/* -------------------------------------------------------------------------- */

export function editContact(
  shopId: number,
  contactId: number,
  url: string,
): Promise<ShopContactInfo> {
  return jsonRequest(
    `/shop/edit-contact/${shopId}/${contactId}`,
    "PUT",
    { url },
    "No pudimos actualizar el contacto.",
  );
}

export function deleteContact(
  shopId: number,
  contactId: number,
): Promise<ApiMessage> {
  return request(
    `/shop/delete-contact/${shopId}/${contactId}`,
    { method: "DELETE" },
    "No pudimos eliminar el contacto.",
  );
}

/**
 * El backend no expone el estado del negocio en `/shop/my-shops`, así que se
 * deduce a partir del listado público de negocios activos.
 */
export async function getPublicShopIds(): Promise<number[] | null> {
  try {
    const shops = await request<ShopGeneralInfo[]>(
      "/client/list-shops",
      {},
      "No pudimos consultar la visibilidad del negocio.",
    );
    return shops.map((shop) => shop.id);
  } catch {
    return null;
  }
}

export function toggleShopStatus(
  shopId: number,
  estadoNegocio: boolean,
): Promise<{ message: string; shop: ShopGeneralInfo }> {
  return jsonRequest(
    `/shop/toggle-status/${shopId}`,
    "PATCH",
    { estado_negocio: estadoNegocio },
    "No pudimos cambiar la visibilidad del negocio.",
  );
}
