import type { ReactNode } from "react";
import { IoClose } from "react-icons/io5";

interface ModalProps{
    isOpen: boolean
    onClose: () => void
    title?: string
    children: ReactNode
}

export function Modal({ isOpen, onClose, title, children }: ModalProps){
    if (!isOpen)return null

    return(
        <div
        className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4"
        onClick={onClose}
        >
            <div
            className="bg-background rounded-lg shadow-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto p-6"
            onClick={(e)=> e.stopPropagation()}
            >
                <div className="flex justify-between items-center mb-4">
                     {title && <h2 className="text-xl font-semibold">{title}</h2>}
                     <button onClick={onClose} className="text-gray-500 hover:text-gray-800">
                         <IoClose size={24} />
                     </button>
                </div>
                {children}
            </div>

        </div>
    )
}