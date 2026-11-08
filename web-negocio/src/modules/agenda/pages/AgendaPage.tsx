import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import {
  LuBan,
  LuCalendar,
  LuCalendarDays,
  LuCheck,
  LuChevronLeft,
  LuChevronRight,
  LuClock,
  LuFilter,
  LuPlus,
  LuRefreshCw,
  LuTrash2,
} from "react-icons/lu";
import { getProfessionals, getServices } from "../../negocio/api";
import type { Professional, Service } from "../../negocio/types";
import { createBlock, deleteBlock, getAgenda } from "../api";
import type {
  AgendaBlock,
  AgendaDay,
  AgendaResponse,
  AgendaSummary,
} from "../types";
import { statusMeta } from "../../reservas/constants";
import { useShop } from "../../shop/hooks/useShop";
import { Badge } from "../../../shared/components/ui/Badge";
import { Button } from "../../../shared/components/ui/Button";
import { Card, CardHeader } from "../../../shared/components/ui/Card";
import { Field, Input, Select, Textarea } from "../../../shared/components/ui/Field";
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
  todayIso,
} from "../../../lib/format";

const EMPTY_SUMMARY: AgendaSummary = {
  total_reservas: 0,
  pendientes: 0,
  confirmadas: 0,
  completadas: 0,
  canceladas: 0,
  dias_abiertos: 0,
  dias_bloqueados: 0,
  dias_cerrados: 0,
};

const DEFAULT_DAYS = 7;

function blockRangeLabel(block: AgendaBlock): string {
  if (block.hora_inicio && block.hora_fin) {
    return `${formatClock(block.hora_inicio)} – ${formatClock(block.hora_fin)}`;
  }
  return "Día completo";
}

