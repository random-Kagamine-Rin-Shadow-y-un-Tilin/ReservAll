import { useState } from "react"
import { useNavigate } from "react-router-dom";
import type { FormEvent, ChangeEvent } from "react";
import { registerShop, uploadShopImage } from "../../../api"
import { CiTextAlignJustify } from "react-icons/ci";
import { PiTextAa } from "react-icons/pi";

const CATEGORIES = [
    {'nombre': 'Barberia', 'id': 1},
    {'nombre': 'Spa', 'id': 2},
    {'nombre': 'Restaurante', 'id': 3},
    {'nombre': 'Belleza', 'id': 4},
    {'nombre': 'Otro', 'id': 5},
]

export function ShopRegisterForm(){
    const navigate = useNavigate()

    const [name, setName] = useState('')
    const [description, setDescription] = useState('')
    const [category, setCategory] = useState<number>(1)
    const [fileImage, setFileImage] = useState<File | null>(null)
    const [previewUrl, setPreviewUrl] = useState<string | null> (null)

    const [error, setError] = useState<string | null>(null)
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

        if (!name.trim() || !description.trim() || !category){
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

            navigate(`/shop/${shop.id}`)
        } catch (err){
            setError(err instanceof Error ? err.message : 'Error al registrar negocio.')
        } finally{
            setLoading(false)
        }
    }

    return( 
        <form onSubmit={handleSubmit} 
        className="flex flex-col gap-4 p-4 bg-card rounded-2xl shadow"
        >
            <h2 className="text-4xl font-medium">Registrar negocio</h2>

            <div className="flex flex-col gap-1">
                <label>Nombre de negocio</label>
                <div className="flex items-center gap-2 px-3 py-2 border rounded-md 
                    border-gray-300 focus-within:border-highlight transition-colors">
                    <PiTextAa className="w-6 h-6"/>
                    <input 
                    type="text"
                    value={name}
                    onChange={(e)=> setName(e.target.value)}
                    placeholder="Ej. Cafeteria Jaimito"
                    className="w-full focus:outline-none"
                    />
                </div>
            </div>

            <div className="flex flex-col gap-1">
                <label>Descripción</label>
                <div className="flex items-center gap-2 px-3 py-2 border rounded-md 
                    border-gray-300 focus-within:border-highlight transition-colors">
                    <textarea 
                    value={description}
                    onChange={(e)=> setDescription(e.target.value)}
                    placeholder="Agrega una descripción para el negocio."
                    className="resize-none w-full focus:outline-none"
                    />
                </div>
            </div>

            <div className="flex flex-col gap-1">
                <label>Categoria de negocio</label>
                <div className="flex items-center gap-2 px-3 py-2 border rounded-md 
                    border-gray-300 focus-within:border-highlight transition-colors">
                    <CiTextAlignJustify/>
                    <select 
                    value={category}
                    onChange={(e)=> setCategory(Number(e.target.value))}
                    className="w-full focus:outline-none"
                    >
                        <option value="">Selecciona una categoria</option>
                        {CATEGORIES.map((cat)=>(
                            <option key={cat.id} value={cat.id}>{cat.nombre}</option>
                        ))}
                    </select>
                </div>
            </div>

            <div className="flex flex-col gap-2">
                <label>Imagen del negocio</label>
                
                <div className="flex items-center gap-4">
                    <label 
                    htmlFor="shop-image"
                    className="cursor-pointer px-4 py-2 bg-primary text-white rounded-md
                    hover:bg-primary/90 transition-colors whitespace-nowgrap"
                    >
                        Seleccionar imagen
                    </label>
                    <input
                    id='shop-image'
                    type="file"
                    accept="image/jpeg,image/png,image/webp"
                    onChange={handleFileChange}
                    className="hidden"
                    />

                    {previewUrl ? (
                        <img 
                        src={previewUrl} 
                        alt="Vista previa"
                        className="w-16 h-16 object-cover rounded-md border"
                        />
                    ):(
                        <span className="text-gray-500 text-sm">
                            Sin imagen seleccionada
                        </span>
                    )}

                </div>
            </div>

            {error && <p>{error}</p>}

            <button type="submit" disabled={loading} className="w-max px-4 py-2 bg-primary 
            rounded-md hover:bg-primary/90 text-white">
                {loading ? 'Registrando...':'Registrar negocio'}
            </button>

        </form>
    )
}