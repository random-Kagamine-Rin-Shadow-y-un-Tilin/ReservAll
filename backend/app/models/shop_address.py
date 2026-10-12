from pydantic import BaseModel

class ShopAddressRegister(BaseModel):
    direccion_calle: str
    ciudad: str
    estado: str
    codigo_postal: str
    pais: str
    latitud: float
    longitud: float
    osm_id: str
    numero_local: str
    numero_interior: str | None

class ShopAddressOut(BaseModel):
    id_direccion: int
    direccion_calle: str
    ciudad: str
    estado: str
    codigo_postal: str
    pais: str
    latitud: float
    longitud: float
    osm_id: str
    numero_local: str
    numero_interior: str | None
        