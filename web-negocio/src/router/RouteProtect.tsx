import type { ReactNode } from "react";
import { Navigate, useNavigate } from "react-router-dom";
import { LuCircleAlert } from "react-icons/lu";
import { useAuth } from "../modules/auth/hooks/useAuth";
import { Button } from "../shared/components/ui/Button";
import { EmptyState, PageLoader } from "../shared/components/ui/Feedback";

export function RouteProtect({
  children,
  requiredRol,
}: {
  children: ReactNode;
  requiredRol?: "cliente" | "negocio" | "admin";
}) {
  const { user, loading, logout } = useAuth();
  const navigate = useNavigate();

  if (loading) return <PageLoader />;
  if (!user) return <Navigate to="/login" replace />;

  if (requiredRol && user.rol !== requiredRol) {
    return (
      <div className="mx-auto max-w-xl px-4 py-12">
        <EmptyState
          icon={<LuCircleAlert />}
          title="Acceso denegado"
          description="Esta cuenta no tiene permisos para ingresar al panel de negocio."
          action={
            <Button
              onClick={async () => {
                await logout();
                navigate("/login", { replace: true });
              }}
            >
              Iniciar sesión con otra cuenta
            </Button>
          }
        />
      </div>
    );
  }

  return children;
}
