import { Route } from "react-router-dom";

//Imports de pagina
import { Home } from "../../modules/shop/pages/Home";
import { RegisterShopPage } from "../../modules/shop/pages/RegisterShopPage";
import { OwnerShopPage } from "../../modules/shop/pages/OwnerShopPage";

export const shopRoutes = (
    <>
    <Route path="/shop" element={<Home/>}/>
    <Route path="/shop/register" element={<RegisterShopPage/>}/>
    <Route path="/shop/:shopId" element={<OwnerShopPage/>}/>
    </>
)