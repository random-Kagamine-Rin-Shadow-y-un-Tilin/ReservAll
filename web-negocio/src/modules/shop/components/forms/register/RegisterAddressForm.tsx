import type { FormEvent } from "react";
import { useState } from "react"
import { useParams } from "react-router-dom"
import { Modal } from "../../../../../shared/components/Modal"
import { MapSelector } from "../../../../ubication/components/MapSelector"
import { useGeoLocation } from "../../../../ubication/hooks/useGeoLocation"
import { getAddressByCoord } from "../../../../ubication/api"
import { registerAddress } from "../../../api";

export function RegisterAddressForm({onSuccess}:  {onSuccess: ()=> void}){

    const {shopId} = useParams<{shopId: string}>()
    const {coords, loading: loadingUbication } = useGeoLocation()
    const [mapOpen, setMapOpen] = useState(false)
    const [loading, setLoading] = useState(false)

    const [address, setAddress] = useState({
        direccion_calle: '',
        ciudad:'',
        estado:'',
        codigo_postal:'',
        pais:'México',
        latitud:0,
        longitud:0,
        osm_id:'',
        numero_local: '',
        numero_interior: '',
    
    })

    const [loadingAddress, setLoadingAddress] = useState(false)
    const [error, setError]= useState<string | null>(null)

    async function handleSubmit(e: FormEvent) {
        e.preventDefault()
        setError(null)

        if(
            !address.ciudad.trim() || 
            !address.direccion_calle.trim() || 
            !address.codigo_postal.trim() ||
            !address.estado.trim() ||
            !address.numero_local.trim ()
        ){
            setError('Hay campos incompletos')
            return
        }

        setLoading(true)
        
        try{
            const data = await registerAddress(Number(shopId), address)
            onSuccess()
        } catch (err){
            setError(err instanceof Error ? err.message : 'Error al registrar contacto.')
        } finally{
            setLoading(false)
        }

    }

    async function handleChangePosition(coords: {lat: number, lng: number}) {
        setLoadingAddress(true)
        setError(null)

        try{
            const dataGeo = await getAddressByCoord(coords.lat, coords.lng)
            setAddress({
                ...dataGeo,
                latitud: coords.lat,
                longitud: coords.lng
            })

        } catch (err){
            setError('No se pudo obtener la dirección. Intenta con otra ubicación.')
        } finally{
            setLoadingAddress(false)
        }
    }

    if(loadingUbication) return <p>Detectando tu ubicación...</p>

    return(
        <form className="mt-4" onSubmit={handleSubmit}>

            <button
            type="button"
            onClick={() => setMapOpen(true)}
            className="px-4 py-2 bg-primary text-white rounded-md 
            hover:bg-primary/90 transition-colors w-fit"
            >
                Seleccionar ubicación en el mapa
            </button>

            <div className="flex flex-col p-4 bg-card gap-4 mt-4 rounded-2xl shadow">
                <div className="flex flex-col gap-2">
                    <span className="text-3xl">Registro de Dirección</span>
                    <span className="text-secondary-text">
                        Ingresa los detalles de la dirección de tu negocio para mantener tu 
                        perfil actualizado
                    </span>

                    <div className="flex flex-col font-medium">
                        <label>Calle</label>
                        <input 
                        type="text" 
                        placeholder="Ej. Calle Francisco I. Madero"
                        className="px-3 py-2 rounded-md border border-gray-300
                        focus:outline-highlight"
                        value={address.direccion_calle}
                        onChange={
                            (e)=>(setAddress(
                                {...address, direccion_calle: e.target.value})
                            )
                        }
                        />
                    </div>

                    <div className="flex justify-between gap-4">
                        <div className="flex flex-col font-medium w-1/2">
                            <label>Ciudad</label>
                            <input 
                            type="text" 
                            placeholder="Ej. Ciudad de México"
                            className="px-3 py-2 rounded-md border border-gray-300
                            focus:outline-highlight"
                            value={address.ciudad}
                            onChange={
                                (e)=>(setAddress(
                                    {...address, ciudad: e.target.value})
                                )
                            }
                            />
                        </div>
                        <div className="flex flex-col font-medium w-1/2">
                            <label>Estado</label>
                            <input 
                            type="text" 
                            placeholder="Ej. Tlaxcala"
                            className="px-3 py-2 rounded-md border border-gray-300
                            focus:outline-highlight"
                            value={address.estado}
                            onChange={
                                (e)=>(setAddress(
                                    {...address, estado: e.target.value})
                                )
                            }
                            />
                        </div>
                    </div>

                    <div className="flex gap-4">
                        <div className="flex flex-col font-medium w-1/2">
                            <label>Código postal</label>
                            <input 
                            type="text" 
                            placeholder="Ej. 90410"
                            className="px-3 py-2 rounded-md border border-gray-300
                            focus:outline-highlight"
                            value={address.codigo_postal}
                            onChange={
                                (e)=>(setAddress(
                                    {...address, codigo_postal: e.target.value})
                                )
                            }
                            />
                        </div>

                        <div className="flex flex-col font-medium w-1/2">
                            <label>Número exterior</label>
                            <input 
                            type="text" 
                            className="px-3 py-2 rounded-md border border-gray-300
                            focus:outline-highlight"
                            value={address.numero_local}
                            onChange={
                                (e)=>(setAddress(
                                    {...address, numero_local: e.target.value})
                                )
                            }
                            />
                        </div>

                        <div className="flex flex-col font-medium w-1/2">
                            <label>Número interior (Opcional)</label>
                            <input 
                            type="text" 
                            className="px-3 py-2 rounded-md border border-gray-300
                            focus:outline-highlight"
                            value={address.numero_interior}
                            onChange={
                                (e)=>(setAddress(
                                    {...address, numero_interior: e.target.value})
                                )
                            }
                            />
                        </div>
                    </div>

                    {error && <p>{error}</p>}

                    <div className="flex justify-end mt-4">
                        <button 
                        disabled={loading}
                        className="px-6 py-2 bg-primary rounded-md text-card 
                        hover:bg-primary/90"
                        >
                            {loading ? 'Cargando...':'Guardar dirección'}
                        </button>
                    </div>
                </div>

            </div>

            <Modal
            isOpen={mapOpen}
            onClose={() => setMapOpen(false)}
            title="Selecciona la ubicación de tu negocio"
            >
                <MapSelector initialPosition={coords} onChangePosition={handleChangePosition} />

                {loadingAddress && 
                <p className="text-sm text-gray-500 mt-2">Obteniendo dirección...</p>
                }
                {error && <p className="text-sm text-red-500 mt-2">{error}</p>}

                <button
                type="button"
                onClick={() => setMapOpen(false)}
                className="mt-4 px-4 py-2 bg-primary text-white rounded-md 
                hover:bg-primary/90 transition-colors"
                >
                Confirmar ubicación
                </button>
            </Modal>
        </form>
    )
}