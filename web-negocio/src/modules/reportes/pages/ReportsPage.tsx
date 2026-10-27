import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import {
  LuArrowDownRight,
  LuArrowUpRight,
  LuCalendar,
  LuClock,
  LuDownload,
  LuPercent,
  LuReceipt,
  LuRefreshCw,
  LuTrendingUp,
  LuUsers,
  LuWallet,
} from "react-icons/lu";
import { getReport } from "../api";
import type { Report } from "../types";
import { statusMeta } from "../../reservas/constants";
import type { ReservationStatus } from "../../reservas/types";
import { useShop } from "../../shop/hooks/useShop";
import { Badge } from "../../../shared/components/ui/Badge";
import { Button } from "../../../shared/components/ui/Button";
import { Card, CardHeader } from "../../../shared/components/ui/Card";
import { Field, Input } from "../../../shared/components/ui/Field";
import { PageHeader } from "../../../shared/components/ui/PageHeader";
import {
  EmptyState,
  ErrorState,
  PageLoader,
} from "../../../shared/components/ui/Feedback";
import {
  addDays,
  formatDateShort,
  formatMoney,
  formatRangeLabel,
  monthEnd,
  monthStart,
  percentChange,
  todayIso,
} from "../../../lib/format";

type Preset = "7d" | "30d" | "90d" | "mes" | "mes-anterior" | "personalizado";
type ChartMetric = "reservas" | "ingresos";

const PRESETS: { value: Preset; label: string }[] = [
  { value: "7d", label: "7 días" },
  { value: "30d", label: "30 días" },
  { value: "90d", label: "90 días" },
  { value: "mes", label: "Este mes" },
  { value: "mes-anterior", label: "Mes anterior" },
];

const STATUS_BAR_TONE: Record<ReservationStatus, string> = {
  pendiente: "bg-highlight",
  confirmada: "bg-secondary",
  completada: "bg-success",
  cancelada: "bg-error",
};

function presetRange(preset: Preset): { desde: string; hasta: string } {
  const today = todayIso();
  if (preset === "7d") return { desde: addDays(today, -6), hasta: today };
  if (preset === "90d") return { desde: addDays(today, -89), hasta: today };
  if (preset === "mes") return { desde: monthStart(today), hasta: monthEnd(today) };
  if (preset === "mes-anterior") {
    const lastOfPrevious = addDays(monthStart(today), -1);
    return {
      desde: monthStart(lastOfPrevious),
      hasta: lastOfPrevious,
    };
  }
  return { desde: addDays(today, -29), hasta: today };
}

function csvValue(value: string | number): string {
  return `"${String(value).replace(/"/g, '""')}"`;
}

function downloadReport(report: Report) {
  const rows: (string | number)[][] = [
    ["Reporte de reservas - ReservAll"],
    ["Periodo", report.rango.desde, report.rango.hasta],
    [],
    ["Reservas", report.totales.reservas],
    ["Completadas", report.totales.completadas],
    ["Canceladas", report.totales.canceladas],
    ["Pendientes", report.totales.pendientes],
    ["Confirmadas", report.totales.confirmadas],
    ["Ingresos", report.totales.ingresos],
    ["Ticket promedio", report.totales.ticket_promedio],
    ["Tasa de cancelacion (%)", report.totales.tasa_cancelacion],
    ["Clientes unicos", report.totales.clientes_unicos],
    [],
    ["Fecha", "Reservas", "Completadas", "Canceladas", "Ingresos"],
    ...report.diario.map((point) => [
      point.fecha,
      point.total,
      point.completadas,
      point.canceladas,
      point.ingresos,
    ]),
    [],
    ["Servicio", "Reservas", "Completadas", "Ingresos"],
    ...report.servicios_top.map((service) => [
      service.nombre,
      service.reservas,
      service.completadas,
      service.ingresos,
    ]),
    [],
    ["Profesional", "Reservas", "Completadas", "Ingresos"],
    ...report.profesionales_top.map((professional) => [
      professional.nombre,
      professional.reservas,
      professional.completadas,
      professional.ingresos,
    ]),
  ];

  const csv = rows.map((row) => row.map(csvValue).join(",")).join("\r\n");
  const blob = new Blob([`\ufeff${csv}`], {
    type: "text/csv;charset=utf-8;",
  });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = `reporte-reservall-${report.rango.desde}-${report.rango.hasta}.csv`;
  document.body.appendChild(anchor);
  anchor.click();
  document.body.removeChild(anchor);
  URL.revokeObjectURL(url);
}

