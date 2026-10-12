import { GeneralOptions } from "./NavBar/GeneralOptions"
import { LocalOptions } from "./NavBar/LocalOptions"

export function NavBar(){
    return(
        <nav className="h-screen bg-card w-min flex flex-col border-r 
        border-gray-300">
            <label className="text-[#9f402d] font-medium text-3xl p-8">CYTAFY</label>

            <div className="flex flex-col h-full justify-between">
                <div className="flex flex-col gap-0.5 font-medium">
                    <GeneralOptions/>
                    <LocalOptions/>
                </div>
            </div>
        </nav>
    )
}