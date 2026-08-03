import { NavItem } from "./NavItem";
import { IoStorefrontOutline , IoStorefront ,IoPerson, IoPersonOutline} from "react-icons/io5";
import { GoHistory } from "react-icons/go";

export function GeneralOptions(){
    return(
        <>
            <NavItem to="/" end label="Locales" IconActive={IoStorefront} 
            IconInactive={IoStorefrontOutline}/>
            <NavItem to="/test" end label="Mi perfil" IconActive={IoPerson} 
            IconInactive={IoPersonOutline}/>
            <NavItem to="/test2" end label="Historial" IconActive={GoHistory} 
            IconInactive={GoHistory}/>
        </>
    )
}