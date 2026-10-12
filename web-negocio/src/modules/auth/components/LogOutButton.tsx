import { useNavigate } from "react-router-dom";
import { useAuth } from "../hooks/useAuth";

export function LogOutButton(){
    const {logout} = useAuth()
    const navigate = useNavigate()

    async function handleLogOut() {
        await logout()
        navigate('/login')
    }

    return(
        <button onClick={handleLogOut} className="p-4">
            Cerrar sesión
        </button>
    )
}