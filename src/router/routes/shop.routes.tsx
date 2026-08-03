import { Route } from "react-router-dom";

//Imports de pagina
import { Home } from "../../modules/shop/pages/Home";
import { RegisterShopPage } from "../../modules/shop/pages/RegisterShopPage";

export const shopRoutes = (
    <>
    <Route path="/" element={<Home/>}/>
    <Route path="/shop/register" element={<RegisterShopPage/>}/>
    </>
)