import { useEffect, useState } from "react";
import { LuClock } from "react-icons/lu";
import { Modal } from "../../../shared/components/Modal";
import { Button } from "../../../shared/components/ui/Button";
import { Field, Input, Select } from "../../../shared/components/ui/Field";
import { createSchedule, editSchedule } from "../api";
import { WEEK_DAYS, formatTime } from "../constants";
import type { Schedule } from "../types";

interface ScheduleFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  shopId: number;
  schedule?: Schedule | null;
  existingDays: string[];
  onSaved: () => Promise<void> | void;
}

export function ScheduleFormModal({
  isOpen,
  onClose,
  shopId,
  schedule,
  existingDays,
  onSaved,
}: ScheduleFormModalProps) {
  const [dia, setDia] = useState("");
  const [apertura, setApertura] = useState("09:00");
  const [cierre, setCierre] = useState("18:00");
  const [descanso, setDescanso] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const isEditing = Boolean(schedule);
  const availableDays = WEEK_DAYS.filter((day) => !existingDays.includes(day.value));

  useEffect(() => {
    if (!isOpen) return;
    setDia(schedule?.dia ?? availableDays[0]?.value ?? "");
    setApertura(schedule ? formatTime(schedule.hora_apertura) : "09:00");
    setCierre(schedule ? formatTime(schedule.hora_cierre) : "18:00");
    setDescanso(schedule?.hora_descanso ? formatTime(schedule.hora_descanso) : "");
    setError(null);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isOpen, schedule]);

  async function handleSubmit() {
    setError(null);

    if (!isEditing && !dia) {
      setError("Selecciona un día de la semana.");
      return;
    }
    if (!apertura || !cierre) {
      setError("La hora de apertura y cierre son obligatorias.");
      return;
    }
    if (apertura >= cierre) {
      setError("La hora de apertura debe ser menor que la de cierre.");
      return;
    }

    setLoading(true);
    try {
      if (schedule) {
        await editSchedule(shopId, schedule.id_horario, {
          hora_apertura: apertura,
          hora_cierre: cierre,
          hora_descanso: descanso || null,
        });
      } else {
        await createSchedule(shopId, {
          dia,
          hora_apertura: apertura,
          hora_cierre: cierre,
          hora_descanso: descanso || null,
        });
      }
      await onSaved();
      onClose();
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "No pudimos guardar el horario.",
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={isEditing ? "Editar horario" : "Añadir horario"}
      description={
        isEditing
          ? `Ajusta la disponibilidad del ${WEEK_DAYS.find((day) => day.value === schedule?.dia)?.label ?? "día"}.`
          : "Configura la apertura y el cierre de un día de la semana."
      }
      size="sm"
    >
      <div className="space-y-4">
        {!isEditing && (
          <Field label="Día de la semana" htmlFor="schedule-day" required>
            {availableDays.length === 0 ? (
              <div className="rounded-xl border border-dashed border-border-strong bg-surface/60 px-4 py-3 text-xs text-secondary-text">
                Ya tienes horario para todos los días de la semana.
              </div>
            ) : (
              <Select
                id="schedule-day"
                value={dia}
                onChange={(event) => setDia(event.target.value)}
              >
                {availableDays.map((day) => (
                  <option key={day.value} value={day.value}>
                    {day.label}
                  </option>
                ))}
              </Select>
            )}
          </Field>
        )}

        <div className="grid grid-cols-2 gap-4">
          <Field label="Apertura" htmlFor="schedule-open" required>
            <Input
              id="schedule-open"
              type="time"
              value={apertura}
              onChange={(event) => setApertura(event.target.value)}
            />
          </Field>
          <Field label="Cierre" htmlFor="schedule-close" required>
            <Input
              id="schedule-close"
              type="time"
              value={cierre}
              onChange={(event) => setCierre(event.target.value)}
            />
          </Field>
        </div>

        <Field
          label="Hora de descanso"
          htmlFor="schedule-break"
          hint="Opcional. Úsala si cierras al mediodía."
        >
          <Input
            id="schedule-break"
            type="time"
            value={descanso}
            onChange={(event) => setDescanso(event.target.value)}
          />
        </Field>

        {error && (
          <div className="rounded-xl border border-error/20 bg-error-tint px-4 py-3 text-sm font-medium text-error">
            {error}
          </div>
        )}

        <div className="flex flex-col-reverse gap-2 border-t border-border/70 pt-4 sm:flex-row sm:justify-end">
          <Button variant="outline" onClick={onClose}>
            Cancelar
          </Button>
          <Button
            onClick={handleSubmit}
            loading={loading}
            disabled={!isEditing && availableDays.length === 0}
            leftIcon={<LuClock size={15} />}
          >
            {isEditing ? "Guardar cambios" : "Guardar horario"}
          </Button>
        </div>
      </div>
    </Modal>
  );
}