function Delta({
  current,
  previous,
  invert = false,
  unit = "percent",
}: {
  current: number;
  previous: number;
  invert?: boolean;
  unit?: "percent" | "points";
}) {
  if (unit === "points") {
    const diff = current - previous;
    if (current === 0 && previous === 0) {
      return (
        <span className="text-[11px] font-medium text-secondary-text">
          Sin datos comparables
        </span>
      );
    }
    if (diff === 0) {
      return (
        <span className="text-[11px] font-medium text-secondary-text">
          Sin cambios vs. periodo anterior
        </span>
      );
    }
    const good = invert ? diff <= 0 : diff >= 0;
    return (
      <span
        className={`inline-flex items-center gap-0.5 text-[11px] font-semibold ${
          good ? "text-success" : "text-error"
        }`}
      >
        {diff >= 0 ? <LuArrowUpRight size={12} /> : <LuArrowDownRight size={12} />}
        {diff >= 0 ? "+" : ""}
        {diff.toFixed(1)} pp vs. periodo anterior
      </span>
    );
  }

  const change = percentChange(current, previous);
  if (change === null) {
    return (
      <span className="text-[11px] font-medium text-secondary-text">
        Sin periodo anterior comparable
      </span>
    );
  }

  if (current === 0 && previous === 0) {
    return (
      <span className="text-[11px] font-medium text-secondary-text">
        Sin datos comparables
      </span>
    );
  }

  if (change === 0) {
    return (
      <span className="text-[11px] font-medium text-secondary-text">
        Sin cambios vs. periodo anterior
      </span>
    );
  }

  const good = invert ? change <= 0 : change >= 0;
  return (
    <span
      className={`inline-flex items-center gap-0.5 text-[11px] font-semibold ${
        good ? "text-success" : "text-error"
      }`}
    >
      {change >= 0 ? <LuArrowUpRight size={12} /> : <LuArrowDownRight size={12} />}
      {change >= 0 ? "+" : ""}
      {change.toFixed(1)}% vs. periodo anterior
    </span>
  );
}

