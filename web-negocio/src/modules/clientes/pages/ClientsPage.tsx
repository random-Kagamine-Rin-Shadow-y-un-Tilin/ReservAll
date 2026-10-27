import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import {
  LuCalendar,
  LuMail,
  LuRefreshCw,
  LuSearch,
  LuTrendingUp,
  LuUser,
  LuUsers,
  LuWallet,
} from "react-icons/lu";
import { getClient, getClients } from "../api";
import type { Client, ClientDetail } from "../types";
import { statusMeta } from "../../reservas/constants";
import { useShop } from "../../shop/hooks/useShop";
import { Badge } from "../../../shared/components/ui/Badge";
import { Button } from "../../../shared/components/ui/Button";
import { Card, CardHeader } from "../../../shared/components/ui/Card";
import { Input } from "../../../shared/components/ui/Field";
import { PageHeader } from "../../../shared/components/ui/PageHeader";
import {
  EmptyState,
  ErrorState,
  PageLoader,
  Spinner,
} from "../../../shared/components/ui/Feedback";
import { Modal } from "../../../shared/components/Modal";
import {
  formatClock,
  formatDateLong,
  formatDateShort,
  formatMoney,
  initials,
} from "../../../lib/format";

const avatarTones = [
  "bg-primary-tint text-primary",
  "bg-secondary-tint text-secondary",
  "bg-highlight-tint text-highlight",
  "bg-surface-muted text-foreground",
];

