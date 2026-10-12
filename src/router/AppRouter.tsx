import { BrowserRouter, Routes, Route, useLocation, Navigate } from "react-router-dom";
import { App } from '../App'
import { RouteProtect } from "./RouteProtect";

//Import of Routes
import { authRoutes } from "./routes/auth.routes";
import { shopRoutes } from "./routes/shop.routes";


function Test(){
    return(
        <h2>Esta es una prueba</h2>
    )
}

function Test2(){
    return(
        <h2>Este es el test2</h2>
    )
}

function Services(){
    return(
        <h2>Servicios</h2>
    )
}

function RedirectRoot(){
    const location = useLocation()

    if (location.pathname === '/'){
        return <Navigate to='/shop' replace/>
    }

    return null
}

export function AppRouter(){
    return(
        <BrowserRouter>
        <RedirectRoot/>
            <Routes>
                {/* Routes without Layout */}
                {authRoutes}

                {/* Routes with Layout */}
                    <Route element={<App/>}>
                        {shopRoutes}
                        <Route path="/test" element={<Test/>}/>
                        <Route path="/test2" element={<Test2/>}/>
                        <Route path="/services" element={<Services/>}/>
                        <Route path="/favorites" element={<Services/>}/>
                        <Route path="/agend" element={<Services/>}/>
                        <Route path="/my-services" element={<Services/>}/>
                    </Route>
            </Routes>
        </BrowserRouter>
    )
}