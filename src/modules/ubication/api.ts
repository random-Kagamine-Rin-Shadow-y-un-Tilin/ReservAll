interface GeocodedAddress{
    direccion_calle: string
    ciudad: string
    estado: string
    codigo_postal: string
    pais: string
    osm_id: string
    numero_local: string
    numero_interior: string
}

export async function getAddressByCoord(lat: number, lng: number): Promise<GeocodedAddress> {
    const url = `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lng}&format=json&addressdetails=1`

    const res = await fetch(url, {
        headers: {
            'Accept-Language': 'es',
        },
    })

    if (!res.ok){
        throw new Error('No se pudo obtener la dirección de esa ubicación.')
    }

    const data = await res.json()
    const address = data.address ?? {}

    return {
        direccion_calle: [address.road, address.house_number].filter(Boolean).join(' ') || 'Sin calle detectada',
        ciudad: address.city || address.town || address.village || address.municipality || '',
        estado: address.state || '',
        codigo_postal: address.postcode || '',
        pais: address.country || '',
        osm_id: data.osm_id?.toString() || '',
        numero_local: '',
        numero_interior: '',
    }
}