import type { ShopContactInfo } from "../../types"
import { useState, useCallback } from "react"
import { useParams } from "react-router-dom"
import { RegisterContacForm } from "../forms/register/RegisterContactForm"
import { SocialComponent } from "../extra/SocialComponent"
import { getContactsByShop } from "../../api"
import { Modal } from "../../../../shared/components/Modal"

//ICON
import { LuPlus } from "react-icons/lu";

export function ContactShopInfo({shop}: {shop: ShopContactInfo[]}){
    const [registerModalOpen, setRegisterModalOpen] = useState(false)
    const [contacts, setContacts] = useState<ShopContactInfo[]>(shop)
    const {shopId} = useParams<{shopId: string}>()

    const updateContacts = useCallback(async ()=>{
        try{
            const data = await getContactsByShop(Number(shopId))
            setContacts(data)
        } catch(err){
            console.error("Error")
        }
    }, [shopId])

    async function handleSuccess() {
        setRegisterModalOpen(false)
        await updateContacts()
    }

    const myContacts = shop.map((c)=> c.nombre_red)

    return(
        <>
            <div className="flex flex-col mt-4">
                {contacts.length === 0 ?
                (
                    <>
                    <span className="font-light text-secondary-text">Aún no tienes información sobre tus contactos.</span>
                    <span className={`text-4xl font-medium`}>
                        Registra tu primera forma para contactarte.
                    </span>
                    <RegisterContacForm allMedia={myContacts} 
                    onSuccess={()=>handleSuccess()}
                    />
                    </>
                ):(
                    <>
                    <div className="flex justify-end gap-2">
                    {contacts.length < 7 && (
                        <button
                        type="button"
                        onClick={()=>setRegisterModalOpen(true)}
                        className="bg-primary text-white px-4 py-2 
                        rounded-md mb-4 hover:bg-primary/90 flex gap-2 items-center"
                        >   
                            <LuPlus/>
                            Añadir Contacto
                        </button>
                    )}
                    </div>
                    <div className="grid grid-cols-2 gap-2 bg-card p-4 rounded-2xl shadow">
                        {contacts.map(s =>(
                            <SocialComponent 
                            shop={
                                {
                                    id_negocio: 1, 
                                    nombre_red: s.nombre_red,
                                    url: s.url
                                }}
                            icon={`${s.nombre_red}`}
                            onSuccess={updateContacts}
                            />
                        ))}
                    </div>

                    <Modal
                    isOpen={registerModalOpen}
                    onClose={()=> setRegisterModalOpen(false)}
                    >
                        <RegisterContacForm allMedia={myContacts} 
                        onSuccess={()=> handleSuccess()}
                        />
                    </Modal>
                    </>
                )}
            </div>
        </>
    )
}