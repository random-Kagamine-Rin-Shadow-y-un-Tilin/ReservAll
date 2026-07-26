import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import type { ReactNode } from "react"
import { useAuth } from "../modules/auth/hooks/useAuth";
import { LoginPage } from "../modules/auth/pages/LoginPage";
import { RegisterPage } from "../modules/auth/pages/RegisterPage";
import { App } from '../App'

//Esto es temporal:
import { LogOutButton } from "../modules/auth/components/LogOutButton";
import { TestComponent } from "../modules/auth/components/TestComoponent";

function RouteProtect({children, requiredRol}: {children: ReactNode; requiredRol?: 'cliente' | 'negocio'}){
    const {user, loading} = useAuth()

    if(loading) return <p>cargando...</p>
    if(!user) return <Navigate to={'/login'} replace/>
    if (requiredRol && user.rol !== requiredRol) return <Navigate to={"/"} replace/>

    return children
}

function InicioPage() {
    return (
        <>
        <TestComponent/>
        <LogOutButton/>
        </>
    )
}

function Test(){
    return(
        <h2>Esta es una prueba</h2>
    )
}

export function AppRouter(){
    return(
        <BrowserRouter>
            <Routes>
                {/* Routes without Layout */}
                <Route path="/login" element={<LoginPage/>}/>
                <Route path="/register" element={<RegisterPage/>}/>

                {/* Routes with Layout */}
                <Route element={<App/>}> 
                    <Route path="/" element={<InicioPage/>} />
                    <Route path="/test" element={<Test/>}/>
                </Route>
            </Routes>
        </BrowserRouter>
    )
}