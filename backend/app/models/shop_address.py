from pydantic import BaseModel, ConfigDict, Field


class ShopAddressRegister(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    direccion_calle: str = Field(..., min_length=1, max_length=255)
    ciudad: str = Field(..., min_length=1, max_length=120)
    estado: str = Field(..., min_length=1, max_length=120)
    codigo_postal: str = Field(..., min_length=1, max_length=20)
    pais: str = Field(..., min_length=1, max_length=120)
    latitud: float = Field(..., ge=-90, le=90)
    longitud: float = Field(..., ge=-180, le=180)
    osm_id: str = Field(default="", max_length=64)
    numero_local: str = Field(..., min_length=1, max_length=20)
    numero_interior: str | None = Field(default=None, max_length=20)


class ShopAddressUpdate(BaseModel):
    """Actualización parcial de la ubicación de un negocio.

    Solo se aplican los campos enviados. Esto permite mover el marcador del
    mapa o corregir un dato sin tener que reenviar toda la dirección.
    """

    model_config = ConfigDict(str_strip_whitespace=True)

    direccion_calle: str | None = Field(None, min_length=1, max_length=255)
    ciudad: str | None = Field(None, min_length=1, max_length=120)
    estado: str | None = Field(None, min_length=1, max_length=120)
    codigo_postal: str | None = Field(None, min_length=1, max_length=20)
    pais: str | None = Field(None, min_length=1, max_length=120)
    latitud: float | None = Field(None, ge=-90, le=90)
    longitud: float | None = Field(None, ge=-180, le=180)
    osm_id: str | None = Field(None, max_length=64)
    numero_local: str | None = Field(None, min_length=1, max_length=20)
    numero_interior: str | None = Field(None, max_length=20)


class ShopAddressOut(BaseModel):
    id_direccion: int
    direccion_calle: str
    ciudad: str
    estado: str
    codigo_postal: str
    pais: str
    latitud: float
    longitud: float
    osm_id: str | None = None
    numero_local: str
    numero_interior: str | None = None
