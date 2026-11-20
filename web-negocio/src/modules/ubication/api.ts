import { fetchWithAuth } from "../../lib/api";

const API_URL = import.meta.env.VITE_API_URL;

export interface GeocodedAddress {
  direccion_calle: string;
  ciudad: string;
  estado: string;
  codigo_postal: string;
  pais: string;
  osm_id: string;
  numero_local: string;
  numero_interior: string;
}

export interface GeocodeResult extends GeocodedAddress {
  display_name: string;
  latitud: number;
  longitud: number;
  osm_type: string | null;
  tipo: string | null;
  clase: string | null;
}

interface ReverseGeocodeResponse extends GeocodedAddress {
  display_name: string;
  latitud: number;
  longitud: number;
  osm_type: string | null;
}

async function readApiError(res: Response, fallback: string): Promise<never> {
  let message = fallback;

  try {
    const data = await res.json();
    const detail = data?.detail;

    if (typeof detail === "string") {
      message = detail;
    } else if (Array.isArray(detail)) {
      message = detail
        .map((item) =>
          item && typeof item === "object" && "msg" in item
            ? String((item as { msg: unknown }).msg)
            : String(item),
        )
        .join(" · ");
    }
  } catch {
    // La respuesta no era JSON; se conserva el mensaje por defecto.
  }

  throw new Error(message);
}

export async function getAddressByCoord(
  lat: number,
  lng: number,
): Promise<GeocodedAddress> {
  const url = `${API_URL}/locations/reverse?lat=${lat}&lng=${lng}&zoom=18`;
  const res = await fetchWithAuth(url);

  if (!res.ok) {
    await readApiError(
      res,
      "No se pudo obtener la dirección de esa ubicación.",
    );
  }

  const data = (await res.json()) as ReverseGeocodeResponse;

  return {
    direccion_calle: data.direccion_calle ?? "",
    ciudad: data.ciudad ?? "",
    estado: data.estado ?? "",
    codigo_postal: data.codigo_postal ?? "",
    pais: data.pais ?? "",
    osm_id: data.osm_id ?? "",
    numero_local: data.numero_local ?? "",
    numero_interior: data.numero_interior ?? "",
  };
}

export async function searchAddresses(
  query: string,
  options: { limit?: number; pais?: string } = {},
): Promise<GeocodeResult[]> {
  const params = new URLSearchParams({ q: query });

  if (options.limit) params.set("limit", String(options.limit));
  if (options.pais) params.set("pais", options.pais);

  const res = await fetchWithAuth(
    `${API_URL}/locations/geocode?${params.toString()}`,
  );

  if (!res.ok) {
    await readApiError(res, "No se pudieron buscar direcciones.");
  }

  return (await res.json()) as GeocodeResult[];
}
