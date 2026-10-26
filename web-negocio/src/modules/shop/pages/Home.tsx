import { useAuth } from "../../auth/hooks/useAuth";
import { OwnerShopList } from "../components/OwnerShopList";

export function Home(){
    const {user} = useAuth()

    if(user?.rol === 'negocio') return(
        <div className="flex flex-col gap-8">
            <OwnerShopList/>
        </div>
    ) 

    return <p>Para clientes</p>
}