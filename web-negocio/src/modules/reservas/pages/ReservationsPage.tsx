import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import {
  LuBan,
  LuCalendar,
  LuCheck,
  LuClock,
  LuFilter,
  LuMail,
  LuRefreshCw,
  LuSearch,
  LuUser,
  LuWallet,
  LuX,
} from "react-icons/lu";
import { getProfessionals } from "../../negocio/api";
import type { Professional } from "../../negocio/types";
import { getReservations, updateReservationStatus } from "../api";
import { RESERVATION_STATUSES, statusMeta } from "../constants";
import type {
  Reservation,
  ReservationStatus,
  ReservationSummary,
} from "../types";
import { useShop } from "../../shop/hooks/useShop";
import { Badge } from "../../../shared/components/ui/Badge";
import { Button } from "../../../shared/components/ui/Button";
import { Card, CardHeader } from "../../../shared/components/ui/Card";
import { Field, Input, Select } from "../../../shared/components/ui/Field";
import { PageHeader } from "../../../shared/components/ui/PageHeader";
import {
  EmptyState,
  ErrorState,
  PageLoader,
} from "../../../shared/components/ui/Feedback";
import { Modal } from "../../../shared/components/Modal";
import {
  addDays,
  formatClock,
  formatDateLong,
  formatDateShort,
  formatDateTime,
  formatDurationMinutes,
  formatMoney,
  todayIso,
} from "../../../lib/format";

const EMPTY_SUMMARY: ReservationSummary = {
  total: 0,
  pendientes: 0,
  confirmadas: 0,
  completadas: 0,
  canceladas: 0,
  ingresos: 0,
};

type RangeKey = "todas" | "hoy" | "semana" | "mes" | "personalizado";

const RANGE_OPTIONS: { value: RangeKey; label: string }[] = [
  { value: "todas", label: "Todas" },
  { value: "hoy", label: "Hoy" },
  { value: "semana", label: "Próximos 7 días" },
  { value: "mes", label: "Últimos 30 días" },
];

function rangeDates(key: RangeKey): { desde: string; hasta: string } {
  const today = todayIso();
  if (key === "hoy") return { desde: today, hasta: today };
  if (key === "semana") return { desde: today, hasta: addDays(today, 7) };
  if (key === "mes") return { desde: addDays(today, -29), hasta: today };
  return { desde: "", hasta: "" };
}

function actionLabel(estado: ReservationStatus): string {
  if (estado === "confirmada") return "Confirmar reserva";
  if (estado === "completada") return "Marcar como completada";
  if (estado === "cancelada") return "Cancelar reserva";
  return "Actualizar reserva";
}

function actionDescription(estado: ReservationStatus, reservation: Reservation): string {
  if (estado === "confirmada") {
    return `Confirmarás la cita de ${reservation.cliente_nombre} para el ${formatDateLong(
      reservation.fecha,
    )} a las ${formatClock(reservation.hora_inicio)}.`;
  }
  if (estado === "completada") {
    return `Se marcará la cita de ${reservation.cliente_nombre} como completada. El importe de ${formatMoney(
      reservation.precio,
    )} se sumará a tus ingresos.`;
  }
  if (estado === "cancelada") {
    return `Cancelarás la cita de ${reservation.cliente_nombre}. Esta acción no se puede deshacer.`;
  }
  return "";
}