export function ClientsPage() {
  const { selectedShop, selectedShopId, loading: shopLoading } = useShop();

  const [clients, setClients] = useState<Client[]>([]);
  const [allClients, setAllClients] = useState<Client[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadedShopId, setLoadedShopId] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [debouncedSearch, setDebouncedSearch] = useState("");
  const [reloadKey, setReloadKey] = useState(0);

  const [detailId, setDetailId] = useState<number | null>(null);
  const [detail, setDetail] = useState<ClientDetail | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [detailError, setDetailError] = useState<string | null>(null);

  useEffect(() => {
    const timer = window.setTimeout(() => setDebouncedSearch(search.trim()), 350);
    return () => window.clearTimeout(timer);
  }, [search]);

  useEffect(() => {
    if (!selectedShopId) {
      setLoading(false);
      return;
    }

    let active = true;
    setLoading(true);
    setError(null);

    getClients(selectedShopId, debouncedSearch || undefined)
      .then((data) => {
        if (!active) return;
        setClients(data.items);
        if (!debouncedSearch) setAllClients(data.items);
      })
      .catch((err) => {
        if (!active) return;
        setError(
          err instanceof Error ? err.message : "No pudimos cargar los clientes.",
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
  }, [selectedShopId, debouncedSearch, reloadKey]);

  useEffect(() => {
    if (!selectedShopId || detailId === null) return;

    let active = true;
    setDetailLoading(true);
    setDetailError(null);
    setDetail(null);

    getClient(selectedShopId, detailId)
      .then((data) => {
        if (active) setDetail(data);
      })
      .catch((err) => {
        if (!active) return;
        setDetailError(
          err instanceof Error
            ? err.message
            : "No pudimos cargar el historial del cliente.",
        );
      })
      .finally(() => {
        if (active) setDetailLoading(false);
      });

    return () => {
      active = false;
    };
  }, [selectedShopId, detailId]);

  const stats = useMemo(() => {
    const totalReservas = allClients.reduce(
      (total, client) => total + client.total_reservas,
      0,
    );
    const ingresos = allClients.reduce(
      (total, client) => total + client.total_gastado,
      0,
    );
    const frecuentes = allClients.filter(
      (client) => client.total_reservas >= 3,
    ).length;
    return {
      clientes: allClients.length,
      totalReservas,
      ingresos,
      frecuentes,
    };
  }, [allClients]);

  const clientCountLabel = `${clients.length} ${
    clients.length === 1 ? "cliente" : "clientes"
  }`;
  const clientCountState = debouncedSearch
    ? clients.length === 1
      ? "encontrado"
      : "encontrados"
    : clients.length === 1
      ? "registrado"
      : "registrados";

  function closeDetail() {
    setDetailId(null);
    setDetail(null);
    setDetailError(null);
  }

  if (shopLoading || (loading && loadedShopId !== selectedShopId)) {
    return <PageLoader label="Cargando tus clientes..." />;
  }

  if (!selectedShop) {
    return (
      <EmptyState
        icon={<LuUsers />}
        title="Primero registra tu negocio"
        description="Necesitas un negocio para conocer a las personas que reservan contigo."
        action={
          <Link to="/negocio/registrar">
            <Button size="sm">Registrar negocio</Button>
          </Link>
        }
      />
    );
  }

  return (
    <div className="space-y-5">
      <PageHeader
        eyebrow="Relaciones"
        title="Clientes"
        description="Las personas que han reservado en tu negocio, con su historial, gasto acumulado y servicio favorito."
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

      {error ? (
        <ErrorState message={error} onRetry={() => setReloadKey((key) => key + 1)} />
      ) : (
        <>
          <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
            {[
              {
                label: "Clientes",
                value: stats.clientes,
                hint: "Con al menos una reserva",
                icon: LuUsers,
                tone: "bg-primary-tint text-primary",
              },
              {
                label: "Reservas",
                value: stats.totalReservas,
                hint: "Historial acumulado",
                icon: LuCalendar,
                tone: "bg-secondary-tint text-secondary",
              },
              {
                label: "Recurrentes",
                value: stats.frecuentes,
                hint: "3 reservas o más",
                icon: LuTrendingUp,
                tone: "bg-highlight-tint text-highlight",
              },
              {
                label: "Ingresos",
                value: formatMoney(stats.ingresos, true),
                hint: "Citas completadas",
                icon: LuWallet,
                tone: "bg-success-tint text-success",
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
              title="Directorio"
              subtitle={`${clientCountLabel} ${clientCountState}`}
              icon={<LuUsers />}
              action={
                <div className="relative">
                  <LuSearch
                    size={16}
                    className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-secondary-text"
                  />
                  <Input
                    className="h-9 w-56 pl-9 text-sm"
                    placeholder="Buscar nombre o correo"
                    value={search}
                    onChange={(event) => setSearch(event.target.value)}
                  />
                </div>
              }
            />

            {clients.length === 0 ? (
              <div className="p-4">
                <EmptyState
                  icon={<LuUser />}
                  title={debouncedSearch ? "Sin coincidencias" : "Aún no tienes clientes"}
                  description={
                    debouncedSearch
                      ? "Prueba con otro nombre o correo."
                      : "Cuando tus clientes hagan su primera reserva aparecerán aquí automáticamente."
                  }
                  action={
                    debouncedSearch ? (
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => setSearch("")}
                      >
                        Limpiar búsqueda
                      </Button>
                    ) : (
                      <Link to="/reservas">
                        <Button size="sm" variant="outline">
                          Ver agenda
                        </Button>
                      </Link>
                    )
                  }
                />
              </div>
            ) : (
              <>
                <div className="hidden overflow-x-auto lg:block">
                  <table className="w-full text-left text-sm">
                    <thead className="border-b border-border/70 bg-surface/60 text-[10px] font-bold uppercase tracking-[0.14em] text-secondary-text">
                      <tr>
                        <th className="px-4 py-3">Cliente</th>
                        <th className="px-4 py-3">Reservas</th>
                        <th className="px-4 py-3">Última visita</th>
                        <th className="px-4 py-3">Gasto acumulado</th>
                        <th className="px-4 py-3">Servicio favorito</th>
                        <th className="px-4 py-3 text-right">Historial</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-border/60">
                      {clients.map((client, index) => (
                        <tr key={client.cliente_id} className="hover:bg-surface/50">
                          <td className="px-4 py-3">
                            <div className="flex items-center gap-3">
                              <span
                                className={`flex size-9 shrink-0 items-center justify-center rounded-xl text-xs font-bold ${
                                  avatarTones[index % avatarTones.length]
                                }`}
                              >
                                {initials(client.nombre)}
                              </span>
                              <div className="min-w-0">
                                <p className="truncate font-semibold text-foreground">
                                  {client.nombre}
                                </p>
                                <p className="truncate text-xs text-secondary-text">
                                  {client.correo}
                                </p>
                              </div>
                            </div>
                          </td>
                          <td className="px-4 py-3">
                            <p className="font-semibold text-foreground">
                              {client.total_reservas}
                            </p>
                            <p className="text-xs text-secondary-text">
                              {client.completadas} completadas
                            </p>
                          </td>
                          <td className="px-4 py-3 text-secondary-text">
                            {client.ultima_reserva
                              ? formatDateShort(client.ultima_reserva)
                              : "—"}
                          </td>
                          <td className="px-4 py-3 font-semibold text-foreground">
                            {formatMoney(client.total_gastado)}
                          </td>
                          <td className="px-4 py-3">
                            <Badge tone="neutral">
                              {client.servicio_favorito ?? "Sin datos"}
                            </Badge>
                          </td>
                          <td className="px-4 py-3 text-right">
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => setDetailId(client.cliente_id)}
                            >
                              Ver historial
                            </Button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>

                <div className="divide-y divide-border/60 lg:hidden">
                  {clients.map((client, index) => (
                    <div key={client.cliente_id} className="space-y-3 p-4">
                      <div className="flex items-center gap-3">
                        <span
                          className={`flex size-10 shrink-0 items-center justify-center rounded-xl text-sm font-bold ${
                            avatarTones[index % avatarTones.length]
                          }`}
                        >
                          {initials(client.nombre)}
                        </span>
                        <div className="min-w-0 flex-1">
                          <p className="truncate font-display text-base font-bold text-foreground">
                            {client.nombre}
                          </p>
                          <p className="truncate text-xs text-secondary-text">
                            {client.correo}
                          </p>
                        </div>
                      </div>
                      <div className="grid grid-cols-3 gap-2 text-center">
                        <div className="rounded-xl border border-border/70 bg-surface/60 px-2 py-2">
                          <p className="font-display text-base font-bold text-foreground">
                            {client.total_reservas}
                          </p>
                          <p className="text-[10px] text-secondary-text">Reservas</p>
                        </div>
                        <div className="rounded-xl border border-border/70 bg-surface/60 px-2 py-2">
                          <p className="font-display text-base font-bold text-foreground">
                            {formatMoney(client.total_gastado, true)}
                          </p>
                          <p className="text-[10px] text-secondary-text">Gastado</p>
                        </div>
                        <div className="rounded-xl border border-border/70 bg-surface/60 px-2 py-2">
                          <p className="font-display text-base font-bold text-foreground">
                            {client.ultima_reserva
                              ? formatDateShort(client.ultima_reserva)
                              : "—"}
                          </p>
                          <p className="text-[10px] text-secondary-text">Última</p>
                        </div>
                      </div>
                      <Button
                        variant="outline"
                        size="sm"
                        className="w-full"
                        onClick={() => setDetailId(client.cliente_id)}
                      >
                        Ver historial
                      </Button>
                    </div>
                  ))}
                </div>
              </>
            )}
          </Card>
        </>
      )}

      <Modal
        isOpen={detailId !== null}
        onClose={closeDetail}
        title="Historial del cliente"
        size="lg"
      >
        {detailLoading && (
          <div className="flex items-center justify-center gap-2 py-10 text-sm text-secondary-text">
            <Spinner /> Cargando historial...
          </div>
        )}

        {detailError && (
          <div className="rounded-xl border border-error/20 bg-error-tint px-4 py-3 text-sm font-medium text-error">
            {detailError}
          </div>
        )}

        {detail && (
          <div className="space-y-5">
            <div className="flex flex-wrap items-center gap-3">
              <span className="flex size-14 items-center justify-center rounded-2xl bg-primary-tint font-display text-lg font-extrabold text-primary">
                {initials(detail.nombre)}
              </span>
              <div className="min-w-0 flex-1">
                <p className="font-display text-xl font-bold text-foreground">
                  {detail.nombre}
                </p>
                <p className="flex items-center gap-1.5 text-sm text-secondary-text">
                  <LuMail size={14} />
                  {detail.correo}
                </p>
              </div>
              <Badge tone={detail.total_reservas >= 3 ? "gold" : "neutral"}>
                {detail.total_reservas >= 3 ? "Cliente frecuente" : "Cliente"}
              </Badge>
            </div>

            <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
              {[
                { label: "Reservas", value: detail.total_reservas },
                { label: "Completadas", value: detail.completadas },
                { label: "Canceladas", value: detail.canceladas },
                { label: "Gastado", value: formatMoney(detail.total_gastado, true) },
              ].map((item) => (
                <div
                  key={item.label}
                  className="rounded-xl border border-border/70 bg-surface/60 px-3 py-3 text-center"
                >
                  <p className="font-display text-lg font-extrabold text-foreground">
                    {item.value}
                  </p>
                  <p className="text-[10px] font-semibold uppercase tracking-wide text-secondary-text">
                    {item.label}
                  </p>
                </div>
              ))}
            </div>

            <div>
              <p className="mb-2 text-[10px] font-bold uppercase tracking-[0.16em] text-secondary-text">
                Reservas
              </p>
              {detail.reservas.length === 0 ? (
                <p className="text-sm text-secondary-text">
                  Este cliente no tiene reservas registradas.
                </p>
              ) : (
                <div className="max-h-80 space-y-2 overflow-y-auto pr-1">
                  {detail.reservas.map((reservation) => {
                    const meta = statusMeta(reservation.estado);
                    return (
                      <div
                        key={reservation.id_reserva}
                        className="flex flex-wrap items-center justify-between gap-2 rounded-xl border border-border/70 bg-card px-4 py-3"
                      >
                        <div className="min-w-0">
                          <p className="truncate text-sm font-semibold text-foreground">
                            {reservation.servicio_nombre}
                          </p>
                          <p className="text-xs text-secondary-text">
                            {formatDateLong(reservation.fecha)} ·{" "}
                            {formatClock(reservation.hora_inicio)} ·{" "}
                            {formatMoney(reservation.precio)}
                          </p>
                        </div>
                        <Badge tone={meta.tone} dot>
                          {meta.label}
                        </Badge>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
