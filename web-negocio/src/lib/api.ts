import { API_KEY, API_URL } from "./config";
import {
  cachedResponseToResponse,
  readCachedResponse,
  writeCachedResponse,
} from "./offlineCache";

function isCacheable(url: string, options: RequestInit): boolean {
  const method = (options.method ?? "GET").toUpperCase();
  return method === "GET" && url.startsWith(API_URL);
}

async function storeResponse(url: string, res: Response): Promise<void> {
  if (!res.ok) return;

  const contentType = res.headers.get("content-type") ?? "";
  if (!contentType.includes("application/json")) return;

  try {
    const body = await res.clone().text();
    writeCachedResponse(url, body, contentType);
  } catch {
    // Si el navegador no permite clonar/leer la respuesta, se ignora.
  }
}

export async function fetchWithAuth(
  url: string,
  options: RequestInit = {},
): Promise<Response> {
  const cacheable = isCacheable(url, options);

  try {
    let res = await fetch(url, {
      ...options,
      credentials: "include",
      headers: { ...options.headers, "x-api-key": API_KEY },
    });

    if (res.status === 401) {
      // Try to refresh the access token
      try {
        const refreshRes = await fetch(`${API_URL}/auth/refresh`, {
          method: "POST",
          credentials: "include",
          headers: { "x-api-key": API_KEY },
        });

        if (refreshRes.ok) {
          // Try again the original request
          res = await fetch(url, {
            ...options,
            credentials: "include",
            headers: { ...options.headers, "x-api-key": API_KEY },
          });
        }
      } catch {
        // Sin conexión durante el refresh: se conserva la respuesta original.
      }
    }

    if (cacheable) {
      await storeResponse(url, res);
    }

    return res;
  } catch (error) {
    // Sin red: devolvemos la última respuesta válida guardada en el dispositivo.
    if (cacheable) {
      const cached = readCachedResponse(url);
      if (cached) return cachedResponseToResponse(cached);
    }
    throw error;
  }
}