export function ReportsPage() {
  const { selectedShop, selectedShopId, loading: shopLoading } = useShop();

  const initialRange = presetRange("30d");
  const [preset, setPreset] = useState<Preset>("30d");
  const [desde, setDesde] = useState(initialRange.desde);
  const [hasta, setHasta] = useState(initialRange.hasta);
  const [metric, setMetric] = useState<ChartMetric>("reservas");
  const [report, setReport] = useState<Report | null>(null);
  const [loading, setLoading] = useState(true);
  const [loadedShopId, setLoadedShopId] = useState<number | null>(null);
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

    getReport(selectedShopId, desde, hasta)
      .then((data) => {
        if (active) setReport(data);
      })
      .catch((err) => {
        if (!active) return;
        setError(
          err instanceof Error ? err.message : "No pudimos generar el reporte.",
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
  }, [selectedShopId, desde, hasta, reloadKey]);

  function applyPreset(next: Preset) {
    setPreset(next);
    const range = presetRange(next);
    setDesde(range.desde);
    setHasta(range.hasta);
  }

  if (shopLoading || (loading && loadedShopId !== selectedShopId)) {
    return <PageLoader label="Calculando tus métricas..." />;
  }

  if (!selectedShop) {
    return (
      <EmptyState
        icon={<LuTrendingUp />}
        title="Primero registra tu negocio"
        description="Necesitas un negocio con reservas para generar reportes."
        action={
          <Link to="/negocio/registrar">
            <Button size="sm">Registrar negocio</Button>
          </Link>
        }
      />
    );
  }

  if (error || !report) {
    return (
      <div className="space-y-5">
        <PageHeader
          eyebrow="Análisis"
          title="Reportes"
          description="Ingresos, demanda y rendimiento de tu negocio."
        />
        <ErrorState
          message={error ?? "No pudimos generar el reporte."}
          onRetry={() => setReloadKey((key) => key + 1)}
        />
      </div>
    );
  }

  const totals = report.totales;
  const comparison = report.comparacion;
  const hasActivity = totals.reservas > 0;
  const maxDaily = Math.max(
    1,
    ...report.diario.map((point) =>
      metric === "reservas" ? point.total : point.ingresos,
    ),
  );
  const labelEvery = Math.max(1, Math.ceil(report.diario.length / 8));
  const chartMinWidth = Math.max(640, report.diario.length * 22);
  const maxWeekday = Math.max(1, ...report.dias_semana.map((day) => day.total));
  const maxHour = Math.max(1, ...report.horas_pico.map((hour) => hour.total));
  const maxService = Math.max(
    1,
    ...report.servicios_top.map((service) => service.reservas),
  );
  const maxProfessional = Math.max(
    1,
    ...report.profesionales_top.map((professional) => professional.reservas),
  );

  const kpis = [
    {
      label: "Reservas",
      value: totals.reservas.toString(),
      hint: "En el periodo",
      icon: LuCalendar,
      tone: "bg-primary-tint text-primary",
      delta: (
        <Delta current={totals.reservas} previous={comparison.reservas} />
      ),
    },
    {
      label: "Ingresos",
      value: formatMoney(totals.ingresos, true),
      hint: "Reservas completadas",
      icon: LuWallet,
      tone: "bg-success-tint text-success",
      delta: (
        <Delta current={totals.ingresos} previous={comparison.ingresos} />
      ),
    },
    {
      label: "Ticket promedio",
      value: formatMoney(totals.ticket_promedio, true),
      hint: "Por cita completada",
      icon: LuReceipt,
      tone: "bg-secondary-tint text-secondary",
      delta: (
        <Delta
          current={totals.ticket_promedio}
          previous={comparison.ticket_promedio}
        />
      ),
    },
    {
      label: "Cancelación",
      value: `${totals.tasa_cancelacion.toFixed(1)}%`,
      hint: "Sobre el total de citas",
      icon: LuPercent,
      tone: "bg-error-tint text-error",
      delta: (
        <Delta
          current={totals.tasa_cancelacion}
          previous={comparison.tasa_cancelacion}
          invert
          unit="points"
        />
      ),
    },
    {
      label: "Clientes",
      value: totals.clientes_unicos.toString(),
      hint: "Personas atendidas",
      icon: LuUsers,
      tone: "bg-highlight-tint text-highlight",
      delta: (
        <Delta
          current={totals.clientes_unicos}
          previous={comparison.clientes_unicos}
        />
      ),
    },
  ];

  return (
    <div className="space-y-5">
      <PageHeader
        eyebrow="Análisis"
        title="Reportes"
        description="Una lectura clara de tus ingresos, la demanda por día y el rendimiento de tu equipo."
        actions={
          <>
            <Button
              variant="outline"
              size="sm"
              leftIcon={<LuRefreshCw size={15} />}
              onClick={() => setReloadKey((key) => key + 1)}
            >
              Actualizar
            </Button>
            <Button
              size="sm"
              leftIcon={<LuDownload size={15} />}
              onClick={() => downloadReport(report)}
            >
              Exportar CSV
            </Button>
          </>
        }
      />

      <Card>
        <CardHeader
          title="Periodo"
          subtitle={formatRangeLabel(report.rango.desde, report.rango.hasta)}
          icon={<LuCalendar />}
          action={<Badge tone="neutral">{report.rango.dias} días</Badge>}
        />
        <div className="space-y-4 p-4">
          <div className="flex flex-wrap gap-2">
            {PRESETS.map((option) => (
              <button
                key={option.value}
                type="button"
                onClick={() => applyPreset(option.value)}
                className={`rounded-full border px-3.5 py-1.5 text-xs font-semibold transition-colors ${
                  preset === option.value
                    ? "border-primary bg-primary text-white"
                    : "border-border bg-card text-secondary-text hover:border-primary-soft/60 hover:text-foreground"
                }`}
              >
                {option.label}
              </button>
            ))}
            {preset === "personalizado" && (
              <Badge tone="primary">Rango personalizado</Badge>
            )}
          </div>
          <div className="grid gap-3 sm:grid-cols-2">
            <Field label="Desde" htmlFor="report-from">
              <Input
                id="report-from"
                type="date"
                value={desde}
                max={hasta}
                onChange={(event) => {
                  const value = event.target.value;
                  setDesde(value);
                  if (value && value > hasta) setHasta(value);
                  setPreset("personalizado");
                }}
              />
            </Field>
            <Field label="Hasta" htmlFor="report-to">
              <Input
                id="report-to"
                type="date"
                value={hasta}
                min={desde}
                onChange={(event) => {
                  const value = event.target.value;
                  setHasta(value);
                  if (value && value < desde) setDesde(value);
                  setPreset("personalizado");
                }}
              />
            </Field>
          </div>
        </div>
      </Card>

      <div className="grid gap-3 sm:grid-cols-2 md:grid-cols-3 xl:grid-cols-5">
        {kpis.map((kpi) => {
          const Icon = kpi.icon;
          return (
            <Card key={kpi.label} className="p-5">
              <div className="flex items-start justify-between">
                <span className={`flex size-10 items-center justify-center rounded-xl text-lg ${kpi.tone}`}>
                  <Icon />
                </span>
                <span className="text-[10px] font-bold uppercase tracking-[0.14em] text-secondary-text">
                  {kpi.label}
                </span>
              </div>
              <p className="mt-4 font-display text-2xl font-extrabold text-foreground">
                {kpi.value}
              </p>
              <p className="mb-2 text-xs text-secondary-text">{kpi.hint}</p>
              {kpi.delta}
            </Card>
          );
        })}
      </div>

      {!hasActivity ? (
        <EmptyState
          icon={<LuTrendingUp />}
          title="Sin actividad en este periodo"
          description="No hay reservas registradas para estas fechas. Prueba con un rango más amplio para ver tus métricas."
          action={
            <Button size="sm" onClick={() => applyPreset("90d")}>
              Ver últimos 90 días
            </Button>
          }
        />
      ) : (
        <>
          <Card>
            <CardHeader
              title="Actividad diaria"
              subtitle={
                metric === "reservas"
                  ? "Reservas totales y completadas por día"
                  : "Ingresos por día (solo citas completadas)"
              }
              icon={<LuCalendar />}
              action={
                <div className="flex rounded-lg border border-border bg-surface p-0.5">
                  {[
                    { value: "reservas" as ChartMetric, label: "Reservas" },
                    { value: "ingresos" as ChartMetric, label: "Ingresos" },
                  ].map((option) => (
                    <button
                      key={option.value}
                      type="button"
                      onClick={() => setMetric(option.value)}
                      className={`rounded-md px-3 py-1.5 text-xs font-semibold transition-colors ${
                        metric === option.value
                          ? "bg-card text-foreground shadow-soft"
                          : "text-secondary-text hover:text-foreground"
                      }`}
                    >
                      {option.label}
                    </button>
                  ))}
                </div>
              }
            />
            <div className="p-4">
              <div className="overflow-x-auto pb-2">
                <div
                  className="flex items-end gap-1"
                  style={{ minWidth: chartMinWidth }}
                >
                  {report.diario.map((point, index) => {
                    const value = metric === "reservas" ? point.total : point.ingresos;
                    const height = (value / maxDaily) * 100;
                    const completedHeight =
                      metric === "reservas" && point.total > 0
                        ? (point.completadas / point.total) * 100
                        : 0;
                    const showLabel =
                      index === report.diario.length - 1 ||
                      (index % labelEvery === 0 &&
                        report.diario.length - 1 - index >= 2);
                    return (
                      <div
                        key={point.fecha}
                        className="group flex min-w-0 flex-1 flex-col items-center gap-1.5"
                        title={`${point.fecha}: ${point.total} reservas · ${point.completadas} completadas · ${formatMoney(
                          point.ingresos,
                        )}`}
                      >
                        <div className="flex h-44 w-full items-end justify-center">
                          {value > 0 ? (
                            <div
                              className={`relative w-full max-w-8 rounded-t-md transition-opacity group-hover:opacity-80 ${
                                metric === "reservas"
                                  ? "bg-primary/20"
                                  : "bg-gradient-to-t from-secondary to-secondary-soft"
                              }`}
                              style={{ height: `${Math.max(height, 2)}%` }}
                            >
                              {metric === "reservas" && completedHeight > 0 && (
                                <div
                                  className="absolute bottom-0 left-0 w-full rounded-t-md bg-secondary"
                                  style={{ height: `${completedHeight}%` }}
                                />
                              )}
                            </div>
                          ) : (
                            <div className="h-0.5 w-full max-w-8 rounded-full bg-border" />
                          )}
                        </div>
                        <span className="h-4 whitespace-nowrap text-[9px] font-medium text-secondary-text">
                          {showLabel ? formatDateShort(point.fecha) : ""}
                        </span>
                      </div>
                    );
                  })}
                </div>
              </div>
              <div className="mt-3 flex flex-wrap items-center gap-4 border-t border-border/60 pt-3 text-[11px] font-medium text-secondary-text">
                {metric === "reservas" ? (
                  <>
                    <span className="flex items-center gap-1.5">
                      <span className="size-2.5 rounded-sm bg-primary/20" />
                      Reservas totales
                    </span>
                    <span className="flex items-center gap-1.5">
                      <span className="size-2.5 rounded-sm bg-secondary" />
                      Completadas
                    </span>
                  </>
                ) : (
                  <span className="flex items-center gap-1.5">
                    <span className="size-2.5 rounded-sm bg-secondary" />
                    Ingresos completados
                  </span>
                )}
                <span className="ml-auto">
                  Máximo: {metric === "reservas" ? maxDaily : formatMoney(maxDaily)}
                </span>
              </div>
            </div>
          </Card>

          <div className="grid gap-5 xl:grid-cols-2">
            <Card>
              <CardHeader
                title="Demanda por día"
                subtitle="Qué días de la semana concentran más citas"
                icon={<LuCalendar />}
              />
              <div className="space-y-3 p-4">
                {report.dias_semana.map((day) => (
                  <div key={day.dia} className="flex items-center gap-3">
                    <span className="w-20 shrink-0 text-xs font-semibold text-foreground">
                      {day.label}
                    </span>
                    <div className="h-2.5 flex-1 overflow-hidden rounded-full bg-surface-muted">
                      <div
                        className="h-full rounded-full bg-gradient-to-r from-primary to-primary-soft"
                        style={{ width: `${(day.total / maxWeekday) * 100}%` }}
                      />
                    </div>
                    <span className="w-24 shrink-0 text-right text-xs font-medium text-secondary-text">
                      {day.total} · {formatMoney(day.ingresos, true)}
                    </span>
                  </div>
                ))}
              </div>
            </Card>

            <Card>
              <CardHeader
                title="Horas con más demanda"
                subtitle="Horarios en los que más te reservan"
                icon={<LuClock />}
              />
              {report.horas_pico.length === 0 ? (
                <p className="p-4 text-sm text-secondary-text">
                  Aún no hay suficientes reservas para calcular horarios.
                </p>
              ) : (
                <div className="space-y-3 p-4">
                  {report.horas_pico.map((hour) => (
                    <div key={hour.hora} className="flex items-center gap-3">
                      <span className="w-14 shrink-0 text-xs font-semibold text-foreground">
                        {String(hour.hora).padStart(2, "0")}:00
                      </span>
                      <div className="h-2.5 flex-1 overflow-hidden rounded-full bg-surface-muted">
                        <div
                          className="h-full rounded-full bg-gradient-to-r from-secondary to-secondary-soft"
                          style={{ width: `${(hour.total / maxHour) * 100}%` }}
                        />
                      </div>
                      <span className="w-8 shrink-0 text-right text-xs font-medium text-secondary-text">
                        {hour.total}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </Card>
          </div>

          <div className="grid gap-5 xl:grid-cols-2">
            <Card>
              <CardHeader
                title="Servicios más solicitados"
                subtitle="Reservas e ingresos por servicio"
                icon={<LuReceipt />}
              />
              <div className="space-y-4 p-4">
                {report.servicios_top.length === 0 ? (
                  <p className="text-sm text-secondary-text">
                    No hay servicios con reservas en este periodo.
                  </p>
                ) : (
                  report.servicios_top.map((service, index) => (
                    <div key={service.servicio_id}>
                      <div className="mb-1.5 flex items-center justify-between gap-2">
                        <p className="flex min-w-0 items-center gap-2 text-sm font-semibold text-foreground">
                          <span className="flex size-5 shrink-0 items-center justify-center rounded-full bg-primary-tint text-[10px] font-bold text-primary">
                            {index + 1}
                          </span>
                          <span className="truncate">{service.nombre}</span>
                        </p>
                        <span className="shrink-0 text-xs font-medium text-secondary-text">
                          {service.reservas} · {formatMoney(service.ingresos, true)}
                        </span>
                      </div>
                      <div className="h-2 overflow-hidden rounded-full bg-surface-muted">
                        <div
                          className="h-full rounded-full bg-gradient-to-r from-highlight to-highlight-soft"
                          style={{
                            width: `${(service.reservas / maxService) * 100}%`,
                          }}
                        />
                      </div>
                    </div>
                  ))
                )}
              </div>
            </Card>

            <Card>
              <CardHeader
                title="Rendimiento del equipo"
                subtitle="Citas atendidas por profesional"
                icon={<LuUsers />}
              />
              <div className="space-y-4 p-4">
                {report.profesionales_top.length === 0 ? (
                  <p className="text-sm text-secondary-text">
                    Asigna profesionales a las reservas para ver su rendimiento.
                  </p>
                ) : (
                  report.profesionales_top.map((professional, index) => (
                    <div key={professional.profesional_id}>
                      <div className="mb-1.5 flex items-center justify-between gap-2">
                        <p className="flex min-w-0 items-center gap-2 text-sm font-semibold text-foreground">
                          <span className="flex size-5 shrink-0 items-center justify-center rounded-full bg-secondary-tint text-[10px] font-bold text-secondary">
                            {index + 1}
                          </span>
                          <span className="truncate">{professional.nombre}</span>
                        </p>
                        <span className="shrink-0 text-xs font-medium text-secondary-text">
                          {professional.reservas} ·{" "}
                          {formatMoney(professional.ingresos, true)}
                        </span>
                      </div>
                      <div className="h-2 overflow-hidden rounded-full bg-surface-muted">
                        <div
                          className="h-full rounded-full bg-gradient-to-r from-secondary to-secondary-soft"
                          style={{
                            width: `${(professional.reservas / maxProfessional) * 100}%`,
                          }}
                        />
                      </div>
                    </div>
                  ))
                )}
              </div>
            </Card>
          </div>

          <Card>
            <CardHeader
              title="Distribución por estado"
              subtitle="Cómo terminaron las citas del periodo"
              icon={<LuPercent />}
            />
            <div className="grid gap-3 p-4 sm:grid-cols-2 xl:grid-cols-4">
              {report.estados.map((item) => {
                const meta = statusMeta(item.estado);
                const percent =
                  totals.reservas > 0 ? (item.total / totals.reservas) * 100 : 0;
                return (
                  <div
                    key={item.estado}
                    className="rounded-xl border border-border/70 bg-surface/60 p-4"
                  >
                    <div className="flex items-center justify-between gap-2">
                      <Badge tone={meta.tone} dot>
                        {meta.label}
                      </Badge>
                      <span className="font-display text-xl font-extrabold text-foreground">
                        {item.total}
                      </span>
                    </div>
                    <div className="mt-3 h-1.5 overflow-hidden rounded-full bg-surface-muted">
                      <div
                        className={`h-full rounded-full ${STATUS_BAR_TONE[item.estado]}`}
                        style={{ width: `${percent}%` }}
                      />
                    </div>
                    <p className="mt-1.5 text-[10px] font-medium text-secondary-text">
                      {percent.toFixed(1)}% del total
                    </p>
                  </div>
                );
              })}
            </div>
          </Card>
        </>
      )}
    </div>
  );
}
