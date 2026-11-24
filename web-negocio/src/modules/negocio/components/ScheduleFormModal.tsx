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
  initialDay?: string | null;
  onSaved: () => Promise<void> | void;
}

export function ScheduleFormModal({
  isOpen,
  onClose,
  shopId,
  schedule,
  initialDay,
  onSaved,
}: ScheduleFormModalProps) {
  const [dia, setDia] = useState<string>(WEEK_DAYS[0].value);
  const [apertura, setApertura] = useState("09:00");
  const [cierre, setCierre] = useState("18:00");
  const [descanso, setDescanso] = useState("");
  const [duracion, setDuracion] = useState("60");
  const [activo, setActivo] = useState(true);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const isEditing = Boolean(schedule);

  useEffect(() => {
    if (!isOpen) return;
    setDia(schedule?.dia ?? initialDay ?? WEEK_DAYS[0].value);
    setApertura(schedule ? formatTime(schedule.hora_apertura) : "09:00");
    setCierre(schedule ? formatTime(schedule.hora_cierre) : "18:00");
    setDescanso(schedule?.hora_descanso ? formatTime(schedule.hora_descanso) : "");
    setDuracion(String(schedule?.descanso_duracion_min ?? 60));
    setActivo(schedule?.estado_horario !== false);
    setError(null);
  }, [isOpen, schedule, initialDay]);

  async function handleSubmit() {
    setError(null);

    if (!dia) {
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
    if (descanso && (descanso <= apertura || descanso >= cierre)) {
      setError("La hora de descanso debe estar dentro del horario.");
      return;
    }
    const duracionNumero = Number(duracion);
    if (!Number.isInteger(duracionNumero) || duracionNumero < 0 || duracionNumero > 240) {
      setError("La duración del descanso debe estar entre 0 y 240 minutos.");
      return;
    }

    setLoading(true);
    try {
      const payload = {
        hora_apertura: apertura,
        hora_cierre: cierre,
        hora_descanso: descanso || null,
        descanso_duracion_min: duracionNumero,
        estado_horario: activo,
      };
      if (schedule) {
        await editSchedule(shopId, schedule.id_horario, payload);
      } else {
        await createSchedule(shopId, { dia, ...payload });
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
      title={isEditing ? "Editar turno" : "Añadir turno"}
      description="Puedes registrar varios turnos por día siempre que no se solapen."
      size="sm"
    >
      <div className="space-y-4">
        <Field label="Día de la semana" htmlFor="schedule-day" required>
          <Select
            id="schedule-day"
            value={dia}
            onChange={(event) => setDia(event.target.value)}
            disabled={isEditing}
          >
            {WEEK_DAYS.map((day) => (
              <option key={day.value} value={day.value}>
                {day.label}
              </option>
            ))}
          </Select>
        </Field>

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

        <div className="grid grid-cols-2 gap-4">
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
          <Field
            label="Duración (min)"
            htmlFor="schedule-break-duration"
            hint="0 desactiva el descanso."
          >
            <Input
              id="schedule-break-duration"
              type="number"
              min={0}
              max={240}
              step={5}
              value={duracion}
              onChange={(event) => setDuracion(event.target.value)}
              disabled={!descanso}
            />
          </Field>
        </div>

        <label className="flex items-center gap-2 text-sm text-secondary-text">
          <input
            type="checkbox"
            checked={activo}
            onChange={(event) => setActivo(event.target.checked)}
            className="size-4 accent-[var(--color-primary)]"
          />
          Turno activo (si lo desactivas, no generará disponibilidad)
        </label>

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
            leftIcon={<LuClock size={15} />}
          >
            {isEditing ? "Guardar cambios" : "Guardar turno"}
          </Button>
        </div>
      </div>
    </Modal>
  );
}
