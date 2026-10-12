import { useState, useEffect } from "react";

interface Coords {
    lat: number
    lng: number
}

const FALLBACK_MEXICO: Coords = { lat: 19.4326, lng: -99.1332 }

export function useGeoLocation(){
    const [coords, setCoords] = useState<Coords>(FALLBACK_MEXICO)
    const [loading, setLoading] = useState(true)
    const [permDeneied, setPermDeneied] = useState(false)

    useEffect(()=>{
        if(!navigator.geolocation){
            setLoading(false)
            return
        }

        navigator.geolocation.getCurrentPosition(
            (position) =>{
                setCoords({
                    lat: position.coords.latitude, 
                    lng: position.coords.longitude
                })
                setLoading(false)
            },
            ()=>{
                setPermDeneied(true)
                setLoading(false)
            },
            {timeout: 5000}
        )
    },[])

    return { coords, loading, permDeneied }
}