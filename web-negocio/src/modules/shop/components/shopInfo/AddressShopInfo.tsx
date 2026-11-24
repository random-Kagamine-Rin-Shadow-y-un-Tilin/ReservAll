import { RegisterAddressForm } from "../forms/register/RegisterAddressForm"
import { useCallback, useState } from "react";
import { useParams } from "react-router-dom";
import { CiLocationOn } from "react-icons/ci";
import { getAddress } from "../../api";
import { LuPencil } from "react-icons/lu";
import type { ShopAddressInfo } from "../../types"

interface AddressShopInfoProps {
  shop: ShopAddressInfo | null
}

export function AddressShopInfo({shop}: AddressShopInfoProps){

    const {shopId} = useParams<{shopId: string}>()
    const [address, setAddress] = useState<ShopAddressInfo | null>(shop)

    const updateAddress = useCallback(async ()=>{
        try{
            const data = await getAddress(Number(shopId))
            setAddress(data)
        } catch(err){
            console.error("Error")
        }
    }, [shopId])

    async function handleSuccess() {
        await updateAddress()
    }
    
    return(    
        <>
        {address === null ?(
            <RegisterAddressForm onSuccess={()=> handleSuccess()}/>
        ):(
            <>
            <div className="mt-4 flex justify-end">
                <button className='flex items-center gap-3 bg-background p-2
                rounded-md text-primary border-2 border-primary hover:bg-primary
                hover:text-foreground transition-colors'>
                    Editar Información
                    <LuPencil/>
                 </button>
            </div>
            <div className="p-4 bg-card rounded-2xl shadow flex flex-col gap-4 mt-4">
                <div className="flex gap-2 items-center text-2xl">
                    <CiLocationOn 
                    className="text-primary p-2 bg-primary/20 rounded-4xl text-5xl"
                    />
                    <span>
                        Esta dirección se mostrara públicamente en tu perfil.
                    </span>
                </div>

                <div className="flex flex-col gap-4">
                    <div className="flex flex-col">
                        <span className="text-secondary-text font-medium text-sm">
                            Calle
                        </span>
                        <span>{address.direccion_calle}</span>
                    </div>

                    <div className="grid grid-cols-2">
                        <div className="flex flex-col">
                            <span className="text-secondary-text font-medium text-sm">
                                Número exterior
                            </span>
                            <span>{address.numero_local}</span>
                        </div>

                        <div className="flex flex-col">
                            <span className="text-secondary-text font-medium text-sm">
                                Número Interior
                            </span>
                            <span>
                            {address.numero_interior? 
                            (address.numero_interior):
                            ("Sin número")}
                            </span>
                        </div>
                    </div>

                    <div className="grid grid-cols-2">
                        <div className="flex flex-col gap-2">
                            <span className="text-secondary-text font-medium text-sm">
                                Código Postal
                            </span>
                            <span>{address.codigo_postal}</span>
                        </div>

                        <div className="flex flex-col gap-2">
                            <span className="text-secondary-text font-medium text-sm">
                                Ciudad
                            </span>
                            <span>{address.ciudad}</span>
                        </div>
                    </div>

                    <div className="grid grid-cols-2">
                        <div className="flex flex-col">
                            <span className="text-secondary-text font-medium text-sm">
                                Estado
                            </span>
                            <span>{address.estado}</span>
                        </div>

                        <div className="flex flex-col">
                            <span className="text-secondary-text font-medium text-sm">
                                País
                            </span>
                            <span>{address.pais}</span>
                        </div>
                    </div>
                </div>
            </div>
            </>
        )}
        </>   
        )   
}