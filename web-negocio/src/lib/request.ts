import { fetchWithAuth } from "./api";
import { API_URL } from "./config";

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

export async function apiRequest<T>(
  path: string,
  options: RequestInit = {},
  fallbackError = "Ocurrió un error inesperado.",
): Promise<T> {
  let res: Response;

  try {
    res = await fetchWithAuth(`${API_URL}${path}`, options);
  } catch {
    throw new Error(
      typeof navigator !== "undefined" && navigator.onLine === false
        ? "Sin conexión. No hay datos guardados para esta sección todavía."
        : "No pudimos conectar con el servidor. Revisa tu conexión e inténtalo de nuevo.",
    );
  }

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

export function jsonRequest<T>(
  path: string,
  method: string,
  body: unknown,
  fallbackError: string,
): Promise<T> {
  return apiRequest<T>(
    path,
    {
      method,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    },
    fallbackError,
  );
}

type QueryValue = string | number | boolean | null | undefined;

export function queryString(params: Record<string, QueryValue>): string {
  const search = new URLSearchParams();
  Object.entries(params).forEach(([key, value]) => {
    if (value === undefined || value === null || value === "") return;
    search.set(key, String(value));
  });
  const query = search.toString();
  return query ? `?${query}` : "";
}
