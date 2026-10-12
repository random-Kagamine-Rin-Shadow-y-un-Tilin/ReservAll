import { NavItem } from "./NavItem"
import { IoCalendarOutline, IoCalendarSharp, IoListOutline, IoListSharp  } from "react-icons/io5";

export function LocalOptions(){
    return(
        <>
        <NavItem to="/my-services" end label="Servicios" IconActive={IoListSharp } 
        IconInactive={IoListOutline}/>
        <NavItem to="/agend" end label="Mi agenda" IconActive={IoCalendarSharp } 
        IconInactive={IoCalendarOutline}/>
        </>
    )
}