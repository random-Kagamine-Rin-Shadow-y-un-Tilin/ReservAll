import { useContext } from "react";
import { ShopContext } from "../context/shop-context";

export function useShop() {
  const context = useContext(ShopContext);
  if (!context) {
    throw new Error("useShop debe usarse dentro de un ShopProvider");
  }
  return context;
}
