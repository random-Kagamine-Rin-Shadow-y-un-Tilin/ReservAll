import { Route } from "react-router-dom";
import { ForgotPasswordPage } from "../../modules/auth/pages/ForgotPasswordPage";
import { LoginPage } from "../../modules/auth/pages/LoginPage";
import { RegisterPage } from "../../modules/auth/pages/RegisterPage";
import { ResetPasswordPage } from "../../modules/auth/pages/ResetPasswordPage";

export const authRoutes = (
    <>
    <Route path='/login' element={<LoginPage/>}/>
    <Route path='/register' element={<RegisterPage/>}/>
    {/* HU_03: recuperación de contraseña */}
    <Route path='/forgot-password' element={<ForgotPasswordPage/>}/>
    <Route path='/reset-password' element={<ResetPasswordPage/>}/>
    </>
)