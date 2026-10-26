import { Link, useNavigate } from "react-router-dom";
import {
  LuLogOut,
  LuMail,
  LuSparkles,
  LuStore,
  LuUser,
} from "react-icons/lu";
import { useAuth } from "../../auth/hooks/useAuth";
import { useShop } from "../../shop/hooks/useShop";
import { Badge } from "../../../shared/components/ui/Badge";
import { Button } from "../../../shared/components/ui/Button";
import { Card, CardHeader } from "../../../shared/components/ui/Card";
import { PageHeader } from "../../../shared/components/ui/PageHeader";

export function AccountPage() {
  const { user, logout } = useAuth();
  const { shops, selectedShop, loading: shopLoading } = useShop();
  const navigate = useNavigate();

  async function handleLogout() {
    await logout();
    navigate("/login", { replace: true });
  }

  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow="Cuenta"
        title="Mi cuenta"
        description="Los datos de la persona que administra el negocio en ReservAll."
      />

      <div className="grid gap-6 lg:grid-cols-[1.3fr_1fr]">
        <Card>
          <CardHeader
            title="Datos de la cuenta"
            subtitle="Información asociada a tu sesión"
            icon={<LuUser />}
          />
          <div className="space-y-4 p-5">
            <div className="flex items-center gap-4">
              <span className="flex size-16 items-center justify-center rounded-2xl bg-secondary-tint font-display text-2xl font-extrabold text-secondary">
                {user?.nombre?.charAt(0).toUpperCase() ?? "R"}
              </span>
              <div>
                <p className="font-display text-lg font-bold text-foreground">
                  {user?.nombre ?? "Propietario"}
                </p>
                <Badge tone="primary" className="mt-1">
                  Cuenta de negocio
                </Badge>
              </div>
            </div>

            <div className="grid gap-3 sm:grid-cols-2">
              <div className="rounded-xl border border-border/70 bg-surface/60 p-4">
                <p className="flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-wide text-secondary-text">
                  <LuMail size={11} />
                  Correo electrónico
                </p>
                <p className="mt-1 truncate text-sm font-semibold text-foreground">
                  {user?.correo ?? "—"}
                </p>
              </div>

              <div className="rounded-xl border border-border/70 bg-surface/60 p-4">
                <p className="flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-wide text-secondary-text">
                  <LuStore size={11} />
                  Negocios
                </p>
                <p className="mt-1 text-sm font-semibold text-foreground">
                  {shopLoading
                    ? "Cargando..."
                    : `${shops.length} ${shops.length === 1 ? "negocio" : "negocios"}`}
                </p>
              </div>
            </div>

            <div className="flex items-start gap-2.5 rounded-xl border border-highlight/20 bg-highlight-tint/50 px-4 py-3">
              <LuSparkles size={16} className="mt-0.5 shrink-0 text-highlight" />
              <p className="text-xs leading-relaxed text-secondary-text">
                La edición de datos personales y el cambio de contraseña estarán
                disponibles en una siguiente fase.
              </p>
            </div>

            <div className="flex flex-col gap-2 border-t border-border/70 pt-4 sm:flex-row sm:justify-end">
              <Button
                variant="outline"
                leftIcon={<LuLogOut size={15} />}
                onClick={handleLogout}
              >
                Cerrar sesión
              </Button>
            </div>
          </div>
        </Card>

        <Card>
          <CardHeader
            title="Negocio activo"
            subtitle="El local que estás administrando"
            icon={<LuStore />}
          />
          <div className="p-5">
            {shopLoading ? (
              <div className="space-y-3">
                <div className="h-28 w-full animate-pulse rounded-xl bg-surface-muted" />
                <div className="h-4 w-2/3 animate-pulse rounded-full bg-surface-muted" />
                <div className="h-3 w-full animate-pulse rounded-full bg-surface-muted" />
              </div>
            ) : selectedShop ? (
              <div className="rounded-2xl border border-border/70 bg-surface/60 p-4">
                {selectedShop.imagen_negocio &&
                selectedShop.imagen_negocio !== "null" ? (
                  <img
                    src={selectedShop.imagen_negocio}
                    alt={selectedShop.nombre}
                    className="h-28 w-full rounded-xl object-cover"
                  />
                ) : (
                  <div className="flex h-28 items-center justify-center rounded-xl bg-surface-muted text-3xl text-primary">
                    <LuStore />
                  </div>
                )}
                <p className="mt-3 font-display text-base font-bold text-foreground">
                  {selectedShop.nombre}
                </p>
                <p className="mt-1 line-clamp-2 text-xs leading-relaxed text-secondary-text">
                  {selectedShop.descripcion || "Sin descripción."}
                </p>
                <Link
                  to="/negocio"
                  className="mt-4 inline-flex text-xs font-semibold text-primary hover:underline"
                >
                  Ver perfil del negocio
                </Link>
              </div>
            ) : (
              <div className="rounded-xl border border-dashed border-border-strong bg-surface/60 px-4 py-8 text-center">
                <p className="text-sm font-semibold text-foreground">
                  Sin negocio seleccionado
                </p>
                <Link
                  to="/negocio/registrar"
                  className="mt-2 inline-flex text-xs font-semibold text-primary hover:underline"
                >
                  Registrar un negocio
                </Link>
              </div>
            )}
          </div>
        </Card>
      </div>
    </div>
  );
}
