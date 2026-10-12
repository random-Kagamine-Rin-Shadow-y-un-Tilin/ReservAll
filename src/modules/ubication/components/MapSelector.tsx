import { useState, useRef } from "react";
import { MapContainer, TileLayer, Marker, useMapEvents } from 'react-leaflet'
import type { LeafletMouseEvent } from "leaflet";
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'

import icon from 'leaflet/dist/images/marker-icon.png'
import iconShadow from 'leaflet/dist/images/marker-shadow.png'

 const defaultIcon = L.icon({
    iconUrl: icon,
    shadowUrl: iconShadow,
    iconSize: [25, 41],
    iconAnchor: [12, 41],
 })

 interface Coords{
    lat: number
    lng: number
 }

 interface MapSelectorProps{
    initialPosition: Coords
    onChangePosition: (coords: Coords) => void
 }

 function DraggableMarker({ position, onChangePosition } : {
    position: Coords
    onChangePosition: (coords: Coords) => void
 }) {
    const markerRef = useRef<L.Marker>(null)

    useMapEvents({
        click(e: LeafletMouseEvent){
            onChangePosition({lat: e.latlng.lat, lng: e.latlng.lng})
        },
    })

    return (
        <Marker
            position={position}
            draggable
            icon={defaultIcon}
            ref={markerRef}
            eventHandlers={{
                dragend: () =>{
                    const marker = markerRef.current
                    if (marker){
                        const { lat, lng } = marker.getLatLng()
                        onChangePosition({lat, lng})
                    }
                },
            }}
            />    
    )
 }

 export function MapSelector({initialPosition, onChangePosition}: MapSelectorProps){
    const [position, setPosition] = useState<Coords>(initialPosition)

    function handleChange(coords: Coords){
        setPosition(coords)
        onChangePosition(coords)
    }

    return (
        <MapContainer
        center={position}
        zoom={16}
        style={{ height: '400px', width: '100%', borderRadius: '8px' }}
        >
            <TileLayer
                attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            />

            <DraggableMarker position={position} onChangePosition={handleChange} />
        </MapContainer>
    )
 }