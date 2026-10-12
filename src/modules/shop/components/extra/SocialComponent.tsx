import { useState } from "react";
import { MdLocalPhone } from "react-icons/md";
import { IoLogoTiktok } from "react-icons/io5";
import { TbLetterX } from "react-icons/tb";
import { ImSphere } from "react-icons/im";
import { IoLogoFacebook, IoLogoInstagram, IoLogoWhatsapp, } from "react-icons/io";
import { Modal } from "../../../../shared/components/Modal";
import { EditContactForm } from "../forms/edit/EditContactForm";
import type { ShopContactEdit } from "../../types";
import { LuPencil , LuTrash2 } from "react-icons/lu";

const icons = { 
        facebook: IoLogoFacebook,
        instagram: IoLogoInstagram,
        whatsapp: IoLogoWhatsapp,
        telefono: MdLocalPhone,
        tiktok: IoLogoTiktok,
        x: TbLetterX,
        sitio_web : ImSphere,
    }

    type IconName = keyof typeof icons;

    interface SocialComponentProps {
        shop: ShopContactEdit
        icon: IconName
        onSuccess: () => Promise<void>
    }


export function SocialComponent({shop, icon, onSuccess} : SocialComponentProps){
    const Icon = icons[icon]
     const [editModalOpen, setEditModalOpen] = useState(false)

     async function handleSuccess() {
        setEditModalOpen(false)
        await onSuccess()
    }

    return(
        <div key={shop.nombre_red} className="flex flex-col">
            <div className="flex gap-2 items-center text-[1.3rem]">
                <Icon className="text-primary"/>
                <span className="font-medium">{shop.nombre_red}</span>
            </div>

            <div 
            className="px-4 py-2 rounded-md border border-foreground flex 
            items-center justify-between"
            >
                <a href={shop.url} className="line-clamp-1">
                    {shop.url}
                </a>

                <div className="flex items-center gap-2">
                    <LuPencil 
                    className="cursor-pointer text-primary hover:text-primary/90"
                    onClick={()=>setEditModalOpen(true)}
                    />
                    <LuTrash2
                    className="cursor-pointer text-error hover:text-error/90"
                    />
                </div>
            </div>

            <Modal
                isOpen={editModalOpen}
                onClose={()=>setEditModalOpen(false)}
            >
                <EditContactForm contact={shop} onSuccess={handleSuccess}/>
            </Modal>
        </div>
    )

}
