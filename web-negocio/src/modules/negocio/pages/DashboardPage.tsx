import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import {
  LuArrowUpRight,
  LuCalendar,
  LuCheck,
  LuClock,
  LuListChecks,
  LuPlus,
  LuSparkles,
  LuStore,
  LuTrendingUp,
} from "react-icons/lu";
import { useAuth } from "../../auth/hooks/useAuth";
import { getProfessionals, getSchedule, getServices } from "../api";
import { WEEK_DAYS, categoryLabel, formatTime } from "../constants";
import type { Professional, Schedule, Service } from "../types";
import { getReport } from "../../reportes/api";
import type { Report } from "../../reportes/types";
import { getReservations } from "../../reservas/api";
import { statusMeta } from "../../reservas/constants";
import type { Reservation } from "../../reservas/types";
import {
  addDays,
  formatClock,
  formatDateShort,
  formatMoney,
  todayIso,
} from "../../../lib/format";
import { getShopForId } from "../../shop/api";
import { useShop } from "../../shop/hooks/useShop";
import type { ShopFullProfileOut } from "../../shop/types";
import { Badge } from "../../../shared/components/ui/Badge";
import { Button } from "../../../shared/components/ui/Button";
import { Card, CardHeader } from "../../../shared/components/ui/Card";
import { PageHeader } from "../../../shared/components/ui/PageHeader";
import {
  EmptyState,
  ErrorState,
  PageLoader,
} from "../../../shared/components/ui/Feedback";

function todayValue(): string {
  const index = new Date().getDay();
  return ["domingo", "lunes", "martes", "miercoles", "jueves", "viernes", "sabado"][
    index
  ];
}

function longDate(): string {
  const formatted = new Intl.DateTimeFormat("es-MX", {
    weekday: "long",
    day: "numeric",
    month: "long",
  }).format(new Date());
  return formatted.charAt(0).toUpperCase() + formatted.slice(1);
}

