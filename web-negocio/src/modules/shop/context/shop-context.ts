import { createContext } from "react";
import type { ShopGeneralInfo } from "../types";

export interface ShopContextValue {
  shops: ShopGeneralInfo[];
  selectedShop: ShopGeneralInfo | null;
  selectedShopId: number | null;
  loading: boolean;
  error: string | null;
  selectShop: (shopId: number) => void;
  refreshShops: () => Promise<void>;
}

export const ShopContext = createContext<ShopContextValue | undefined>(undefined);
