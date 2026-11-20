import asyncio
import time
from typing import Any, Optional
from urllib.parse import urlencode

import httpx
from fastapi import HTTPException, status

from app.core.config import settings

# Nominatim (OpenStreetMap) pide no superar una petición por segundo y enviar
# un User-Agent identificable. Se centraliza aquí para que el frontend no llame
# directo al servicio externo (CORS, cuotas y formato consistente).
_MIN_INTERVAL_SECONDS = 1.0
_CACHE_TTL_SECONDS = 300.0
_CACHE_MAX_ENTRIES = 256

_cache: dict[str, tuple[float, Any]] = {}
_request_lock = asyncio.Lock()
_last_request_at = 0.0


def _cache_get(key: str) -> Any | None:
    cached = _cache.get(key)
    if cached is None:
        return None

    expires_at, value = cached
    if time.monotonic() >= expires_at:
        _cache.pop(key, None)
        return None
    return value


def _cache_set(key: str, value: Any) -> None:
    if len(_cache) >= _CACHE_MAX_ENTRIES:
        # Descarta la entrada más antigua para acotar el uso de memoria.
        _cache.pop(next(iter(_cache)))
    _cache[key] = (time.monotonic() + _CACHE_TTL_SECONDS, value)


async def _nominatim_get(path: str, params: dict[str, Any]) -> Any:
    cache_key = f"{path}?{urlencode(sorted(params.items()))}"
    cached = _cache_get(cache_key)
    if cached is not None:
        return cached

    global _last_request_at

    url = f"{settings.geocoding_url.rstrip('/')}{path}"
    headers = {
        "User-Agent": settings.geocoding_user_agent,
        "Accept": "application/json",
        "Accept-Language": "es",
    }

    async with _request_lock:
        # Otra petición pudo llenar la caché mientras se esperaba el turno.
        cached = _cache_get(cache_key)
        if cached is not None:
            return cached

        wait = _MIN_INTERVAL_SECONDS - (time.monotonic() - _last_request_at)
        if wait > 0:
            await asyncio.sleep(wait)

        try:
            async with httpx.AsyncClient(
                timeout=settings.geocoding_timeout_seconds
            ) as client:
                response = await client.get(url, params=params, headers=headers)
        except httpx.TimeoutException:
            raise HTTPException(
                status.HTTP_504_GATEWAY_TIMEOUT,
                "El servicio de mapas tardó demasiado en responder.",
            )
        except httpx.RequestError:
            raise HTTPException(
                status.HTTP_503_SERVICE_UNAVAILABLE,
                "No se pudo contactar al servicio de mapas.",
            )
        finally:
            _last_request_at = time.monotonic()

    if response.status_code == status.HTTP_429_TOO_MANY_REQUESTS:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            "El servicio de mapas está saturado. Intenta de nuevo en unos segundos.",
        )
    if response.status_code >= status.HTTP_500_INTERNAL_SERVER_ERROR:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            "El servicio de mapas no está disponible en este momento.",
        )
    if response.status_code >= status.HTTP_400_BAD_REQUEST:
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY,
            "El servicio de mapas devolvió una respuesta inválida.",
        )

    try:
        data = response.json()
    except ValueError:
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY,
            "El servicio de mapas devolvió una respuesta inválida.",
        )

    _cache_set(cache_key, data)
    return data


def _first(address: dict[str, Any], *keys: str) -> str:
    for key in keys:
        value = address.get(key)
        if value:
            return str(value)
    return ""


def _parse_nominatim_item(item: dict[str, Any]) -> dict[str, Any]:
    address = item.get("address") or {}

    return {
        "display_name": item.get("display_name", ""),
        "latitud": float(item["lat"]),
        "longitud": float(item["lon"]),
        "osm_id": str(item.get("osm_id", "")),
        "osm_type": item.get("osm_type"),
        "tipo": item.get("type"),
        "clase": item.get("class"),
        "direccion_calle": _first(
            address,
            "road",
            "pedestrian",
            "footway",
            "cycleway",
            "path",
            "residential",
            "square",
        ),
        "ciudad": _first(
            address, "city", "town", "village", "municipality", "county"
        ),
        "estado": _first(address, "state", "region", "province"),
        "codigo_postal": str(address.get("postcode") or ""),
        "pais": _first(address, "country"),
        "numero_local": str(address.get("house_number") or ""),
        # OpenStreetMap no distingue número interior; el usuario lo completa.
        "numero_interior": "",
    }


async def search_locations(
    query: str,
    *,
    limit: int = 5,
    country_codes: Optional[str] = None,
    near_lat: Optional[float] = None,
    near_lng: Optional[float] = None,
) -> list[dict[str, Any]]:
    """Busca direcciones por texto y devuelve candidatos normalizados."""

    query = query.strip()
    if len(query) < 3:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Escribe al menos 3 caracteres para buscar una dirección.",
        )

    if (near_lat is None) != (near_lng is None):
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Debes enviar cerca_lat y cerca_lng juntos.",
        )

    params: dict[str, Any] = {
        "q": query,
        "format": "jsonv2",
        "addressdetails": 1,
        "limit": limit,
        "dedupe": 1,
    }

    if country_codes:
        params["countrycodes"] = country_codes.lower()

    # Sesga los resultados hacia la zona del usuario sin descartar el resto.
    if near_lat is not None and near_lng is not None:
        delta = 0.5
        params["viewbox"] = (
            f"{near_lng - delta},{near_lat + delta},"
            f"{near_lng + delta},{near_lat - delta}"
        )
        params["bounded"] = 0

    data = await _nominatim_get("/search", params)
    if not isinstance(data, list):
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY,
            "El servicio de mapas devolvió una respuesta inválida.",
        )

    results: list[dict[str, Any]] = []
    for item in data:
        if not isinstance(item, dict) or "lat" not in item or "lon" not in item:
            continue
        results.append(_parse_nominatim_item(item))

    return results


async def reverse_geocode(lat: float, lng: float, *, zoom: int = 18) -> dict[str, Any]:
    """Obtiene la dirección correspondiente a una coordenada."""

    params = {
        "lat": lat,
        "lon": lng,
        "format": "jsonv2",
        "addressdetails": 1,
        "zoom": zoom,
    }

    data = await _nominatim_get("/reverse", params)

    if not isinstance(data, dict) or data.get("error"):
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "No se encontró una dirección para esa ubicación.",
        )

    return _parse_nominatim_item(data)
