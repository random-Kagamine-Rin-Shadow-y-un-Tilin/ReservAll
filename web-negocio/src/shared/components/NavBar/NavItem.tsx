import { NavLink } from "react-router-dom";
import type { IconType } from "react-icons";

interface NavItemsProps{
    to: string
    label: string
    IconActive: IconType
    IconInactive: IconType
    end?: boolean
}

export function NavItem({to, label, IconActive, IconInactive, end}: NavItemsProps){
    return(
        <NavLink 
        to={to}
        end={end}
        className={({isActive})=>
        `py-3 px-4 flex items-center gap-2 
        ${isActive? 'bg-primary/10 border-r-2 border-[#9F402D] text-[#9F402D]': 
        'hover:bg-secondary/10 hover:text-secondary'}`
        }
        >
            {({isActive})=>(
                <>
                {isActive? <IconActive size={20}/>: <IconInactive size={20}/>}
                <span className="cursor-pointer">{label}</span>
                </>
            )}
        </NavLink>
    )
}