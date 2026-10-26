import type { ReactNode } from "react";
import { LuCalendar, LuClock, LuSparkles, LuUsers } from "react-icons/lu";
import { Brand } from "../../../shared/components/layout/Brand";

export function AuthLayout({
  title,
  subtitle,
  children,
  footer,
}: {
  title: string;
  subtitle: string;
  children: ReactNode;
  footer?: ReactNode;
}) {
  return (
    <div className="min-h-screen lg:grid lg:grid-cols-[1.05fr_1fr]">
      <aside className="relative hidden overflow-hidden bg-primary p-10 text-white lg:flex lg:flex-col lg:justify-between xl:p-14">
        <div className="pointer-events-none absolute -right-24 -top-24 size-80 rounded-full bg-white/10 blur-2xl" />
        <div className="pointer-events-none absolute -bottom-32 -left-20 size-96 rounded-full bg-highlight-soft/20 blur-3xl" />

        <div className="relative">
          <Brand inverted />
        </div>

        <div className="relative max-w-lg">
          <p className="text-[11px] font-bold uppercase tracking-[0.22em] text-white/60">
            Panel para negocios
          </p>
          <h1 className="mt-4 font-display text-4xl font-extrabold leading-[1.08] xl:text-5xl">
            Menos llamadas.
            <br />
            Más citas confirmadas.
          </h1>
          <p className="mt-4 text-base leading-relaxed text-white/80">
            ReservAll centraliza tus servicios, tu equipo y tu disponibilidad para que
            dediques el tiempo a atender, no a organizar la agenda.
          </p>

          <ul className="mt-8 space-y-3">
            {[
              { icon: LuCalendar, text: "Catálogo de servicios claro y ordenado" },
              { icon: LuUsers, text: "Equipo y especialidades en un solo lugar" },
              { icon: LuClock, text: "Horarios semanales siempre actualizados" },
              { icon: LuSparkles, text: "Preparado para reservas y reportes" },
            ].map((feature) => {
              const Icon = feature.icon;
              return (
                <li key={feature.text} className="flex items-center gap-3 text-sm">
                  <span className="flex size-8 shrink-0 items-center justify-center rounded-lg bg-white/15">
                    <Icon size={15} />
                  </span>
                  <span className="text-white/90">{feature.text}</span>
                </li>
              );
            })}
          </ul>
        </div>

        <div className="relative flex items-center gap-3 rounded-2xl border border-white/20 bg-white/10 p-4 backdrop-blur">
          <span className="flex size-10 shrink-0 items-center justify-center rounded-xl bg-highlight-soft text-lg text-foreground">
            R
          </span>
          <div>
            <p className="text-sm font-semibold">ReservAll · Fase 1</p>
            <p className="text-xs text-white/70">
              Perfil, servicios, profesionales y horarios.
            </p>
          </div>
        </div>
      </aside>

      <main className="flex min-h-screen items-center justify-center px-4 py-10 sm:px-8">
        <div className="w-full max-w-md">
          <div className="mb-8 lg:hidden">
            <Brand />
          </div>

          <p className="text-[11px] font-bold uppercase tracking-[0.18em] text-primary">
            ReservAll para negocios
          </p>
          <h1 className="mt-2 font-display text-3xl font-extrabold text-foreground">
            {title}
          </h1>
          <p className="mt-2 text-sm leading-relaxed text-secondary-text">{subtitle}</p>

          <div className="mt-7">{children}</div>
          {footer}
        </div>
      </main>
    </div>
  );
}
