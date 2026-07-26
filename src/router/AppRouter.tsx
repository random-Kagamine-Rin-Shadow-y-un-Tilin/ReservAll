import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import type { ReactNode } from "react"
import { useAuth } from "../modules/auth/hooks/useAuth";
import { LoginPage } from "../modules/auth/pages/LoginPage";
import { RegisterPage } from "../modules/auth/pages/RegisterPage";
import { App } from '../App'

function RouteProtect({children, requiredRol}: {children: ReactNode; requiredRol?: 'cliente' | 'negocio'}){
    const {user, loading} = useAuth()

    if(loading) return <p>cargando...</p>
    if(!user) return <Navigate to={'/login'} replace/>
    if (requiredRol && user.rol !== requiredRol) return <Navigate to={"/"} replace/>

    return children
}

export function AppRouter(){
    return(
        <BrowserRouter>
            <Routes>
                <Route path="/login" element={<LoginPage/>}/>
                <Route path="/register" element={<RegisterPage/>}/>
                <Route path="/" element={<App/>} />
            </Routes>
        </BrowserRouter>
    )
}