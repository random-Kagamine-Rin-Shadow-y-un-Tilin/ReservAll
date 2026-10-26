import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import {
  LuCalendar,
  LuClock,
  LuInfo,
  LuPencil,
  LuPlus,
  LuTrash2,
} from "react-icons/lu";
import { deleteSchedule, getSchedule } from "../api";
import { WEEK_DAYS, formatTime } from "../constants";
import type { Schedule } from "../types";
import { useShop } from "../../shop/hooks/useShop";
import { Badge } from "../../../shared/components/ui/Badge";
import { Button } from "../../../shared/components/ui/Button";
import { Card } from "../../../shared/components/ui/Card";
import { PageHeader } from "../../../shared/components/ui/PageHeader";
import {
  EmptyState,
  ErrorState,
  PageLoader,
} from "../../../shared/components/ui/Feedback";
import { Modal } from "../../../shared/components/Modal";
import { ScheduleFormModal } from "../components/ScheduleFormModal";

function todayValue(): string {
  const index = new Date().getDay();
  return ["domingo", "lunes", "martes", "miercoles", "jueves", "viernes", "sabado"][
    index
  ];
}

export function SchedulesPage() {
  const { selectedShop, selectedShopId, loading: shopLoading } = useShop();
  const [schedule, setSchedule] = useState<Schedule[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Schedule | null>(null);
  const [toDelete, setToDelete] = useState<Schedule | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [deleteError, setDeleteError] = useState<string | null>(null);
  const [reloadKey, setReloadKey] = useState(0);

  useEffect(() => {
    if (!selectedShopId) {
      setLoading(false);
      return;
    }

    let active = true;
    setLoading(true);
    setError(null);

    getSchedule(selectedShopId)
      .then((data) => {
        if (active) setSchedule(data);
      })
      .catch((err) => {
        if (!active) return;
        setError(
          err instanceof Error ? err.message : "No pudimos cargar los horarios.",
        );
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    return () => {
      active = false;
    };
  }, [selectedShopId, reloadKey]);

  async function reload() {
    setReloadKey((key) => key + 1);
  }

  function openCreate() {
    setEditing(null);
    setModalOpen(true);
  }

  function openEdit(entry: Schedule) {
    setEditing(entry);
    setModalOpen(true);
  }

  async function handleDelete() {
    if (!selectedShopId || !toDelete) return;
    setDeleting(true);
    setDeleteError(null);
    try {
      await deleteSchedule(selectedShopId, toDelete.id_horario);
      setToDelete(null);
      await reload();
    } catch (err) {
      setDeleteError(
        err instanceof Error ? err.message : "No pudimos eliminar el horario.",
      );
    } finally {
      setDeleting(false);
    }
  }

  if (shopLoading || loading) {
    return <PageLoader label="Cargando tus horarios..." />;
  }

  if (!selectedShop) {
    return (
      <EmptyState
        icon={<LuCalendar />}
        title="Primero registra tu negocio"
        description="Necesitas un negocio para configurar tus horarios."
        action={
          <Link to="/negocio/registrar">
            <Button size="sm">Registrar negocio</Button>
          </Link>
        }
      />
    );
  }

  const today = todayValue();
  const existingDays = schedule.map((entry) => entry.dia);

  return (
    <div>
      <PageHeader
        eyebrow="Disponibilidad"
        title="Horarios"
        description="Define los días y horas en que tu negocio atiende. Esta información se usará para calcular los espacios reservables."
        actions={
          <Button
            leftIcon={<LuPlus size={16} />}
            onClick={openCreate}
            disabled={schedule.length >= 7}
          >
            Añadir horario
          </Button>
        }
      />

      {error ? (
        <ErrorState message={error} onRetry={reload} />
      ) : (
        <div className="space-y-5">
          <div className="flex flex-wrap items-center gap-2">
            <Badge tone="primary">{schedule.length} de 7 días</Badge>
            {schedule.length === 7 ? (
              <Badge tone="success" dot>
                Semana completa
              </Badge>
            ) : (
              <Badge tone="gold">
                {7 - schedule.length === 1
                  ? "Falta 1 día por configurar"
                  : `Faltan ${7 - schedule.length} días por configurar`}
              </Badge>
            )}
          </div>

          <div className="flex items-start gap-2.5 rounded-xl border border-border bg-surface/70 px-4 py-3">
            <LuInfo size={17} className="mt-0.5 shrink-0 text-primary" />
            <p className="text-xs leading-relaxed text-secondary-text">
              La hora de descanso es opcional y sirve para bloquear un receso dentro del
              horario de atención.
            </p>
          </div>

          {schedule.length === 0 ? (
            <EmptyState
              icon={<LuClock />}
              title="Aún no tienes horarios"
              description="Registra al menos un día de atención para que tus servicios tengan disponibilidad."
              action={
                <Button
                  size="sm"
                  leftIcon={<LuPlus size={15} />}
                  onClick={openCreate}
                >
                  Configurar horario
                </Button>
              }
            />
          ) : (
            <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
              {WEEK_DAYS.map((day) => {
                const entry = schedule.find((item) => item.dia === day.value);
                const isToday = day.value === today;

                return (
                  <Card
                    key={day.value}
                    className={`p-5 transition-shadow ${
                      entry ? "hover:shadow-lift" : "border-dashed bg-surface/50"
                    } ${isToday ? "ring-2 ring-primary-soft/40" : ""}`}
                  >
                    <div className="flex items-start justify-between gap-2">
                      <div className="flex items-center gap-3">
                        <span
                          className={`flex size-10 items-center justify-center rounded-xl font-display text-xs font-extrabold ${
                            entry
                              ? "bg-primary-tint text-primary"
                              : "bg-surface-muted text-secondary-text"
                          }`}
                        >
                          {day.short}
                        </span>
                        <div>
                          <h3 className="font-display text-base font-bold text-foreground">
                            {day.label}
                          </h3>
                          {isToday ? (
                            <p className="text-[10px] font-bold uppercase tracking-wide text-primary">
                              Hoy
                            </p>
                          ) : (
                            <p className="text-[10px] text-secondary-text">
                              {entry ? "Día laboral" : "Sin configurar"}
                            </p>
                          )}
                        </div>
                      </div>
                      {entry ? (
                        <Badge tone="success" dot>
                          Abierto
                        </Badge>
                      ) : (
                        <Badge tone="neutral">Cerrado</Badge>
                      )}
                    </div>

                    {entry ? (
                      <>
                        <div className="mt-4 rounded-xl bg-surface px-3 py-2.5">
                          <p className="text-[10px] font-bold uppercase tracking-wide text-secondary-text">
                            Horario de atención
                          </p>
                          <p className="mt-0.5 font-display text-lg font-extrabold text-foreground">
                            {formatTime(entry.hora_apertura)} –{" "}
                            {formatTime(entry.hora_cierre)}
                          </p>
                          <p className="mt-0.5 text-[11px] text-secondary-text">
                            Descanso:{" "}
                            {entry.hora_descanso
                              ? formatTime(entry.hora_descanso)
                              : "Sin descanso"}
                          </p>
                        </div>

                        <div className="mt-3 flex items-center gap-1">
                          <Button
                            variant="ghost"
                            size="sm"
                            leftIcon={<LuPencil size={13} />}
                            onClick={() => openEdit(entry)}
                          >
                            Editar
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            className="ml-auto text-error/80 hover:bg-error-tint hover:text-error"
                            leftIcon={<LuTrash2 size={13} />}
                            onClick={() => {
                              setDeleteError(null);
                              setToDelete(entry);
                            }}
                          >
                            Eliminar
                          </Button>
                        </div>
                      </>
                    ) : (
                      <Button
                        variant="outline"
                        size="sm"
                        className="mt-4 w-full"
                        leftIcon={<LuPlus size={14} />}
                        onClick={openCreate}
                      >
                        Configurar {day.label}
                      </Button>
                    )}
                  </Card>
                );
              })}
            </div>
          )}
        </div>
      )}

      {selectedShopId && (
        <ScheduleFormModal
          isOpen={modalOpen}
          onClose={() => setModalOpen(false)}
          shopId={selectedShopId}
          schedule={editing}
          existingDays={existingDays}
          onSaved={reload}
        />
      )}

      <Modal
        isOpen={Boolean(toDelete)}
        onClose={() => setToDelete(null)}
        title="Eliminar horario"
        size="sm"
      >
        <div className="space-y-4">
          <p className="text-sm leading-relaxed text-secondary-text">
            ¿Eliminar el horario del{" "}
            <strong className="text-foreground">
              {WEEK_DAYS.find((day) => day.value === toDelete?.dia)?.label ??
                toDelete?.dia}
            </strong>
            ? Ese día quedará cerrado.
          </p>

          {deleteError && (
            <div className="rounded-xl border border-error/20 bg-error-tint px-4 py-3 text-sm font-medium text-error">
              {deleteError}
            </div>
          )}

          <div className="flex flex-col-reverse gap-2 border-t border-border/70 pt-4 sm:flex-row sm:justify-end">
            <Button variant="outline" onClick={() => setToDelete(null)}>
              Cancelar
            </Button>
            <Button variant="danger" loading={deleting} onClick={handleDelete}>
              Sí, eliminar
            </Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