export function ReservationsPage() {
  const { selectedShop, selectedShopId, loading: shopLoading } = useShop();

  const [reservations, setReservations] = useState<Reservation[]>([]);
  const [summary, setSummary] = useState<ReservationSummary>(EMPTY_SUMMARY);
  const [professionals, setProfessionals] = useState<Professional[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadedShopId, setLoadedShopId] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [reloadKey, setReloadKey] = useState(0);

  const [rangeKey, setRangeKey] = useState<RangeKey>("todas");
  const [desde, setDesde] = useState("");
  const [hasta, setHasta] = useState("");
  const [estado, setEstado] = useState<ReservationStatus | "todas">("todas");
  const [profesionalId, setProfesionalId] = useState("");
  const [search, setSearch] = useState("");
  const [debouncedSearch, setDebouncedSearch] = useState("");

  const [selected, setSelected] = useState<Reservation | null>(null);
  const [statusTarget, setStatusTarget] = useState<{
    reservation: Reservation;
    estado: ReservationStatus;
  } | null>(null);
  const [updating, setUpdating] = useState(false);
  const [statusError, setStatusError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  useEffect(() => {
    if (!selectedShopId) return;
    getProfessionals(selectedShopId)
      .then(setProfessionals)
      .catch(() => setProfessionals([]));
  }, [selectedShopId]);

  useEffect(() => {
    const timer = window.setTimeout(() => setDebouncedSearch(search.trim()), 350);
    return () => window.clearTimeout(timer);
  }, [search]);

  useEffect(() => {
    if (!notice) return;
    const timer = window.setTimeout(() => setNotice(null), 4000);
    return () => window.clearTimeout(timer);
  }, [notice]);

  useEffect(() => {
    if (!selectedShopId) {
      setLoading(false);
      return;
    }

    let active = true;
    setLoading(true);
    setError(null);

    getReservations(selectedShopId, {
      fecha_desde: desde || undefined,
      fecha_hasta: hasta || undefined,
      estado: estado === "todas" ? undefined : estado,
      profesional_id: profesionalId ? Number(profesionalId) : undefined,
      search: debouncedSearch || undefined,
    })
      .then((data) => {
        if (!active) return;
        setReservations(data.items);
        setSummary(data.summary);
      })
      .catch((err) => {
        if (!active) return;
        setError(
          err instanceof Error ? err.message : "No pudimos cargar las reservas.",
        );
      })
      .finally(() => {
        if (active) {
          setLoading(false);
          setLoadedShopId(selectedShopId);
        }
      });

    return () => {
      active = false;
    };
  }, [selectedShopId, desde, hasta, estado, profesionalId, debouncedSearch, reloadKey]);

  const activeRange = useMemo<RangeKey>(() => {
    if (rangeKey !== "personalizado") return rangeKey;
    return "personalizado";
  }, [rangeKey]);

  function applyRange(key: RangeKey) {
    setRangeKey(key);
    const dates = rangeDates(key);
    setDesde(dates.desde);
    setHasta(dates.hasta);
  }

  function clearFilters() {
    applyRange("todas");
    setEstado("todas");
    setProfesionalId("");
    setSearch("");
  }

  function requestStatus(reservation: Reservation, nextStatus: ReservationStatus) {
    setStatusError(null);
    setStatusTarget({ reservation, estado: nextStatus });
  }

  async function confirmStatusChange() {
    if (!selectedShopId || !statusTarget) return;
    setUpdating(true);
    setStatusError(null);
    try {
      const updated = await updateReservationStatus(
        selectedShopId,
        statusTarget.reservation.id_reserva,
        statusTarget.estado,
      );
      setReservations((current) =>
        current.map((item) =>
          item.id_reserva === updated.id_reserva ? updated : item,
        ),
      );
      setSelected((current) =>
        current && current.id_reserva === updated.id_reserva ? updated : current,
      );
      setNotice(`Reserva ${statusMeta(updated.estado).label.toLowerCase()} correctamente.`);
      setStatusTarget(null);
      setReloadKey((key) => key + 1);
    } catch (err) {
      setStatusError(
        err instanceof Error ? err.message : "No pudimos actualizar la reserva.",
      );
    } finally {
      setUpdating(false);
    }
  }

  if (shopLoading || (loading && loadedShopId !== selectedShopId)) {
    return <PageLoader label="Cargando la agenda..." />;
  }

  if (!selectedShop) {
    return (
      <EmptyState
        icon={<LuCalendar />}
        title="Primero registra tu negocio"
        description="Necesitas un negocio para recibir reservas y gestionar tu agenda."
        action={
          <Link to="/negocio/registrar">
            <Button size="sm">Registrar negocio</Button>
          </Link>
        }
      />
    );
  }

  const hasFilters =
    Boolean(desde || hasta || debouncedSearch) ||
    estado !== "todas" ||
    Boolean(profesionalId);

  return (
    <div className="space-y-5">
      <PageHeader
        eyebrow="Operación"
        title="Reservas"
        description="Confirma, completa o cancela las citas de tus clientes. Los ingresos se calculan con las reservas completadas."
        actions={
          <Button
            variant="outline"
            size="sm"
            leftIcon={<LuRefreshCw size={15} />}
            onClick={() => setReloadKey((key) => key + 1)}
          >
            Actualizar
          </Button>
        }
      />

      {notice && (
        <div className="flex items-center gap-2 rounded-xl border border-success/20 bg-success-tint px-4 py-3 text-sm font-semibold text-success">
          <LuCheck size={16} />
          {notice}
        </div>
      )}

      {error && (
        <ErrorState message={error} onRetry={() => setReloadKey((key) => key + 1)} />
      )}

      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        {[
          {
            label: "Pendientes",
            value: summary.pendientes,
            hint: "Por confirmar",
            icon: LuClock,
            tone: "bg-highlight-tint text-highlight",
          },
          {
            label: "Confirmadas",
            value: summary.confirmadas,
            hint: "En la agenda",
            icon: LuCalendar,
            tone: "bg-secondary-tint text-secondary",
          },
          {
            label: "Completadas",
            value: summary.completadas,
            hint: "Citas atendidas",
            icon: LuCheck,
            tone: "bg-success-tint text-success",
          },
          {
            label: "Ingresos",
            value: formatMoney(summary.ingresos, true),
            hint: "Reservas completadas",
            icon: LuWallet,
            tone: "bg-primary-tint text-primary",
          },
        ].map((stat) => {
          const Icon = stat.icon;
          return (
            <Card key={stat.label} className="p-5">
              <div className="flex items-start justify-between">
                <span className={`flex size-10 items-center justify-center rounded-xl text-lg ${stat.tone}`}>
                  <Icon />
                </span>
                <span className="text-[10px] font-bold uppercase tracking-[0.14em] text-secondary-text">
                  {stat.label}
                </span>
              </div>
              <p className="mt-4 font-display text-2xl font-extrabold text-foreground">
                {stat.value}
              </p>
              <p className="text-xs text-secondary-text">{stat.hint}</p>
            </Card>
          );
        })}
      </div>

      <Card>
        <CardHeader
          title="Filtros"
          subtitle="Encuentra una cita por fecha, estado, profesional o cliente."
          icon={<LuFilter />}
          action={
            hasFilters ? (
              <Button variant="ghost" size="sm" onClick={clearFilters}>
                Limpiar
              </Button>
            ) : undefined
          }
        />
        <div className="space-y-4 p-4">
          <div className="flex flex-wrap gap-2">
            {RANGE_OPTIONS.map((option) => (
              <button
                key={option.value}
                type="button"
                onClick={() => applyRange(option.value)}
                className={`rounded-full border px-3.5 py-1.5 text-xs font-semibold transition-colors ${
                  activeRange === option.value
                    ? "border-primary bg-primary text-white"
                    : "border-border bg-card text-secondary-text hover:border-primary-soft/60 hover:text-foreground"
                }`}
              >
                {option.label}
              </button>
            ))}
            {activeRange === "personalizado" && (
              <Badge tone="primary">Rango personalizado</Badge>
            )}
          </div>

          <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-5">
            <Field label="Desde" htmlFor="reservations-from">
              <Input
                id="reservations-from"
                type="date"
                value={desde}
                onChange={(event) => {
                  setDesde(event.target.value);
                  setRangeKey("personalizado");
                }}
              />
            </Field>
            <Field label="Hasta" htmlFor="reservations-to">
              <Input
                id="reservations-to"
                type="date"
                value={hasta}
                onChange={(event) => {
                  setHasta(event.target.value);
                  setRangeKey("personalizado");
                }}
              />
            </Field>
            <Field label="Estado" htmlFor="reservations-status">
              <Select
                id="reservations-status"
                value={estado}
                onChange={(event) =>
                  setEstado(event.target.value as ReservationStatus | "todas")
                }
              >
                <option value="todas">Todos los estados</option>
                {RESERVATION_STATUSES.map((item) => (
                  <option key={item.value} value={item.value}>
                    {item.label}
                  </option>
                ))}
              </Select>
            </Field>
            <Field label="Profesional" htmlFor="reservations-professional">
              <Select
                id="reservations-professional"
                value={profesionalId}
                onChange={(event) => setProfesionalId(event.target.value)}
              >
                <option value="">Todo el equipo</option>
                {professionals.map((professional) => (
                  <option
                    key={professional.id_profesional}
                    value={professional.id_profesional}
                  >
                    {professional.nombre}
                  </option>
                ))}
              </Select>
            </Field>
            <Field label="Cliente" htmlFor="reservations-search">
              <div className="relative">
                <LuSearch
                  size={16}
                  className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-secondary-text"
                />
                <Input
                  id="reservations-search"
                  className="pl-9"
                  placeholder="Nombre o correo"
                  value={search}
                  onChange={(event) => setSearch(event.target.value)}
                />
              </div>
            </Field>
          </div>
        </div>
      </Card>

      <Card>
        <CardHeader
          title="Agenda"
          subtitle={`${summary.total} ${summary.total === 1 ? "reserva" : "reservas"} en el periodo`}
          icon={<LuCalendar />}
        />

        {reservations.length === 0 ? (
          <div className="p-4">
            <EmptyState
              icon={<LuCalendar />}
              title="No hay reservas con estos filtros"
              description="Cuando tus clientes reserven, sus citas aparecerán aquí. También puedes ampliar el rango de fechas."
              action={
                hasFilters ? (
                  <Button size="sm" variant="outline" onClick={clearFilters}>
                    Limpiar filtros
                  </Button>
                ) : undefined
              }
            />
          </div>
        ) : (
          <>
            <div className="hidden overflow-x-auto lg:block">
              <table className="w-full text-left text-sm">
                <thead className="border-b border-border/70 bg-surface/60 text-[10px] font-bold uppercase tracking-[0.14em] text-secondary-text">
                  <tr>
                    <th className="px-4 py-3">Fecha y hora</th>
                    <th className="px-4 py-3">Cliente</th>
                    <th className="px-4 py-3">Servicio</th>
                    <th className="px-4 py-3">Profesional</th>
                    <th className="px-4 py-3">Estado</th>
                    <th className="px-4 py-3 text-right">Acciones</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border/60">
                  {reservations.map((reservation) => {
                    const meta = statusMeta(reservation.estado);
                    return (
                      <tr key={reservation.id_reserva} className="hover:bg-surface/50">
                        <td className="px-4 py-3">
                          <p className="font-semibold text-foreground">
                            {formatDateShort(reservation.fecha)}
                          </p>
                          <p className="text-xs text-secondary-text">
                            {formatClock(reservation.hora_inicio)} –{" "}
                            {formatClock(reservation.hora_fin)}
                          </p>
                        </td>
                        <td className="px-4 py-3">
                          <p className="font-semibold text-foreground">
                            {reservation.cliente_nombre}
                          </p>
                          <p className="text-xs text-secondary-text">
                            {reservation.cliente_correo}
                          </p>
                        </td>
                        <td className="px-4 py-3">
                          <p className="font-medium text-foreground">
                            {reservation.servicio_nombre}
                          </p>
                          <p className="text-xs text-secondary-text">
                            {formatMoney(reservation.precio)} ·{" "}
                            {formatDurationMinutes(reservation.duracion_minutos)}
                          </p>
                        </td>
                        <td className="px-4 py-3 text-secondary-text">
                          {reservation.profesional_nombre ?? "Sin asignar"}
                        </td>
                        <td className="px-4 py-3">
                          <Badge tone={meta.tone} dot>
                            {meta.label}
                          </Badge>
                        </td>
                        <td className="px-4 py-3">
                          <div className="flex items-center justify-end gap-1">
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => setSelected(reservation)}
                            >
                              Ver
                            </Button>
                            {reservation.estado === "pendiente" && (
                              <Button
                                variant="secondary"
                                size="sm"
                                leftIcon={<LuCheck size={14} />}
                                onClick={() => requestStatus(reservation, "confirmada")}
                              >
                                Confirmar
                              </Button>
                            )}
                            {reservation.estado === "confirmada" && (
                              <Button
                                size="sm"
                                leftIcon={<LuCheck size={14} />}
                                onClick={() => requestStatus(reservation, "completada")}
                              >
                                Completar
                              </Button>
                            )}
                            {(reservation.estado === "pendiente" ||
                              reservation.estado === "confirmada") && (
                              <Button
                                variant="ghost"
                                size="sm"
                                className="text-error/80 hover:bg-error-tint hover:text-error"
                                onClick={() => requestStatus(reservation, "cancelada")}
                              >
                                Cancelar
                              </Button>
                            )}
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            <div className="divide-y divide-border/60 lg:hidden">
              {reservations.map((reservation) => {
                const meta = statusMeta(reservation.estado);
                return (
                  <div key={reservation.id_reserva} className="space-y-3 p-4">
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <p className="font-display text-base font-bold text-foreground">
                          {reservation.cliente_nombre}
                        </p>
                        <p className="text-xs text-secondary-text">
                          {reservation.servicio_nombre}
                        </p>
                      </div>
                      <Badge tone={meta.tone} dot>
                        {meta.label}
                      </Badge>
                    </div>
                    <div className="flex flex-wrap gap-x-4 gap-y-1 text-xs text-secondary-text">
                      <span className="flex items-center gap-1.5">
                        <LuCalendar size={13} />
                        {formatDateShort(reservation.fecha)}
                      </span>
                      <span className="flex items-center gap-1.5">
                        <LuClock size={13} />
                        {formatClock(reservation.hora_inicio)} –{" "}
                        {formatClock(reservation.hora_fin)}
                      </span>
                      <span className="flex items-center gap-1.5">
                        <LuUser size={13} />
                        {reservation.profesional_nombre ?? "Sin asignar"}
                      </span>
                    </div>
                    <div className="flex flex-wrap items-center gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => setSelected(reservation)}
                      >
                        Ver detalle
                      </Button>
                      {reservation.estado === "pendiente" && (
                        <Button
                          variant="secondary"
                          size="sm"
                          leftIcon={<LuCheck size={14} />}
                          onClick={() => requestStatus(reservation, "confirmada")}
                        >
                          Confirmar
                        </Button>
                      )}
                      {reservation.estado === "confirmada" && (
                        <Button
                          size="sm"
                          leftIcon={<LuCheck size={14} />}
                          onClick={() => requestStatus(reservation, "completada")}
                        >
                          Completar
                        </Button>
                      )}
                      {(reservation.estado === "pendiente" ||
                        reservation.estado === "confirmada") && (
                        <Button
                          variant="ghost"
                          size="sm"
                          className="text-error/80 hover:bg-error-tint hover:text-error"
                          onClick={() => requestStatus(reservation, "cancelada")}
                        >
                          Cancelar
                        </Button>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </>
        )}
      </Card>

      <ReservationDetailModal
        reservation={selected}
        onClose={() => setSelected(null)}
        onRequestStatus={(reservation, nextStatus) =>
          requestStatus(reservation, nextStatus)
        }
      />

      <Modal
        isOpen={Boolean(statusTarget)}
        onClose={() => {
          if (updating) return;
          setStatusTarget(null);
        }}
        title={statusTarget ? actionLabel(statusTarget.estado) : "Actualizar reserva"}
        size="sm"
      >
        {statusTarget && (
          <div className="space-y-4">
            <div className="rounded-xl border border-border/70 bg-surface/70 px-4 py-3 text-sm leading-relaxed text-secondary-text">
              {actionDescription(statusTarget.estado, statusTarget.reservation)}
            </div>

            {statusError && (
              <div className="rounded-xl border border-error/20 bg-error-tint px-4 py-3 text-sm font-medium text-error">
                {statusError}
              </div>
            )}

            <div className="flex flex-col-reverse gap-2 border-t border-border/70 pt-4 sm:flex-row sm:justify-end">
              <Button
                variant="outline"
                onClick={() => setStatusTarget(null)}
                disabled={updating}
              >
                Volver
              </Button>
              <Button
                variant={statusTarget.estado === "cancelada" ? "danger" : "primary"}
                loading={updating}
                onClick={confirmStatusChange}
              >
                {statusTarget.estado === "cancelada" ? (
                  <>
                    <LuBan size={15} />
                    Sí, cancelar
                  </>
                ) : (
                  <>
                    <LuCheck size={15} />
                    Confirmar
                  </>
                )}
              </Button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}

function ReservationDetailModal({
  reservation,
  onClose,
  onRequestStatus,
}: {
  reservation: Reservation | null;
  onClose: () => void;
  onRequestStatus: (
    reservation: Reservation,
    estado: ReservationStatus,
  ) => void;
}) {
  return (
    <Modal
      isOpen={Boolean(reservation)}
      onClose={onClose}
      title="Detalle de la reserva"
      size="md"
    >
      {reservation && (
        <div className="space-y-5">
          <div className="flex flex-wrap items-start justify-between gap-3">
            <div>
              <p className="font-display text-xl font-bold text-foreground">
                {reservation.servicio_nombre}
              </p>
              <p className="mt-1 text-sm text-secondary-text">
                {formatDateLong(reservation.fecha)} ·{" "}
                {formatClock(reservation.hora_inicio)} –{" "}
                {formatClock(reservation.hora_fin)}
              </p>
            </div>
            <Badge tone={statusMeta(reservation.estado).tone} dot>
              {statusMeta(reservation.estado).label}
            </Badge>
          </div>

          <div className="grid gap-3 sm:grid-cols-2">
            {[
              {
                icon: <LuUser size={16} />,
                label: "Cliente",
                value: reservation.cliente_nombre,
              },
              {
                icon: <LuMail size={16} />,
                label: "Correo",
                value: reservation.cliente_correo,
              },
              {
                icon: <LuUser size={16} />,
                label: "Profesional",
                value: reservation.profesional_nombre ?? "Sin asignar",
              },
              {
                icon: <LuClock size={16} />,
                label: "Duración",
                value: formatDurationMinutes(reservation.duracion_minutos),
              },
              {
                icon: <LuWallet size={16} />,
                label: "Precio",
                value: formatMoney(reservation.precio),
              },
              {
                icon: <LuCalendar size={16} />,
                label: "Solicitada",
                value: formatDateTime(reservation.fecha_creacion),
              },
            ].map((item) => (
              <div
                key={item.label}
                className="rounded-xl border border-border/70 bg-surface/60 px-4 py-3"
              >
                <p className="flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-[0.14em] text-secondary-text">
                  <span className="text-primary">{item.icon}</span>
                  {item.label}
                </p>
                <p className="mt-1 break-words text-sm font-semibold text-foreground">
                  {item.value}
                </p>
              </div>
            ))}
          </div>

          {(reservation.estado === "pendiente" ||
            reservation.estado === "confirmada") && (
            <div className="flex flex-col-reverse gap-2 border-t border-border/70 pt-4 sm:flex-row sm:justify-end">
              <Button
                variant="ghost"
                className="text-error/80 hover:bg-error-tint hover:text-error"
                leftIcon={<LuX size={15} />}
                onClick={() => onRequestStatus(reservation, "cancelada")}
              >
                Cancelar cita
              </Button>
              {reservation.estado === "pendiente" ? (
                <Button
                  variant="secondary"
                  leftIcon={<LuCheck size={15} />}
                  onClick={() => onRequestStatus(reservation, "confirmada")}
                >
                  Confirmar cita
                </Button>
              ) : (
                <Button
                  leftIcon={<LuCheck size={15} />}
                  onClick={() => onRequestStatus(reservation, "completada")}
                >
                  Marcar completada
                </Button>
              )}
            </div>
          )}
        </div>
      )}
    </Modal>
  );
}
