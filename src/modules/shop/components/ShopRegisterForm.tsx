import { useState } from "react"
import { useNavigate } from "react-router-dom";
import type { FormEvent, ChangeEvent } from "react";
import { registerShop, uploadShopImage } from "../api"

const CATEGORIES = ['Barberia', 'Spa', 'Restaurante', 'Belleza', 'Otro']

export function ShopRegisterForm(){
    const navigate = useNavigate()

    const [name, setName] = useState('')
    const [description, setDescription] = useState('')
    const [category, setCategory] = useState('')
    const [fileImage, setFileImage] = useState<File | null>(null)
    const [previewUrl, setPreviewUrl] = useState<string | null> (null)

    const [error, setError] = useState<String | null>(null)
    const [loading, setLoading] = useState(false)

    function handleFileChange(e: ChangeEvent<HTMLInputElement>){
        const file = e.target.files?.[0]
        if(!file) return

        if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type)){
            setError('Formato de imagen no permitido (usa JPG, PNG o WEBP).')
            return
        }

        if (file.size > 5 * 1024 * 1024){
            setError('La imagen no debe superar los 5MB.')
            return
        }

        setError(null)
        setFileImage(file)
        setPreviewUrl(URL.createObjectURL(file)) // Preview wiev of image
    }

    async function handleSubmit(e:FormEvent) {
        e.preventDefault()
        setError(null)

        if (!name.trim() ||! description.trim() || !category){
            setError('Nombre, descripción y categoria son obligatorios.')
            return
        }

        setLoading(true)
        try{
            let urlImage : string | undefined

            if (fileImage){
                urlImage = await uploadShopImage(fileImage)
            }

            const shop = await registerShop({
                nombre: name.trim(),
                descripcion: description.trim(),
                imagen_negocio: urlImage,
                categoria_negocio: category,
            })

            navigate('/')
        } catch (err){
            setError(err instanceof Error ? err.message : 'Error al registrar negocio.')
        } finally{
            setLoading(false)
        }
    }

    return( 
        <form onSubmit={handleSubmit}>
            <h2>Registrar negocio</h2>

            <div>
                <label>Nombre del negocio</label>
                <input 
                type="text"
                value={name}
                onChange={(e)=> setName(e.target.value)}
                />
            </div>

            <div>
                <label>Descripción</label>
                <textarea 
                value={description}
                onChange={(e)=> setDescription(e.target.value)}
                rows={3}
                />
            </div>

            <div>
                <label>Categoria de negocio</label>
                <select 
                value={category}
                onChange={(e)=> setCategory(e.target.value)}
                >
                    <option value="">Selecciona una categoria</option>
                    {CATEGORIES.map((cat)=>(
                        <option key={cat} value={cat.toLowerCase()}>{cat}</option>
                    ))}
                </select>
            </div>

             <div>
                <label>Imagen del negocio</label>
                <input 
                type="file"
                accept="image/jpeg,image/png,image/webp"
                onChange={handleFileChange} 
                />

                {previewUrl && (
                    <img src={previewUrl} alt="Vista previa"/>
                )}
            </div>

            {error && <p>{error}</p>}

            <button type="submit" disabled={loading}>
                {loading ? 'Registrando...':'Registrar negocio'}
            </button>

        </form>
    )
}