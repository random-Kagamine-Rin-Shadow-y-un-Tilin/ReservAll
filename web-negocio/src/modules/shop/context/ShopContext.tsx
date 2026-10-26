import { useCallback, useEffect, useState, type ReactNode } from "react";
import { getOwnerShops } from "../api";
import type { ShopGeneralInfo } from "../types";
import { ShopContext } from "./shop-context";

const STORAGE_KEY = "reservall:selected-shop";

function readStoredShopId(): number | null {
  const raw = window.localStorage.getItem(STORAGE_KEY);
  if (!raw) return null;
  const parsed = Number(raw);
  return Number.isFinite(parsed) ? parsed : null;
}

export function ShopProvider({ children }: { children: ReactNode }) {
  const [shops, setShops] = useState<ShopGeneralInfo[]>([]);
  const [selectedShopId, setSelectedShopId] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refreshShops = useCallback(async () => {
    setLoading(true);
    try {
      const data = await getOwnerShops();
      setShops(data);
      setError(null);

      setSelectedShopId((current) => {
        const stored = readStoredShopId();
        const preferred = current ?? stored;
        const exists = data.some((shop) => shop.id === preferred);
        const next = exists ? preferred : (data[0]?.id ?? null);
        if (next) window.localStorage.setItem(STORAGE_KEY, String(next));
        return next;
      });
    } catch (err) {
      setShops([]);
      setSelectedShopId(null);
      setError(
        err instanceof Error ? err.message : "No pudimos cargar tus negocios.",
      );
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void refreshShops();
  }, [refreshShops]);

  const selectShop = useCallback((shopId: number) => {
    setSelectedShopId(shopId);
    window.localStorage.setItem(STORAGE_KEY, String(shopId));
  }, []);

  const selectedShop =
    shops.find((shop) => shop.id === selectedShopId) ?? null;

  return (
    <ShopContext.Provider
      value={{
        shops,
        selectedShop,
        selectedShopId,
        loading,
        error,
        selectShop,
        refreshShops,
      }}
    >
      {children}
    </ShopContext.Provider>
  );
}
