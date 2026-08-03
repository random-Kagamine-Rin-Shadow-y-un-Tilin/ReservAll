import { Navigate } from "react-router-dom";
import type { ReactNode } from "react";
import { useAuth } from "../modules/auth/hooks/useAuth";

export function RouteProtect({children, requiredRol}: {children: ReactNode; requiredRol?: 'cliente' | 'negocio'}){
    const {user, loading} = useAuth()

    if(loading) return <p>cargando...</p>
    if(!user) return <Navigate to={'/login'} replace/>
    if (requiredRol && user.rol !== requiredRol) return <Navigate to={"/login"} replace/>

    return children
}