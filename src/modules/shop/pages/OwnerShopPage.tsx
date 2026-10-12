import { useParams } from "react-router-dom"
import { useState, useEffect } from "react"
import { getShopForId } from "../api"
import { GeneralShopInfo } from "../components/shopInfo/GeneralShopInfo"
import { ContactShopInfo } from "../components/shopInfo/ContactShopInfo"
import { AddressShopInfo } from "../components/shopInfo/AddressShopInfo"
import { ScheduleShopInfo } from "../components/shopInfo/ScheduleShopInfo"
import { getColorCategory } from "../utils/categoryStyle"
import type { ShopFullProfileOut } from "../types"

export function OwnerShopPage(){
    const { shopId } = useParams<{shopId : string }>()
    const [shop, setShop] = useState<ShopFullProfileOut | null>(null)
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState<string | null>(null)

    useEffect(()=>{
        if(!shopId) return

        async function loadShop() {
            try{
                const data = await getShopForId(shopId)
                setShop(data)
            }
            catch (err) {
                setError(err instanceof Error ? err.message : 'Error al cargar negocio.')
            } finally{
                setLoading(false)
            }
        } 

        loadShop()
    }, [shopId])


    if (loading) return <p>Cargando</p>
    if(error) return <p>{error}</p>
    if (!shop) return null
    const colorStyle = getColorCategory(shop.general.categoria_negocio)

    return(
        <div className="flex flex-col">
            <div className="flex justify-between items-center">
                <div className="flex flex-col">
                    <span className="font-medium text-4xl">Perfil de Negocio</span>
                    <span className="text-secondary-text">
                        Gestiona los detalles de tu negocio.
                    </span>
                </div>
            </div>

            <div className="mt-4 flex flex-col">
                 <span className={`border-b-4 ${colorStyle}
                    text-4xl font-medium`}>
                        General
                </span>
                <GeneralShopInfo shop={shop.general} />
            </div>
            
            <div className="mt-4 flex flex-col">
                <span className={`border-b-4 text-4xl font-medium ${colorStyle}`}>
                Contacto
                </span>
                <ContactShopInfo shop={shop.contacto}/>
            </div>

            <div className="mt-4 flex flex-col">
                <span className={`border-b-4 text-4xl font-medium ${colorStyle}`}>
                    Horarios
                </span>
                <ScheduleShopInfo shop={shop.horario} />
            </div>

            <div className="mt-4 flex flex-col">
                <span className={`border-b-4 text-4xl font-medium ${colorStyle}`}>
                    Direccion
                </span>
                <AddressShopInfo shop={shop.direccion}/>
            </div>
        </div>
    )
}