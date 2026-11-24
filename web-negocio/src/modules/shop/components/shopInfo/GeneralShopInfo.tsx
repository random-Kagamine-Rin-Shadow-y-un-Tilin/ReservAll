import type { ShopGeneralInfo } from "../../types";
import { EditGeneralForm } from "../forms/edit/EditGeneralForm";
import { getGeneral } from "../../api";
import { Modal } from "../../../../shared/components/Modal";
import { useState, useCallback } from "react";
import { useParams } from "react-router-dom";
import { LuPencil } from "react-icons/lu";

export function GeneralShopInfo({shop}: {shop:ShopGeneralInfo},){

    const[editModalOpen, setEditModalOpen] = useState(false)
    const[generalInfo, setGeneralInfo] = useState<ShopGeneralInfo>(shop)
    const {shopId} = useParams<{shopId: string}>()

    const updateInfo = useCallback(async()=>{
        try{
            const data = await getGeneral(Number(shopId))
            setGeneralInfo(data)
        } catch(err){
            console.error("Error")
        }
    },[shopId])

    async function handleSuccess() {
        setEditModalOpen(false)
        await updateInfo()
    }

    return(
        <>
        <div className="mt-4 flex justify-end">
            <button className='flex items-center gap-3 bg-background p-2
            rounded-md text-primary border-2 border-primary hover:bg-primary
            hover:text-foreground transition-colors'
            onClick={()=>setEditModalOpen(true)}
            >
                Editar Información
                <LuPencil/>
            </button>
        </div>

        <div className="p-4 bg-card rounded-2xl shadow mt-4">
            <div className="flex mt-4 justify-between">
                <div className="flex flex-col gap-3">
                    <div className="flex flex-col">
                        <span className="text-3xl font-medium">Nombre</span>
                        <span className="text-secondary-text font-light">{generalInfo.nombre}</span>
                    </div>
                    <div className="flex flex-col">
                        <span className="text-3xl font-medium">Categoría</span>
                        <span className="text-secondary-text font-light">
                            {generalInfo.categoria_negocio}
                        </span>
                    </div>
                </div>

                <div className="flex flex-col justify-items-start w-1/2 gap-3">
                    <div className="flex flex-col">
                        <span className="text-3xl font-medium">Descripción</span>
                        <span className="text-secondary-text font-light">{generalInfo.descripcion}</span>
                    </div>
                    <div className="flex flex-col">
                        <span className="text-3xl font-medium">Imágen</span>
                        {generalInfo.imagen_negocio === 'null' ? (
                            <span className="text-secondary-text">No hay imagen disponible</span>
                        ): (
                            <img src={generalInfo.imagen_negocio} alt="Imagen negocio" 
                            className="w-32 h-32"/>
                        )} 
                    </div>
                </div>
            </div>

        </div>

        <Modal
        isOpen={editModalOpen}
        onClose={()=> setEditModalOpen(false)}
        title="Editar información general"
        >
            <EditGeneralForm shop={generalInfo} onSuccess={()=>handleSuccess()}/>
        </Modal>
        </>
    )
}