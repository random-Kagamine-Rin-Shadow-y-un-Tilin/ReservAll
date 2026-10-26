import { useEffect } from "react";
import { NavLink, useLocation, useNavigate } from "react-router-dom";
import {
  LuCalendar,
  LuChevronRight,
  LuClock,
  LuLayoutDashboard,
  LuListChecks,
  LuLogOut,
  LuSparkles,
  LuStore,
  LuTrendingUp,
  LuUser,
  LuUsers,
} from "react-icons/lu";
import { useAuth } from "../../../modules/auth/hooks/useAuth";
import { Brand } from "./Brand";

interface NavEntry {
  to: string;
  label: string;
  icon: typeof LuStore;
  soon?: boolean;
}

const groups: { label: string; items: NavEntry[] }[] = [
  {
    label: "General",
    items: [
      { to: "/dashboard", label: "Panel", icon: LuLayoutDashboard },
      { to: "/negocio", label: "Mi negocio", icon: LuStore },
    ],
  },
  {
    label: "Operación",
    items: [
      { to: "/servicios", label: "Servicios", icon: LuListChecks },
      { to: "/profesionales", label: "Profesionales", icon: LuUsers },
      { to: "/horarios", label: "Horarios", icon: LuClock },
    ],
  },
  {
    label: "Próximamente",
    items: [
      { to: "/reservas", label: "Reservas", icon: LuCalendar, soon: true },
      { to: "/clientes", label: "Clientes", icon: LuUser, soon: true },
      { to: "/reportes", label: "Reportes", icon: LuTrendingUp, soon: true },
    ],
  },
];

export function Sidebar({
  open,
  onClose,
}: {
  open: boolean;
  onClose: () => void;
}) {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  useEffect(() => {
    onClose();
  }, [location.pathname, onClose]);

  async function handleLogout() {
    await logout();
    navigate("/login", { replace: true });
  }

  return (
    <>
      {open && (
        <div
          className="fixed inset-0 z-30 bg-foreground/40 backdrop-blur-sm lg:hidden"
          onClick={onClose}
          role="presentation"
        />
      )}

      <aside
        className={`fixed inset-y-0 left-0 z-40 flex w-72 flex-col border-r border-border/80 bg-surface/95 backdrop-blur transition-transform duration-200 lg:sticky lg:top-0 lg:h-screen lg:translate-x-0 ${
          open ? "translate-x-0" : "-translate-x-full"
        }`}
      >
        <div className="flex h-20 shrink-0 items-center justify-between px-5">
          <Brand />
          <button
            type="button"
            onClick={onClose}
            className="rounded-lg px-2 py-1 text-sm font-medium text-secondary-text hover:bg-surface-muted lg:hidden"
          >
            Cerrar
          </button>
        </div>

        <nav className="flex-1 overflow-y-auto px-3 pb-4">
          {groups.map((group) => (
            <div key={group.label} className="mb-5">
              <p className="mb-2 px-3 text-[10px] font-bold uppercase tracking-[0.18em] text-secondary-text/80">
                {group.label}
              </p>
              <div className="space-y-1">
                {group.items.map((item) => {
                  const Icon = item.icon;
                  return (
                    <NavLink
                      key={item.to}
                      to={item.to}
                      end
                      className={({ isActive }) =>
                        `group flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-semibold transition-colors ${
                          isActive
                            ? "bg-primary-tint text-primary"
                            : "text-secondary-text hover:bg-surface-muted hover:text-foreground"
                        }`
                      }
                    >
                      {({ isActive }) => (
                        <>
                          <Icon
                            size={18}
                            className={isActive ? "text-primary" : "text-secondary-text"}
                          />
                          <span className="flex-1">{item.label}</span>
                          {item.soon && (
                            <span className="rounded-full bg-highlight-tint px-1.5 py-0.5 text-[9px] font-bold uppercase tracking-wide text-highlight">
                              Pronto
                            </span>
                          )}
                          {isActive && <LuChevronRight size={14} />}
                        </>
                      )}
                    </NavLink>
                  );
                })}
              </div>
            </div>
          ))}
        </nav>

        <div className="shrink-0 border-t border-border/70 p-3">
          <NavLink
            to="/perfil"
            end
            className={({ isActive }) =>
              `mb-2 flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-semibold transition-colors ${
                isActive
                  ? "bg-primary-tint text-primary"
                  : "text-secondary-text hover:bg-surface-muted hover:text-foreground"
              }`
            }
          >
            <LuUser size={18} />
            <span className="flex-1">Mi cuenta</span>
          </NavLink>

          <div className="rounded-xl border border-border/70 bg-card p-3">
            <div className="flex items-center gap-2.5">
              <span className="flex size-9 shrink-0 items-center justify-center rounded-full bg-secondary-tint font-display text-sm font-bold text-secondary">
                {user?.nombre?.charAt(0).toUpperCase() ?? "R"}
              </span>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-semibold text-foreground">
                  {user?.nombre ?? "Propietario"}
                </p>
                <p className="truncate text-xs text-secondary-text">{user?.correo}</p>
              </div>
            </div>
            <button
              type="button"
              onClick={handleLogout}
              className="mt-3 flex w-full items-center justify-center gap-2 rounded-lg border border-border px-3 py-2 text-xs font-semibold text-secondary-text transition-colors hover:border-error/30 hover:bg-error-tint hover:text-error"
            >
              <LuLogOut size={14} />
              Cerrar sesión
            </button>
          </div>

          <p className="mt-3 flex items-center justify-center gap-1.5 text-[10px] font-medium text-secondary-text/80">
            <LuSparkles size={11} />
            ReservAll · Fase 1
          </p>
        </div>
      </aside>
    </>
  );
}
