import { Route } from "react-router-dom";
import { LoginPage } from "../../modules/auth/pages/LoginPage";
import { RegisterPage } from "../../modules/auth/pages/RegisterPage";

export const authRoutes = (
    <>
    <Route path='/login' element={<LoginPage/>}/>
    <Route path='/register' element={<RegisterPage/>}/>
    </>
)