export function DashboardPage() {
  const { user } = useAuth();
  const { selectedShop, selectedShopId, loading: shopLoading, error: shopError } = useShop();

  const [services, setServices] = useState<Service[]>([]);
  const [professionals, setProfessionals] = useState<Professional[]>([]);
  const [schedule, setSchedule] = useState<Schedule[]>([]);
  const [profile, setProfile] = useState<ShopFullProfileOut | null>(null);
  const [report, setReport] = useState<Report | null>(null);
  const [todayReservations, setTodayReservations] = useState<Reservation[]>([]);
  const [upcoming, setUpcoming] = useState<Reservation[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [reloadKey, setReloadKey] = useState(0);

  useEffect(() => {
    if (!selectedShopId) {
      setLoading(false);
      return;
    }

    let active = true;
    setLoading(true);
    setError(null);

    const today = todayIso();

    Promise.allSettled([
      getServices(selectedShopId),
      getProfessionals(selectedShopId),
      getSchedule(selectedShopId),
      getShopForId(String(selectedShopId)),
      getReport(selectedShopId, addDays(today, -29), today),
      getReservations(selectedShopId, {
        fecha_desde: today,
        fecha_hasta: addDays(today, 7),
      }),
    ]).then((results) => {
      if (!active) return;

      const [
        servicesResult,
        professionalsResult,
        scheduleResult,
        profileResult,
        reportResult,
        reservationsResult,
      ] = results;

      if (servicesResult.status === "fulfilled") setServices(servicesResult.value);
      if (professionalsResult.status === "fulfilled")
        setProfessionals(professionalsResult.value);
      if (scheduleResult.status === "fulfilled") setSchedule(scheduleResult.value);
      if (profileResult.status === "fulfilled") setProfile(profileResult.value);
      if (reportResult.status === "fulfilled") setReport(reportResult.value);
      if (reservationsResult.status === "fulfilled") {
        const items = reservationsResult.value.items;
        setTodayReservations(
          items.filter(
            (item) => item.fecha === today && item.estado !== "cancelada",
          ),
        );
        setUpcoming(
          items
            .filter(
              (item) =>
                item.fecha >= today &&
                (item.estado === "pendiente" || item.estado === "confirmada"),
            )
            .sort((a, b) =>
              `${a.fecha}T${a.hora_inicio}`.localeCompare(
                `${b.fecha}T${b.hora_inicio}`,
              ),
            )
            .slice(0, 4),
        );
      }

      const failures = results.filter((result) => result.status === "rejected");
      if (failures.length === results.length) {
        setError("No pudimos cargar la información del panel.");
      }

      setLoading(false);
    });

    return () => {
      active = false;
    };
  }, [selectedShopId, reloadKey]);

  if (shopLoading || loading) {
    return <PageLoader label="Cargando el resumen de tu negocio..." />;
  }

  if (shopError) {
    return (
      <ErrorState
        title="No pudimos cargar tus negocios"
        message={shopError}
        onRetry={() => window.location.reload()}
      />
    );
  }

  if (!selectedShop) {
    return (
      <div className="mx-auto max-w-3xl">
        <PageHeader
          eyebrow="Primer paso"
          title="Bienvenido a ReservAll"
          description="Registra tu negocio para comenzar a organizar servicios, profesionales y horarios."
        />
        <Card className="p-8 text-center">
          <span className="mx-auto flex size-14 items-center justify-center rounded-2xl bg-primary-tint text-2xl text-primary">
            <LuStore />
          </span>
          <h2 className="mt-4 font-display text-xl font-bold">Aún no tienes un negocio</h2>
          <p className="mx-auto mt-2 max-w-md text-sm text-secondary-text">
            Crea tu perfil de negocio y empieza a configurar tu catálogo y disponibilidad.
          </p>
          <Link to="/negocio/registrar" className="mt-6 inline-block">
            <Button leftIcon={<LuPlus size={16} />}>Registrar mi negocio</Button>
          </Link>
        </Card>
      </div>
    );
  }

  const hasImage =
    Boolean(selectedShop.imagen_negocio) && selectedShop.imagen_negocio !== "null";
  const contactsCount = profile?.contacto.length ?? 0;
  const checklist = [
    {
      label: "Información general del negocio",
      done: Boolean(selectedShop.nombre && selectedShop.descripcion),
      to: "/negocio",
    },
    { label: "Imagen de portada", done: hasImage, to: "/negocio" },
    { label: "Formas de contacto", done: contactsCount > 0, to: "/negocio" },
    { label: "Dirección del local", done: Boolean(profile?.direccion), to: "/negocio" },
    { label: "Al menos un servicio", done: services.length > 0, to: "/servicios" },
    {
      label: "Equipo de profesionales",
      done: professionals.length > 0,
      to: "/profesionales",
    },
    { label: "Horario semanal", done: schedule.length > 0, to: "/horarios" },
  ];

  const completed = checklist.filter((item) => item.done).length;
  const completeness = Math.round((completed / checklist.length) * 100);
  const today = todayValue();

  const todayCount = todayReservations.length;
  const pendingUpcoming = upcoming.filter(
    (reservation) => reservation.estado === "pendiente",
  ).length;

  const stats = [
    {
      label: "Reservas hoy",
      value: todayCount,
      hint: `${upcoming.length} próximas en 7 días`,
      icon: LuCalendar,
      tone: "bg-primary-tint text-primary",
      to: "/reservas",
    },
    {
      label: "Por confirmar",
      value: pendingUpcoming,
      hint: "Pendientes en tu agenda",
      icon: LuClock,
      tone: "bg-highlight-tint text-highlight",
      to: "/reservas",
    },
    {
      label: "Ingresos 30 días",
      value: formatMoney(report?.totales.ingresos ?? 0, true),
      hint: `${report?.totales.completadas ?? 0} citas completadas`,
      icon: LuTrendingUp,
      tone: "bg-secondary-tint text-secondary",
      to: "/reportes",
    },
    {
      label: "Perfil completo",
      value: `${completeness}%`,
      hint: `${completed} de ${checklist.length} pasos`,
      icon: LuSparkles,
      tone: "bg-surface-muted text-foreground",
      to: "/negocio",
    },
  ];

  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow={longDate()}
        title={`Hola, ${user?.nombre?.split(" ")[0] ?? "propietario"}`}
        description="Este es el estado de tu negocio y los siguientes pasos para tenerlo listo."
        actions={
          <>
            <Link to="/reportes">
              <Button variant="outline" size="sm" leftIcon={<LuTrendingUp size={15} />}>
                Ver reportes
              </Button>
            </Link>
            <Link to="/servicios">
              <Button size="sm" leftIcon={<LuPlus size={15} />}>
                Nuevo servicio
              </Button>
            </Link>
          </>
        }
      />

      {error && (
        <ErrorState
          message={error}
          onRetry={() => setReloadKey((key) => key + 1)}
        />
      )}

      <section className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-primary via-primary to-primary-soft p-6 text-white shadow-lift sm:p-8">
        <div className="pointer-events-none absolute -right-16 -top-20 size-64 rounded-full bg-white/10 blur-2xl" />
        <div className="pointer-events-none absolute -bottom-24 left-1/3 size-64 rounded-full bg-highlight-soft/20 blur-3xl" />
        <div className="relative flex flex-col gap-6 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-center gap-4">
            {hasImage ? (
              <img
                src={selectedShop.imagen_negocio}
                alt={selectedShop.nombre}
                className="size-16 rounded-2xl border-2 border-white/30 object-cover shadow-lg sm:size-20"
              />
            ) : (
              <span className="flex size-16 items-center justify-center rounded-2xl border border-white/30 bg-white/10 text-2xl sm:size-20">
                <LuStore />
              </span>
            )}
            <div>
              <div className="flex flex-wrap items-center gap-2">
                <h2 className="font-display text-xl font-extrabold sm:text-2xl">
                  {selectedShop.nombre}
                </h2>
                <span className="rounded-full bg-white/15 px-2.5 py-1 text-[10px] font-bold uppercase tracking-wide text-white">
                  {categoryLabel(selectedShop.categoria_negocio)}
                </span>
              </div>
              <p className="mt-1 line-clamp-2 max-w-xl text-sm text-white/80">
                {selectedShop.descripcion || "Agrega una descripción para tu negocio."}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-3 rounded-2xl border border-white/20 bg-white/10 px-4 py-3 backdrop-blur">
            <div className="text-right">
              <p className="text-[10px] font-bold uppercase tracking-[0.16em] text-white/70">
                Perfil
              </p>
              <p className="font-display text-lg font-extrabold">{completeness}%</p>
            </div>
            <div className="h-10 w-px bg-white/20" />
            <div className="text-right">
              <p className="text-[10px] font-bold uppercase tracking-[0.16em] text-white/70">
                Equipo
              </p>
              <p className="font-display text-lg font-extrabold">{professionals.length}</p>
            </div>
          </div>
        </div>
      </section>

      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        {stats.map((stat) => {
          const Icon = stat.icon;
          return (
            <Link
              key={stat.label}
              to={stat.to}
              className="group rounded-2xl border border-border/80 bg-card p-5 shadow-soft transition-all hover:-translate-y-0.5 hover:border-primary-soft/60 hover:shadow-lift"
            >
              <div className="flex items-start justify-between">
                <span className={`flex size-10 items-center justify-center rounded-xl text-lg ${stat.tone}`}>
                  <Icon />
                </span>
                <LuArrowUpRight
                  size={16}
                  className="text-secondary-text/50 transition-colors group-hover:text-primary"
                />
              </div>
              <p className="mt-4 font-display text-3xl font-extrabold text-foreground">
                {stat.value}
              </p>
              <p className="text-sm font-semibold text-foreground">{stat.label}</p>
              <p className="text-xs text-secondary-text">{stat.hint}</p>
            </Link>
          );
        })}
      </div>

      <div className="grid gap-6 xl:grid-cols-[1.55fr_1fr]">
        <div className="space-y-6">
          <Card>
            <CardHeader
              title="Tu semana"
              subtitle="Horario configurado para cada día"
              icon={<LuClock />}
              action={
                <Link
                  to="/horarios"
                  className="text-xs font-semibold text-primary hover:underline"
                >
                  Gestionar
                </Link>
              }
            />
            <div className="grid gap-2 p-4 sm:grid-cols-2">
              {WEEK_DAYS.map((day) => {
                const entry = schedule.find((item) => item.dia === day.value);
                const isToday = day.value === today;
                return (
                  <div
                    key={day.value}
                    className={`flex items-center justify-between gap-3 rounded-xl border px-3 py-2.5 ${
                      isToday
                        ? "border-primary-soft/50 bg-primary-tint/50"
                        : "border-border/60 bg-surface/60"
                    }`}
                  >
                    <div className="flex items-center gap-2">
                      <span
                        className={`flex size-7 items-center justify-center rounded-lg text-[10px] font-bold ${
                          isToday
                            ? "bg-primary text-white"
                            : "bg-surface-muted text-secondary-text"
                        }`}
                      >
                        {day.short}
                      </span>
                      <span className="text-sm font-semibold text-foreground">
                        {day.label}
                      </span>
                    </div>
                    {entry ? (
                      <span className="text-xs font-medium text-secondary-text">
                        {formatTime(entry.hora_apertura)} – {formatTime(entry.hora_cierre)}
                      </span>
                    ) : (
                      <Badge tone="neutral">Cerrado</Badge>
                    )}
                  </div>
                );
              })}
            </div>
          </Card>

          <Card>
            <CardHeader
              title="Próximas reservas"
              subtitle="Citas pendientes o confirmadas de los próximos 7 días"
              icon={<LuCalendar />}
              action={
                <Link
                  to="/reservas"
                  className="text-xs font-semibold text-primary hover:underline"
                >
                  Ver agenda
                </Link>
              }
            />
            {upcoming.length === 0 ? (
              <div className="px-4 py-8 text-center">
                <p className="text-sm text-secondary-text">
                  No tienes citas próximas. Cuando tus clientes reserven,
                  aparecerán aquí.
                </p>
                <Link to="/reservas" className="mt-3 inline-block">
                  <Button variant="outline" size="sm" leftIcon={<LuCalendar size={14} />}>
                    Abrir agenda
                  </Button>
                </Link>
              </div>
            ) : (
              <div className="divide-y divide-border/60">
                {upcoming.map((reservation) => {
                  const meta = statusMeta(reservation.estado);
                  return (
                    <Link
                      key={reservation.id_reserva}
                      to="/reservas"
                      className="flex items-center gap-3 px-4 py-3 transition-colors hover:bg-surface/60"
                    >
                      <span className="flex w-16 shrink-0 flex-col items-center rounded-xl bg-primary-tint/60 px-2 py-2 text-center">
                        <span className="text-[10px] font-bold uppercase tracking-wide text-primary">
                          {formatDateShort(reservation.fecha)}
                        </span>
                        <span className="text-xs font-semibold text-foreground">
                          {formatClock(reservation.hora_inicio)}
                        </span>
                      </span>
                      <div className="min-w-0 flex-1">
                        <p className="truncate text-sm font-semibold text-foreground">
                          {reservation.cliente_nombre}
                        </p>
                        <p className="truncate text-xs text-secondary-text">
                          {reservation.servicio_nombre}
                          {reservation.profesional_nombre
                            ? ` · ${reservation.profesional_nombre}`
                            : ""}
                        </p>
                      </div>
                      <Badge tone={meta.tone} dot>
                        {meta.label}
                      </Badge>
                    </Link>
                  );
                })}
              </div>
            )}
          </Card>
        </div>

        <div className="space-y-6">
          <Card>
            <CardHeader
              title="Completa tu perfil"
              subtitle={`${completed} de ${checklist.length} pasos completados`}
              icon={<LuCheck />}
            />
            <div className="p-4">
              <div className="mb-4 h-2 overflow-hidden rounded-full bg-surface-muted">
                <div
                  className="h-full rounded-full bg-gradient-to-r from-primary to-highlight-soft transition-all"
                  style={{ width: `${completeness}%` }}
                />
              </div>
              <ul className="space-y-1">
                {checklist.map((item) => (
                  <li key={item.label}>
                    <Link
                      to={item.to}
                      className="flex items-center gap-2.5 rounded-lg px-2 py-2 transition-colors hover:bg-surface-muted"
                    >
                      <span
                        className={`flex size-5 shrink-0 items-center justify-center rounded-full ${
                          item.done
                            ? "bg-success-tint text-success"
                            : "border border-border-strong text-transparent"
                        }`}
                      >
                        <LuCheck size={12} />
                      </span>
                      <span
                        className={`flex-1 text-xs font-medium ${
                          item.done ? "text-secondary-text line-through" : "text-foreground"
                        }`}
                      >
                        {item.label}
                      </span>
                      {!item.done && (
                        <LuArrowUpRight size={13} className="text-secondary-text/60" />
                      )}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          </Card>

          <Card className="overflow-hidden">
            <div className="bg-foreground px-5 py-4 text-white">
              <p className="text-[10px] font-bold uppercase tracking-[0.18em] text-white/60">
                Acciones rápidas
              </p>
              <p className="mt-1 font-display text-base font-bold">
                Mantén tu negocio al día
              </p>
            </div>
            <div className="space-y-1 p-3">
              {[
                { to: "/servicios", label: "Agregar un servicio", icon: LuListChecks },
                { to: "/reservas", label: "Revisar la agenda", icon: LuCalendar },
                { to: "/reportes", label: "Consultar reportes", icon: LuTrendingUp },
                { to: "/negocio", label: "Editar información", icon: LuStore },
              ].map((action) => {
                const Icon = action.icon;
                return (
                  <Link
                    key={action.to}
                    to={action.to}
                    className="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-semibold text-secondary-text transition-colors hover:bg-surface-muted hover:text-foreground"
                  >
                    <Icon size={16} className="text-primary" />
                    <span className="flex-1">{action.label}</span>
                    <LuArrowUpRight size={14} />
                  </Link>
                );
              })}
            </div>
          </Card>

          <div className="rounded-2xl border border-border/70 bg-surface/70 p-4">
            <p className="text-[10px] font-bold uppercase tracking-[0.18em] text-secondary-text">
              Métricas de reservas
            </p>
            <div className="mt-3 grid grid-cols-3 gap-2">
              {[
                { label: "Hoy", value: todayCount },
                { label: "Pendientes", value: pendingUpcoming },
                {
                  label: "Ingresos 30d",
                  value: formatMoney(report?.totales.ingresos ?? 0, true),
                },
              ].map((item) => (
                <div
                  key={item.label}
                  className="rounded-xl border border-border/70 bg-card px-2 py-3 text-center"
                >
                  <p className="font-display text-base font-extrabold text-foreground">
                    {item.value}
                  </p>
                  <p className="text-[10px] font-medium text-secondary-text">
                    {item.label}
                  </p>
                </div>
              ))}
            </div>
            <Link
              to="/reportes"
              className="mt-3 flex items-center justify-center gap-1.5 text-[10px] font-semibold text-primary hover:underline"
            >
              <LuSparkles size={11} className="text-highlight" />
              Ver el reporte completo
            </Link>
          </div>
        </div>
      </div>

      {services.length === 0 && (
        <EmptyState
          icon={<LuListChecks />}
          title="Tu catálogo está vacío"
          description="Agrega tu primer servicio para que tus clientes puedan reservarlo."
          action={
            <Link to="/servicios">
              <Button size="sm" leftIcon={<LuPlus size={15} />}>
                Crear servicio
              </Button>
            </Link>
          }
        />
      )}
    </div>
  );
}
