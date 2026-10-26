import type { FormEvent } from "react";
import { useState } from "react";
import { useParams } from "react-router-dom";
import { registerContact } from "../../../api";

export function RegisterContacForm( 
    {allMedia, onSuccess} : {allMedia: string[], onSuccess: ()=> void} 
){
    const socialMedia = [
        'facebook',
        'instagram',
        'whatsapp',
        'telefono',
        'tiktok',
        'x',
        'sitio_web',
    ]

    const [socialName, setSocailName] = useState<string>('')
    const [url, setUrl] = useState<string>('')

    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)

    const {shopId} = useParams<{shopId: string}>()

    async function handleSubmit(e:FormEvent) {
        e.preventDefault()
        setError(null)

        if(!url.trim() || !socialName.trim()){
            setError('Todos los campos son obligatorios.')
        }

        if (!socialName) {
            setError('Selecciona una red social.')
            return
        }

        setLoading(true)

        try{
            await registerContact(Number(shopId), {
                nombre_red: socialName,
                url: url
            })
            onSuccess()
        } catch (err){
            setError(err instanceof Error ? err.message : 'Error al registrar contacto.')
        } finally{
            setLoading(false)
        }
    }

    return(
        <form onSubmit={handleSubmit} 
        className="flex flex-col justify-center mt-4 gap-3 p-4 bg-card shadow rounded-2xl"
        >
            <span className="text-3xl">Registro de Contacto</span>

            <div className="flex flex-col justify-center">
                <label>Red social</label>
                <select value={socialName} onChange={(e)=>{setSocailName(e.target.value)}}
                    className="px-3 py-2 bg-card border rounded-md">
                    <option value="" disabled>Selecciona una red social</option>
                    {socialMedia.map((social)=>(
                       !allMedia.includes(social) &&
                       (<option key={social} value={social}>
                        {social === 'sitio_web' ? ('Sitio web'):(social)}
                       </option>) 
                    ))}
                </select>
            </div>

            <div className="flex flex-col justify-center">
                <label>Ingresa número o url.</label>
                <input type="text" onChange={(e)=>{setUrl(e.target.value)}}
                placeholder="Ej. https/instagram/mi-media"
                className="px-3 py-2 bg-card border rounded-md"/>
            </div>

            {error && <p>{error}</p>}

            <div className="flex justify-end">
                <button type="submit" className="w-max px-4 py-2 bg-primary 
                rounded-md hover:bg-primary/90 text-white" disabled={loading}>
                    {loading? (<p>Cargando...</p>):(<p>Guardar contacto</p>)}
                </button>
            </div>
        </form>
    )
 }