from fastapi import APIRouter, Depends, Query
from app.core.dependencies import verify_api_key
from app.models.location import GeocodeResult, ReverseGeocodeOut
from app.services import location_service

router = APIRouter(
    prefix="/locations",
    tags=["locations"],
    dependencies=[Depends(verify_api_key)],
)


@router.get("/geocode", response_model=list[GeocodeResult])
async def geocode_address(
    q: str = Query(
        ...,
        min_length=3,
        max_length=200,
        description="Texto de la dirección: calle, ciudad, estado o código postal",
    ),
    limit: int = Query(5, ge=1, le=10, description="Número máximo de resultados"),
    pais: str | None = Query(
        None,
        min_length=2,
        max_length=2,
        description="Código ISO de dos letras para restringir el país (ej. mx)",
    ),
    cerca_lat: float | None = Query(
        None,
        ge=-90,
        le=90,
        description="Latitud de referencia para priorizar resultados cercanos",
    ),
    cerca_lng: float | None = Query(
        None,
        ge=-180,
        le=180,
        description="Longitud de referencia para priorizar resultados cercanos",
    ),
):
    return await location_service.search_locations(
        q,
        limit=limit,
        country_codes=pais,
        near_lat=cerca_lat,
        near_lng=cerca_lng,
    )


@router.get("/reverse", response_model=ReverseGeocodeOut)
async def reverse_geocode(
    lat: float = Query(..., ge=-90, le=90, description="Latitud"),
    lng: float = Query(..., ge=-180, le=180, description="Longitud"),
    zoom: int = Query(
        18,
        ge=3,
        le=18,
        description="Nivel de detalle: 18 edificio, 16 calle, 14 colonia, 10 ciudad",
    ),
):
    return await location_service.reverse_geocode(lat, lng, zoom=zoom)
