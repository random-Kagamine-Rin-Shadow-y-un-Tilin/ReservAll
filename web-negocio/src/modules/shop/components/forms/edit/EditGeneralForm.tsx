import { useState } from "react";
import { useParams } from "react-router-dom";
import { uploadShopImage, editShop } from "../../../api";
import type { ShopGeneralInfo } from "../../../types";
import type { FormEvent, ChangeEvent } from "react";

export function EditGeneralForm(
    {shop, onSuccess}: {shop: ShopGeneralInfo, onSuccess: ()=> void})
    {
    const {shopId} = useParams<{shopId: string}>()
    const[editGeneral, setEditGeneral] = useState<ShopGeneralInfo>(shop)
    const[previewUrl, setPreviewUrl] = useState<string | null> (null)
    const[fileImage, setFileImage] = useState<File | null>(null)

    const[loading, setLoading] = useState(false)
    const[error, setError] = useState<string | null>(null)

    const CATEGORIES = [
    {'nombre': 'Barberia', 'id': 1},
    {'nombre': 'Spa', 'id': 2},
    {'nombre': 'Restaurante', 'id': 3},
    {'nombre': 'Belleza', 'id': 4},
    {'nombre': 'Otro', 'id': 5},]

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
    
        if (
            !editGeneral.nombre.trim() || 
            !editGeneral.descripcion.trim() ||
             !editGeneral.categoria_negocio
            ){
            setError('Nombre, descripción y categoria son obligatorios.')
            return
        }
    
        setLoading(true)
        try{
            let urlImage : string | undefined
    
            if (fileImage){
                urlImage = await uploadShopImage(fileImage)
            }
    
            await editShop(
                {
                    nombre: editGeneral.nombre,
                    descripcion: editGeneral.descripcion,
                    imagen_negocio: urlImage,
                    fk_categoria: editGeneral.id_categoria
                }, 
                Number(shopId))
                onSuccess()
    
        } catch (err){
            setError(err instanceof Error ? err.message : 'Error al registrar negocio.')
        } finally{
            setLoading(false)
        }
    }

    return(
        <form onSubmit={handleSubmit} className="bg-card p-4 shadow rounded-2xl gap-2">
            <div className="flex flex-col gap-1">
                <label className="font-medium">Nombre de neogcio</label>
                <input 
                type="text" 
                value={editGeneral.nombre}
                className="px-3 py-2 focus:outline-highlight border border-gray-300
                rounded-md"
                onChange={(e)=>(setEditGeneral({...editGeneral, nombre: e.target.value}))}
                />
            </div>

            <div className="flex flex-col gap-1">
                <label className="font-medium">Descripción</label>
                <textarea 
                value={editGeneral.descripcion}
                onChange={
                    (e)=>{setEditGeneral({...editGeneral, descripcion: e.target.value})
                }}
                className="px-3 py-2 focus:outline-highlight border border-gray-300
                rounded-md resize-none"
                />
            </div>

            <div className="flex flex-col gap-1">
                <label className="font-medium">Categoría</label>
                <select 
                value={editGeneral.id_categoria}
                onChange={(e)=>{
                    setEditGeneral({...editGeneral, id_categoria: Number(e.target.value)})
                }}
                className="px-3 py-2 focus:outline-highlight border border-gray-300
                rounded-md"
                >
                    <option disabled>Selecciona una categoria</option>
                    {CATEGORIES.map((cat)=>(
                        <option key={cat.id} value={cat.id}>{cat.nombre}</option>
                    ))}
                </select>
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

                    {editGeneral.imagen_negocio !== 'null' && (
                        <div className="flex flex-col">
                            <span>Imágen actual</span>
                            <img 
                            src={editGeneral.imagen_negocio} 
                            alt="Vista previa"
                            className="w-16 h-16 object-cover rounded-md border"
                            />
                        </div>
                    )}

                    {previewUrl ? (
                        <div className="flex flex-col">
                            <span>Nueva imágen</span>
                            <img 
                            src={previewUrl} 
                            alt="Vista previa"
                            className="w-16 h-16 object-cover rounded-md border"
                            />
                        </div>
                    ):(
                        <span className="text-gray-500 text-sm">
                            Sin nueva imagen seleccionada
                        </span>
                    )}

                </div>
            </div>

            {error && <p>{error}</p>}

            <div className="flex justify-end">
                <button type="submit" disabled={loading} className="w-max px-4 py-2 bg-primary 
                rounded-md hover:bg-primary/90 text-white">
                    {loading ? 'Registrando...':'Editar infromación'}
                </button>
            </div>
        </form>
    )
}