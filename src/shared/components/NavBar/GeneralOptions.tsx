import { NavItem } from "./NavItem";
import { IoStorefrontOutline , IoStorefront ,IoPerson, IoPersonOutline} from "react-icons/io5";
import { GoHistory } from "react-icons/go";

export function GeneralOptions(){
    return(
        <>
            <NavItem to="/shop" label="Locales" IconActive={IoStorefront} 
            IconInactive={IoStorefrontOutline}/>
            <NavItem to="/test" label="Mi perfil" IconActive={IoPerson} 
            IconInactive={IoPersonOutline}/>
            <NavItem to="/test2" label="Historial" IconActive={GoHistory} 
            IconInactive={GoHistory}/>
        </>
    )
}