export function AgendaPage() {
  const { selectedShop, selectedShopId, loading: shopLoading } = useShop();

  const [agenda, setAgenda] = useState<AgendaResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [reloadKey, setReloadKey] = useState(0);

  const [desde, setDesde] = useState(todayIso());
  const [hasta, setHasta] = useState(addDays(todayIso(), DEFAULT_DAYS - 1));
  const [servicioId, setServicioId] = useState("");
  const [profesionalId, setProfesionalId] = useState("");

  const [services, setServices] = useState<Service[]>([]);
  const [professionals, setProfessionals] = useState<Professional[]>([]);

  const [notice, setNotice] = useState<string | null>(null);
  const [blockModal, setBlockModal] = useState<{
    fecha: string;
    fullDay: boolean;
  } | null>(null);
  const [blockToDelete, setBlockToDelete] = useState<AgendaBlock | null>(null);
  const [deletingBlock, setDeletingBlock] = useState(false);
  const [deleteBlockError, setDeleteBlockError] = useState<string | null>(null);

  useEffect(() => {
    if (!selectedShopId) return;
    getServices(selectedShopId)
      .then(setServices)
      .catch(() => setServices([]));
    getProfessionals(selectedShopId)
      .then(setProfessionals)
      .catch(() => setProfessionals([]));
  }, [selectedShopId]);

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

    getAgenda(selectedShopId, {
      fecha_desde: desde || undefined,
      fecha_hasta: hasta || undefined,
      servicio_id: servicioId ? Number(servicioId) : undefined,
      profesional_id: profesionalId ? Number(profesionalId) : undefined,
    })
      .then((data) => {
        if (active) setAgenda(data);
      })
      .catch((err) => {
        if (!active) return;
        setError(
          err instanceof Error ? err.message : "No pudimos cargar la agenda.",
        );
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    return () => {
      active = false;
    };
  }, [selectedShopId, desde, hasta, servicioId, profesionalId, reloadKey]);

  function reload() {
    setReloadKey((key) => key + 1);
  }

  function applyRange(days: number) {
    const today = todayIso();
    setDesde(today);
    setHasta(addDays(today, days - 1));
  }

  function shiftRange(days: number) {
    setDesde((current) => addDays(current, days));
    setHasta((current) => addDays(current, days));
  }

  function handleDesdeChange(value: string) {
    setDesde(value);
    if (value && hasta && value > hasta) {
      setHasta(addDays(value, DEFAULT_DAYS - 1));
    }
  }

  async function handleDeleteBlock() {
    if (!selectedShopId || !blockToDelete) return;
    setDeletingBlock(true);
    setDeleteBlockError(null);
    try {
      await deleteBlock(selectedShopId, blockToDelete.id_bloqueo);
      setBlockToDelete(null);
      setNotice("Bloqueo eliminado correctamente.");
      reload();
    } catch (err) {
      setDeleteBlockError(
        err instanceof Error ? err.message : "No pudimos eliminar el bloqueo.",
      );
    } finally {
      setDeletingBlock(false);
    }
  }

  if (shopLoading || loading) {
    return <PageLoader label="Cargando la agenda..." />;
  }

  if (!selectedShopId || !selectedShop) {
    return (
      <EmptyState
        icon={<LuCalendarDays />}
        title="Primero registra tu negocio"
        description="Necesitas un negocio para consultar tu agenda y bloquear fechas."
        action={
          <Link to="/negocio/registrar">
            <Button size="sm">Registrar negocio</Button>
          </Link>
        }
      />
    );
  }

  const summary = agenda?.resumen ?? EMPTY_SUMMARY;
  const days = agenda?.dias ?? [];

  const summaryCards = [
    {
      label: "Reservas",
      value: summary.total_reservas,
      hint: "En el rango visible",
      icon: LuCalendar,
      tone: "bg-primary-tint text-primary",
    },
    {
      label: "Días abiertos",
      value: summary.dias_abiertos,
      hint: "Con atención disponible",
      icon: LuCheck,
      tone: "bg-success-tint text-success",
    },
    {
      label: "Días bloqueados",
      value: summary.dias_bloqueados,
      hint: "Cerrados por ti",
      icon: LuBan,
      tone: "bg-error-tint text-error",
    },
    {
      label: "Días cerrados",
      value: summary.dias_cerrados,
      hint: "Sin horario configurado",
      icon: LuClock,
      tone: "bg-surface-muted text-secondary-text",
    },
  ];

  return (
    <div className="space-y-5">
      <PageHeader
        eyebrow="Disponibilidad"
        title="Agenda"
        description="Consulta tus días de atención, tus reservas y bloquea fechas u horarios completos."
        actions={
          <>
            <Button
              variant="outline"
              size="sm"
              leftIcon={<LuRefreshCw size={15} />}
              onClick={reload}
            >
              Actualizar
            </Button>
            <Button
              size="sm"
              leftIcon={<LuPlus size={15} />}
              onClick={() => setBlockModal({ fecha: todayIso(), fullDay: true })}
            >
              Nuevo bloqueo
            </Button>
          </>
        }
      />

      {notice && (
        <div className="flex items-center gap-2 rounded-xl border border-success/20 bg-success-tint px-4 py-3 text-sm font-semibold text-success">
          <LuCheck size={16} />
          {notice}
        </div>
      )}

      {error && <ErrorState message={error} onRetry={reload} />}

      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        {summaryCards.map((stat) => {
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
          title="Rango y filtros"
          subtitle="Elige las fechas y el equipo para calcular la disponibilidad."
          icon={<LuFilter />}
        />
        <div className="space-y-4 p-4">
          <div className="flex flex-wrap gap-2">
            {[
              { label: "Hoy", days: 1 },
              { label: "7 días", days: 7 },
              { label: "14 días", days: 14 },
              { label: "30 días", days: 30 },
            ].map((option) => {
              const active =
                desde === todayIso() &&
                hasta === addDays(todayIso(), option.days - 1);
              return (
                <button
                  key={option.label}
                  type="button"
                  onClick={() => applyRange(option.days)}
                  className={`rounded-full border px-3.5 py-1.5 text-xs font-semibold transition-colors ${
                    active
                      ? "border-primary bg-primary text-white"
                      : "border-border bg-card text-secondary-text hover:border-primary-soft/60 hover:text-foreground"
                  }`}
                >
                  {option.label}
                </button>
              );
            })}
            <div className="ml-auto flex items-center gap-1">
              <Button
                variant="outline"
                size="sm"
                aria-label="Rango anterior"
                onClick={() => shiftRange(-DEFAULT_DAYS)}
              >
                <LuChevronLeft size={15} />
              </Button>
              <Button
                variant="outline"
                size="sm"
                aria-label="Rango siguiente"
                onClick={() => shiftRange(DEFAULT_DAYS)}
              >
                <LuChevronRight size={15} />
              </Button>
            </div>
          </div>

          <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
            <Field label="Desde" htmlFor="agenda-from">
              <Input
                id="agenda-from"
                type="date"
                value={desde}
                onChange={(event) => handleDesdeChange(event.target.value)}
              />
            </Field>
            <Field label="Hasta" htmlFor="agenda-to">
              <Input
                id="agenda-to"
                type="date"
                value={hasta}
                onChange={(event) => setHasta(event.target.value)}
              />
            </Field>
            <Field
              label="Servicio"
              htmlFor="agenda-service"
              hint="Ajusta la duración de los espacios."
            >
              <Select
                id="agenda-service"
                value={servicioId}
                onChange={(event) => setServicioId(event.target.value)}
              >
                <option value="">Duración estándar</option>
                {services
                  .filter((service) => service.estado_servicio)
                  .map((service) => (
                    <option
                      key={service.id_servicio}
                      value={service.id_servicio}
                    >
                      {service.nombre}
                    </option>
                  ))}
              </Select>
            </Field>
            <Field label="Profesional" htmlFor="agenda-professional">
              <Select
                id="agenda-professional"
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
          </div>
        </div>
      </Card>

      {days.length === 0 ? (
        <EmptyState
          icon={<LuCalendarDays />}
          title="No hay días en este rango"
          description="Ajusta las fechas para consultar la agenda de tu negocio."
          action={
            <Button size="sm" variant="outline" onClick={() => applyRange(7)}>
              Ver los próximos 7 días
            </Button>
          }
        />
      ) : (
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {days.map((day) => (
            <AgendaDayCard
              key={day.fecha}
              day={day}
              onBlockDay={() =>
                setBlockModal({ fecha: day.fecha, fullDay: true })
              }
              onBlockRange={() =>
                setBlockModal({ fecha: day.fecha, fullDay: false })
              }
              onDeleteBlock={(block) => {
                setDeleteBlockError(null);
                setBlockToDelete(block);
              }}
            />
          ))}
        </div>
      )}

      <BlockFormModal
        isOpen={Boolean(blockModal)}
        initialDate={blockModal?.fecha ?? todayIso()}
        initialFullDay={blockModal?.fullDay ?? true}
        shopId={selectedShopId}
        onClose={() => setBlockModal(null)}
        onSaved={(message) => {
          setNotice(message);
          reload();
        }}
      />

      <Modal
        isOpen={Boolean(blockToDelete)}
        onClose={() => {
          if (deletingBlock) return;
          setBlockToDelete(null);
        }}
        title="Eliminar bloqueo"
        size="sm"
      >
        {blockToDelete && (
          <div className="space-y-4">
            <p className="text-sm leading-relaxed text-secondary-text">
              ¿Eliminar el bloqueo del{" "}
              <strong className="text-foreground">
                {formatDateLong(blockToDelete.fecha)}
              </strong>{" "}
              ({blockRangeLabel(blockToDelete)})? El horario volverá a estar
              disponible.
            </p>

            {deleteBlockError && (
              <div className="rounded-xl border border-error/20 bg-error-tint px-4 py-3 text-sm font-medium text-error">
                {deleteBlockError}
              </div>
            )}

            <div className="flex flex-col-reverse gap-2 border-t border-border/70 pt-4 sm:flex-row sm:justify-end">
              <Button
                variant="outline"
                onClick={() => setBlockToDelete(null)}
                disabled={deletingBlock}
              >
                Volver
              </Button>
              <Button
                variant="danger"
                loading={deletingBlock}
                onClick={handleDeleteBlock}
              >
                Sí, eliminar
              </Button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}

function AgendaDayCard({
  day,
  onBlockDay,
  onBlockRange,
  onDeleteBlock,
}: {
  day: AgendaDay;
  onBlockDay: () => void;
  onBlockRange: () => void;
  onDeleteBlock: (block: AgendaBlock) => void;
}) {
  const freeSlots = day.disponibilidad.filter((slot) => slot.disponible);
  const status = day.bloqueado
    ? { label: "Bloqueado", tone: "danger" as const }
    : day.abierto
      ? { label: "Abierto", tone: "success" as const }
      : { label: "Cerrado", tone: "neutral" as const };

  return (
    <Card
      className={`flex flex-col p-4 ${
        !day.abierto && !day.bloqueado ? "bg-surface/50" : ""
      }`}
    >
      <div className="flex items-start justify-between gap-2">
        <div>
          <p className="text-[10px] font-bold uppercase tracking-[0.14em] text-secondary-text">
            {day.dia_semana}
          </p>
          <h3 className="font-display text-base font-bold text-foreground">
            {formatDateLong(day.fecha)}
          </h3>
        </div>
        <Badge tone={status.tone} dot>
          {status.label}
        </Badge>
      </div>

      <div className="mt-2 space-y-1 text-xs text-secondary-text">
        <p className="flex items-center gap-1.5">
          <LuClock size={13} />
          {day.horario
            ? `${formatClock(day.horario.hora_apertura)} – ${formatClock(
                day.horario.hora_cierre,
              )}`
            : "Sin horario configurado"}
        </p>
        {day.horario?.hora_descanso && (
          <p className="flex items-center gap-1.5">
            <LuClock size={13} />
            Descanso: {formatClock(day.horario.hora_descanso)}
          </p>
        )}
      </div>

      {day.reservas.length > 0 && (
        <div className="mt-3 space-y-1.5">
          <p className="text-[10px] font-bold uppercase tracking-[0.14em] text-secondary-text">
            Reservas ({day.reservas.length})
          </p>
          {day.reservas.map((reservation) => {
            const meta = statusMeta(reservation.estado);
            return (
              <div
                key={reservation.id_reserva}
                className="flex items-center gap-2 rounded-lg border border-border/60 bg-surface/60 px-2.5 py-1.5"
              >
                <span className="font-display text-xs font-bold text-foreground">
                  {formatClock(reservation.hora_inicio)}
                </span>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-xs font-semibold text-foreground">
                    {reservation.cliente_nombre}
                  </p>
                  <p className="truncate text-[10px] text-secondary-text">
                    {reservation.servicio_nombre}
                  </p>
                </div>
                <Badge tone={meta.tone}>{meta.label}</Badge>
              </div>
            );
          })}
        </div>
      )}

      {day.bloqueos.length > 0 && (
        <div className="mt-3 space-y-1.5">
          <p className="text-[10px] font-bold uppercase tracking-[0.14em] text-secondary-text">
            Bloqueos
          </p>
          {day.bloqueos.map((block) => (
            <div
              key={block.id_bloqueo}
              className="flex items-center gap-2 rounded-lg border border-error/20 bg-error-tint/60 px-2.5 py-1.5"
            >
              <LuBan size={13} className="shrink-0 text-error" />
              <div className="min-w-0 flex-1">
                <p className="text-xs font-semibold text-foreground">
                  {blockRangeLabel(block)}
                </p>
                {block.motivo && (
                  <p className="truncate text-[10px] text-secondary-text">
                    {block.motivo}
                  </p>
                )}
              </div>
              <button
                type="button"
                aria-label="Eliminar bloqueo"
                onClick={() => onDeleteBlock(block)}
                className="flex size-7 shrink-0 items-center justify-center rounded-lg text-secondary-text transition-colors hover:bg-error-tint hover:text-error"
              >
                <LuTrash2 size={13} />
              </button>
            </div>
          ))}
        </div>
      )}

      <div className="mt-3">
        <p className="text-[10px] font-bold uppercase tracking-[0.14em] text-secondary-text">
          Disponibilidad
        </p>
        {day.disponibilidad.length === 0 ? (
          <p className="mt-1 text-xs text-secondary-text">
            {day.bloqueado
              ? "Día bloqueado por el negocio."
              : day.abierto
                ? "No hay espacios disponibles."
                : "Día cerrado."}
          </p>
        ) : freeSlots.length === 0 ? (
          <p className="mt-1 text-xs text-secondary-text">
            Todos los espacios están ocupados.
          </p>
        ) : (
          <div className="mt-1.5 flex flex-wrap gap-1">
            {freeSlots.slice(0, 8).map((slot) => (
              <span
                key={slot.hora_inicio}
                className="rounded-md bg-success-tint px-1.5 py-0.5 text-[10px] font-semibold text-success"
              >
                {formatClock(slot.hora_inicio)}
              </span>
            ))}
            {freeSlots.length > 8 && (
              <span className="px-1 text-[10px] font-semibold text-secondary-text">
                +{freeSlots.length - 8}
              </span>
            )}
          </div>
        )}
      </div>

      <div className="mt-auto flex flex-wrap items-center gap-2 border-t border-border/70 pt-3">
        <Button
          variant="ghost"
          size="sm"
          leftIcon={<LuBan size={13} />}
          onClick={onBlockDay}
          disabled={day.bloqueado}
        >
          Bloquear día
        </Button>
        <Button
          variant="ghost"
          size="sm"
          leftIcon={<LuClock size={13} />}
          onClick={onBlockRange}
          disabled={day.bloqueado}
        >
          Bloquear horario
        </Button>
      </div>
    </Card>
  );
}

function BlockFormModal({
  isOpen,
  initialDate,
  initialFullDay,
  shopId,
  onClose,
  onSaved,
}: {
  isOpen: boolean;
  initialDate: string;
  initialFullDay: boolean;
  shopId: number;
  onClose: () => void;
  onSaved: (message: string) => void;
}) {
  const [fecha, setFecha] = useState(initialDate);
  const [fullDay, setFullDay] = useState(initialFullDay);
  const [horaInicio, setHoraInicio] = useState("09:00");
  const [horaFin, setHoraFin] = useState("10:00");
  const [motivo, setMotivo] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!isOpen) return;
    setFecha(initialDate);
    setFullDay(initialFullDay);
    setHoraInicio("09:00");
    setHoraFin("10:00");
    setMotivo("");
    setError(null);
  }, [isOpen, initialDate, initialFullDay]);

  async function handleSubmit() {
    setError(null);

    if (!fecha) {
      setError("Selecciona una fecha para el bloqueo.");
      return;
    }

    if (!fullDay) {
      if (!horaInicio || !horaFin) {
        setError("Indica la hora de inicio y la hora de fin.");
        return;
      }
      if (horaInicio >= horaFin) {
        setError("La hora de inicio debe ser menor que la hora de fin.");
        return;
      }
    }

    setSaving(true);
    try {
      await createBlock(shopId, {
        fecha,
        hora_inicio: fullDay ? null : horaInicio,
        hora_fin: fullDay ? null : horaFin,
        motivo: motivo.trim() || null,
      });
      onSaved(
        fullDay
          ? "Día bloqueado correctamente."
          : "Horario bloqueado correctamente.",
      );
      onClose();
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "No pudimos crear el bloqueo.",
      );
    } finally {
      setSaving(false);
    }
  }

  return (
    <Modal
      isOpen={isOpen}
      onClose={() => {
        if (saving) return;
        onClose();
      }}
      title={fullDay ? "Bloquear día completo" : "Bloquear un horario"}
      description="Los clientes no podrán reservar dentro del bloqueo."
      size="sm"
    >
      <div className="space-y-4">
        <Field label="Fecha" htmlFor="block-date" required>
          <Input
            id="block-date"
            type="date"
            min={todayIso()}
            value={fecha}
            onChange={(event) => setFecha(event.target.value)}
            disabled={saving}
          />
        </Field>

        <div className="grid grid-cols-2 gap-2">
          <button
            type="button"
            onClick={() => setFullDay(true)}
            className={`rounded-xl border px-3 py-2.5 text-xs font-semibold transition-colors ${
              fullDay
                ? "border-primary bg-primary text-white"
                : "border-border bg-card text-secondary-text hover:border-primary-soft/60 hover:text-foreground"
            }`}
          >
            Día completo
          </button>
          <button
            type="button"
            onClick={() => setFullDay(false)}
            className={`rounded-xl border px-3 py-2.5 text-xs font-semibold transition-colors ${
              !fullDay
                ? "border-primary bg-primary text-white"
                : "border-border bg-card text-secondary-text hover:border-primary-soft/60 hover:text-foreground"
            }`}
          >
            Horario específico
          </button>
        </div>

        {!fullDay && (
          <div className="grid gap-3 sm:grid-cols-2">
            <Field label="Hora de inicio" htmlFor="block-start" required>
              <Input
                id="block-start"
                type="time"
                value={horaInicio}
                onChange={(event) => setHoraInicio(event.target.value)}
                disabled={saving}
              />
            </Field>
            <Field label="Hora de fin" htmlFor="block-end" required>
              <Input
                id="block-end"
                type="time"
                value={horaFin}
                onChange={(event) => setHoraFin(event.target.value)}
                disabled={saving}
              />
            </Field>
          </div>
        )}

        <Field
          label="Motivo"
          htmlFor="block-reason"
          hint="Opcional. Solo lo verás tú."
        >
          <Textarea
            id="block-reason"
            rows={2}
            maxLength={255}
            placeholder="Ej. Vacaciones, capacitación, mantenimiento..."
            value={motivo}
            onChange={(event) => setMotivo(event.target.value)}
            disabled={saving}
          />
        </Field>

        {error && (
          <div className="rounded-xl border border-error/20 bg-error-tint px-4 py-3 text-sm font-medium text-error">
            {error}
          </div>
        )}

        <div className="flex flex-col-reverse gap-2 border-t border-border/70 pt-4 sm:flex-row sm:justify-end">
          <Button variant="outline" onClick={onClose} disabled={saving}>
            Cancelar
          </Button>
          <Button
            variant="danger"
            loading={saving}
            onClick={handleSubmit}
            leftIcon={<LuBan size={15} />}
          >
            Crear bloqueo
          </Button>
        </div>
      </div>
    </Modal>
  );
}
