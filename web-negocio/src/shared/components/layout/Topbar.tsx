import { Link, useLocation, useNavigate } from "react-router-dom";
import { LuChevronDown, LuLogOut, LuMenu, LuPlus, LuStore, LuUser } from "react-icons/lu";
import { useAuth } from "../../../modules/auth/hooks/useAuth";
import { useShop } from "../../../modules/shop/hooks/useShop";
import { Button } from "../ui/Button";

const titles: Record<string, string> = {
  "/dashboard": "Panel general",
  "/negocio": "Mi negocio",
  "/negocio/registrar": "Registrar negocio",
  "/servicios": "Servicios",
  "/profesionales": "Profesionales",
  "/horarios": "Horarios",
  "/reservas": "Reservas",
  "/clientes": "Clientes",
  "/reportes": "Reportes",
  "/perfil": "Mi cuenta",
};

export function Topbar({ onMenuClick }: { onMenuClick: () => void }) {
  const { user, logout } = useAuth();
  const { shops, selectedShop, selectedShopId, selectShop, loading } = useShop();
  const location = useLocation();
  const navigate = useNavigate();

  const title = titles[location.pathname] ?? "Panel de negocio";

  async function handleLogout() {
    await logout();
    navigate("/login", { replace: true });
  }

  return (
    <header className="sticky top-0 z-20 flex h-16 items-center justify-between gap-3 border-b border-border/70 bg-background/85 px-4 backdrop-blur-md sm:px-6 lg:px-8">
      <div className="flex min-w-0 items-center gap-3">
        <button
          type="button"
          onClick={onMenuClick}
          aria-label="Abrir menú"
          className="flex size-9 shrink-0 items-center justify-center rounded-xl border border-border bg-card text-secondary-text transition-colors hover:border-primary-soft hover:text-primary lg:hidden"
        >
          <LuMenu size={18} />
        </button>
        <div className="min-w-0">
          <p className="truncate font-display text-sm font-bold text-foreground">{title}</p>
          <p className="hidden text-[11px] text-secondary-text sm:block">
            {selectedShop ? selectedShop.nombre : "ReservAll · Panel de negocio"}
          </p>
        </div>
      </div>

      <div className="flex items-center gap-2">
        <div className="hidden items-center gap-2 sm:flex">
          {loading ? (
            <span className="h-9 w-40 animate-pulse rounded-xl bg-surface-muted" />
          ) : shops.length > 1 ? (
            <label className="flex items-center gap-2 rounded-xl border border-border bg-card px-3 py-2">
              <LuStore size={15} className="text-primary" />
              <select
                value={selectedShopId ?? ""}
                onChange={(event) => selectShop(Number(event.target.value))}
                className="max-w-44 bg-transparent text-xs font-semibold text-foreground focus:outline-none"
                aria-label="Seleccionar negocio"
              >
                {shops.map((shop) => (
                  <option key={shop.id} value={shop.id}>
                    {shop.nombre}
                  </option>
                ))}
              </select>
            </label>
          ) : selectedShop ? (
            <span className="flex items-center gap-2 rounded-xl border border-border bg-card px-3 py-2 text-xs font-semibold text-foreground">
              <LuStore size={15} className="text-primary" />
              <span className="max-w-44 truncate">{selectedShop.nombre}</span>
            </span>
          ) : null}
        </div>

        {location.pathname !== "/servicios" && (
          <Link to="/servicios" className="hidden md:block">
            <Button size="sm" leftIcon={<LuPlus size={15} />}>
              Nuevo servicio
            </Button>
          </Link>
        )}

        <details className="group relative">
          <summary className="flex cursor-pointer list-none items-center gap-2 rounded-xl border border-border bg-card px-2 py-1.5 transition-colors hover:border-primary-soft [&::-webkit-details-marker]:hidden">
            <span className="flex size-7 items-center justify-center rounded-full bg-secondary-tint font-display text-xs font-bold text-secondary">
              {user?.nombre?.charAt(0).toUpperCase() ?? "R"}
            </span>
            <span className="hidden max-w-28 truncate text-xs font-semibold text-foreground sm:block">
              {user?.nombre ?? "Mi cuenta"}
            </span>
            <LuChevronDown size={13} className="text-secondary-text" />
          </summary>

          <div className="absolute right-0 mt-2 w-60 overflow-hidden rounded-xl border border-border bg-card shadow-lift">
            <div className="border-b border-border/70 px-4 py-3">
              <p className="truncate text-sm font-semibold text-foreground">
                {user?.nombre}
              </p>
              <p className="truncate text-xs text-secondary-text">{user?.correo}</p>
              <span className="mt-2 inline-flex rounded-full bg-primary-tint px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide text-primary">
                Cuenta de negocio
              </span>
            </div>
            <Link
              to="/perfil"
              className="flex items-center gap-2 px-4 py-2.5 text-xs font-semibold text-secondary-text transition-colors hover:bg-surface-muted hover:text-foreground"
            >
              <LuUser size={15} />
              Mi cuenta
            </Link>
            <button
              type="button"
              onClick={handleLogout}
              className="flex w-full items-center gap-2 px-4 py-2.5 text-xs font-semibold text-secondary-text transition-colors hover:bg-error-tint hover:text-error"
            >
              <LuLogOut size={15} />
              Cerrar sesión
            </button>
          </div>
        </details>
      </div>
    </header>
  );
}
