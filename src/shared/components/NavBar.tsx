import { GeneralOptions } from "./NavBar/GeneralOptions"
import { ClientOptions } from "./NavBar/ClientOptions"
import { LocalOptions } from "./NavBar/LocalOptions"

export function NavBar({ rol }: {rol: string}){

    return(
        <nav className="h-screen bg-background w-min flex flex-col border-r 
        border-gray-300">
            <label className="text-[#9f402d] font-medium text-3xl p-8">LOGOTIPO</label>

            <div className="flex flex-col h-full justify-between">
                <div className="flex flex-col gap-0.5 font-medium">
                    <GeneralOptions/>
                    {rol === 'negocio'? 
                    <LocalOptions/>
                    : 
                    <ClientOptions/>
                    }
                </div>

                <div>
                    Otro elemento
                </div>
            </div>
        </nav>
    )
} 