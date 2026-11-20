from pydantic import BaseModel, Field


class GeocodedAddress(BaseModel):
    """Dirección normalizada a partir de un resultado de OpenStreetMap."""

    direccion_calle: str = ""
    ciudad: str = ""
    estado: str = ""
    codigo_postal: str = ""
    pais: str = ""
    osm_id: str = ""
    numero_local: str = ""
    numero_interior: str = ""


class ReverseGeocodeOut(GeocodedAddress):
    """Dirección obtenida a partir de una coordenada (latitud/longitud)."""

    display_name: str = ""
    latitud: float = Field(..., ge=-90, le=90)
    longitud: float = Field(..., ge=-180, le=180)
    osm_type: str | None = None


class GeocodeResult(GeocodedAddress):
    """Candidato devuelto por el buscador de direcciones."""

    display_name: str
    latitud: float = Field(..., ge=-90, le=90)
    longitud: float = Field(..., ge=-180, le=180)
    osm_type: str | None = None
    tipo: str | None = None
    clase: str | None = None
