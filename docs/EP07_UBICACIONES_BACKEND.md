# Épica 07 - Ubicaciones y mapas (backend)

Endpoints agregados para gestionar la ubicación de los negocios y alimentar los
mapas del panel web y de las apps móviles.

Todos los endpoints requieren el header `x-api-key`. Los de negocio requieren
además la cookie de sesión (`SNRL_access_token`) y que el usuario sea el dueño
del negocio.

## Geocodificación

El backend hace de proxy de OpenStreetMap/Nominatim para evitar CORS, centralizar
el formato y respetar el límite de una petición por segundo.

### Buscar una dirección

```http
GET /api/v1/locations/geocode?q=Av.%20Ju%C3%A1rez%20100%2C%20CDMX&limit=5
```

Parámetros opcionales:

| Parámetro  | Descripción                                              |
| ---------- | -------------------------------------------------------- |
| `pais`     | Código ISO de dos letras para restringir el país (`mx`). |
| `cerca_lat`| Latitud de referencia para priorizar resultados cercanos.|
| `cerca_lng`| Longitud de referencia para priorizar resultados cercanos.|

Respuesta:

```json
[
  {
    "display_name": "Avenida Juárez 100, Centro, Cuauhtémoc, CDMX, México",
    "latitud": 19.4326,
    "longitud": -99.1332,
    "osm_id": "123456",
    "osm_type": "way",
    "tipo": "residential",
    "clase": "highway",
    "direccion_calle": "Avenida Juárez",
    "ciudad": "Ciudad de México",
    "estado": "Ciudad de México",
    "codigo_postal": "06000",
    "pais": "México",
    "numero_local": "100",
    "numero_interior": ""
  }
]
```

### Obtener la dirección de una coordenada

```http
GET /api/v1/locations/reverse?lat=19.4326&lng=-99.1332&zoom=18
```

`zoom` va de 3 a 18 (18 = edificio, 16 = calle, 14 = colonia, 10 = ciudad).
Devuelve el mismo formato plano que `geocode`, más `display_name`, `latitud`,
`longitud` y `osm_type`.

## Dirección del negocio

### Registrar la dirección

Sin cambios de contrato:

```http
POST /api/v1/shop/register-address/{shop_id}
```

### Editar o mover la ubicación

```http
PUT /api/v1/shop/edit-address/{shop_id}
```

Acepta actualización parcial. Solo se actualizan los campos enviados:

```json
{
  "latitud": 19.4326,
  "longitud": -99.1332,
  "direccion_calle": "Avenida Juárez",
  "numero_local": "100"
}
```

También sirve para corregir `ciudad`, `estado`, `codigo_postal`, `pais`,
`osm_id` o `numero_interior`. Para borrar el número interior envía
`"numero_interior": null`.

## Mapa de negocios

```http
GET /api/v1/client/map/shops?min_lat=19.40&max_lat=19.46&min_lng=-99.17&max_lng=-99.10
```

Devuelve solo negocios activos que tengan coordenadas registradas:

```json
[
  {
    "id": 12,
    "nombre": "Barbería Central",
    "imagen_negocio": "https://...",
    "categoria_negocio": "Barbería",
    "id_categoria": 3,
    "direccion": "Avenida Juárez 100, Ciudad de México, Ciudad de México",
    "ciudad": "Ciudad de México",
    "estado_direccion": "Ciudad de México",
    "latitud": 19.4326,
    "longitud": -99.1332,
    "precio_minimo": 120.0,
    "precio_maximo": 350.0,
    "distancia_km": 1.24
  }
]
```

Filtros disponibles:

| Parámetro      | Descripción                                                    |
| -------------- | -------------------------------------------------------------- |
| `min_lat`, `max_lat`, `min_lng`, `max_lng` | Zona visible del mapa (los cuatro juntos). |
| `lat`, `lng`   | Centro para calcular `distancia_km`. Deben ir juntos.           |
| `radio_km`     | Radio máximo desde `lat/lng`.                                   |
| `q`            | Texto libre (nombre, descripción, categoría o servicio).        |
| `categoria_id` | ID de categoría.                                                |
| `ciudad`       | Nombre de ciudad.                                               |
| `limit`, `offset` | Paginación (máximo 500 por página).                          |

## Base de datos

Aplicar la migración:

```powershell
psql "$env:DATABASE_URL" -f migrations/003_direcciones_negocio_ubicacion.sql
```

Agrega índices para el mapa, valida rangos de latitud/longitud e intenta crear
un índice único por `negocio_id` si no existen direcciones duplicadas.
