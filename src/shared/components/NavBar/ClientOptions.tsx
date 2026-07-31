import { NavItem } from "./NavItem"
import { IoIosHeartEmpty, IoIosHeart,  } from "react-icons/io"
import { IoFastFoodOutline, IoFastFoodSharp } from "react-icons/io5"

export function ClientOptions(){
    return(
        <>
        <NavItem to="/services" end label="Servicios" IconActive={IoIosHeart} 
        IconInactive={IoIosHeartEmpty}/>
        <NavItem to="/favorites" end label="Favoritos" IconActive={IoFastFoodSharp } 
        IconInactive={IoFastFoodOutline}/>
        </>
    )
}