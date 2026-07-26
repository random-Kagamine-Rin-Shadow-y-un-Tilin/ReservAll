import { useAuth } from "../hooks/useAuth";
export function TestComponent(){
    const {user} = useAuth()
    console.log(user)
    return(
        <div>
            {user === null? <p>No hay usuario</p> : <p>Bienvenido: {user.nombre}</p>}
        </div>
    )
}