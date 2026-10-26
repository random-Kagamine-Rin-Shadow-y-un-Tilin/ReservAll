import { useState } from "react"
import type { FormEvent } from "react"

import type { ShopContactEdit } from "../../../types"

export function EditContactForm({contact, onSuccess}: 
    {contact: ShopContactEdit, onSuccess?: ()=> void}){
    
    const[editContact, setEditContact] = useState<ShopContactEdit>(contact)

    const [loading] = useState(false)
    const [error] = useState<string | null>(null)

    async function handleSubmit(event: FormEvent) {
        event.preventDefault()
        onSuccess?.()
    }

    const socialMedia = [
        'facebook',
        'instagram',
        'whatsapp',
        'telefono',
        'tiktok',
        'x',
        'sitio_web',
    ]

    return <form onSubmit={handleSubmit} 
        className="flex flex-col justify-center mt-4 gap-3 p-4 bg-card shadow rounded-2xl"
        >
            <span className="text-3xl">Edicion de Contacto</span>

            <div className="flex flex-col justify-center">
                <label>Red social</label>
                <select value={contact.nombre_red} 
                onChange={(e)=>{setEditContact({...editContact, nombre_red: e.target.value})}}
                    className="px-3 py-2 bg-card border rounded-md">
                    <option value="" disabled>Selecciona una red social</option>
                    {socialMedia.map((social)=>(
                       (<option key={social} value={social}>
                        {social === 'sitio_web' ? ('Sitio web'):(social)}
                       </option>) 
                    ))}
                </select>
            </div>

            <div className="flex flex-col justify-center">
                <label>Ingresa número o url.</label>
                <input type="text" onChange={(e)=>{setEditContact({...editContact, url: e.target.value})}}
                placeholder="Ej. https/instagram/mi-media"
                value={editContact.url}
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
}