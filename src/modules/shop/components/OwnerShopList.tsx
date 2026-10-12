import { useState, useEffect } from "react"
import { Link } from "react-router-dom"
import { getOwnerShops } from "../api"
import { getCategoryStyle } from "../utils/categoryStyle"
import { ImageSustitutionForList } from "./ImageSustitutionForList"
import { GoArrowRight } from "react-icons/go";
import { FaShop } from "react-icons/fa6";
import type { ShopGeneralInfo } from "../types"

export function OwnerShopList(){
    const [shops, setShops] = useState<ShopGeneralInfo[]>([])
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState<string| null>(null)

    useEffect(()=>{
        async function loadShops() {
            try {
                const data = await getOwnerShops()
                setShops(data)
            } catch (err){
                setError(err instanceof Error ? err.message : 'Error al cargar tus negocios.')
            } finally {
                setLoading(false)
            }
        }

        loadShops()
    },[])

    if (loading) return <p>Cargando tus negocios</p>
    if (error) return <p>{error}</p>
    if (shops.length === 0){
        return(
            <div className="flex flex-col gap-3 justify-between h-full">
                <div className="flex flex-col gap-2">
                    <span className="text-4xl">Sin negocios registrados</span>
                    <Link to="/shop/register"
                    className="px-3 py-2 bg-primary rounded-md w-max 
                    text-card hover:bg-primary/90"
                    >
                        Resgitrar mi primer negocio
                    </Link>
                </div>

                <div className="flex flex-col justify-center items-center text-center py-12">
                    <FaShop className="text-9xl"/>
                    <span className="text-3xl">No hay negocios por mostrar</span>
                </div>
            </div>
        )
    }

    return(
        <>
        <div className="flex flex-col gap-4">
            <span className="text-4xl">Tus negocios</span>
            <Link to='/shop/register'
            className="px-3 py-2 bg-primary rounded-md w-max text-card 
            hover:bg-primary/90"
            >
                Registrar un negocio
            </Link>
        </div>
        <div className="grid grid-cols-1 gap-4 w-full">
        {shops.map((shop) => (
            <div className="flex rounded-md bg-card shadow" key={shop.id}>
                {shop.imagen_negocio !== 'null' ? 
                <img src={shop.imagen_negocio} alt="Imagen del negocio"
                className="h-[200px] w-[200px] rounded-bl-md rounded-tl-md"
                />:
                <ImageSustitutionForList category={shop.categoria_negocio}/>
                }
                <div className="p-3 flex flex-col w-full justify-between">
                    <div className="flex justify-between">
                        <span className="font-medium text-2xl">{shop.nombre}</span>
                        <span 
                        className={`px-3 py-1 rounded-4xl text-center ${getCategoryStyle(shop.categoria_negocio)}`}
                        >
                            {shop.categoria_negocio}
                        </span>
                    </div>
                    <div>
                        <span 
                        className="text-secondary-text "
                        >
                            {shop.descripcion}
                        </span>
                    </div>
                    <Link to={`/shop/${shop.id}`} className="flex justify-end items-center gap-2 text-primary">
                    Ver detalles
                    <GoArrowRight/>
                    </Link>
                </div>
            </div>
        ))}
        </div>
        </>
    )
}