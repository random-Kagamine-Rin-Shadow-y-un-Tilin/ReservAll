import { Route } from "react-router-dom";
import { TestComponent } from "../../modules/auth/components/TestComoponent";
import { LogOutButton } from "../../modules/auth/components/LogOutButton";

//Imports de pagina
import { RegisterShopPage } from "../../modules/shop/pages/RegisterShopPage";

function InicioPage() {
    return (
        <>
        <TestComponent/>
        <LogOutButton/>
        </>
    )
}

export const shopRoutes = (
    <>
    <Route path="/" element={<InicioPage/>}/>
    <Route path="/shop/register" element={<RegisterShopPage/>}/>
    </>
)