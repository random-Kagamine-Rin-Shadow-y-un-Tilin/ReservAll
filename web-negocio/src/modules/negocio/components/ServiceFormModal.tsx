import { useEffect, useState } from "react";
import { LuCheck, LuSparkles } from "react-icons/lu";
import { Modal } from "../../../shared/components/Modal";
import { Button } from "../../../shared/components/ui/Button";
import { Field, Input, Select, Textarea } from "../../../shared/components/ui/Field";
import { createService, editService } from "../api";
import { SERVICE_CATEGORIES } from "../constants";
import type { Professional, Service } from "../types";

interface ServiceFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  shopId: number;
  professionals: Professional[];
  service?: Service | null;
  onSaved: () => Promise<void> | void;
}

export function ServiceFormModal({
  isOpen,
  onClose,
  shopId,
  professionals,
  service = null,
  onSaved,
}: ServiceFormModalProps) {
  const [nombre, setNombre] = useState("");
  const [descripcion, setDescripcion] = useState("");
  const [duracion, setDuracion] = useState("60");
  const [precio, setPrecio] = useState("0");
  const [categoria, setCategoria] = useState("servicio");
  const [cantidad, setCantidad] = useState("1");
  const [estado, setEstado] = useState(true);
  const [profesionalIds, setProfesionalIds] = useState<number[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const editing = Boolean(service);

  useEffect(() => {
    if (!isOpen) return;
    setNombre(service?.nombre ?? "");
    setDescripcion(service?.descripcion ?? "");
    setDuracion(String(service?.duracion_minutos ?? 60));
    setPrecio(String(service?.precio ?? 0));
    setCategoria(service?.categoria_servicio ?? "servicio");
    setCantidad(String(service?.cantidad_servicio ?? 1));
    setEstado(service?.estado_servicio ?? true);
    setProfesionalIds(
      service?.profesionales?.map((professional) => professional.id_profesional) ??
        [],
    );
    setError(null);
  }, [isOpen, service]);

  function toggleProfessional(id: number) {
    setProfesionalIds((current) =>
      current.includes(id)
        ? current.filter((item) => item !== id)
        : [...current, id],
    );
  }

  async function handleSubmit() {
    setError(null);

    if (!nombre.trim()) {
      setError("El nombre del servicio es obligatorio.");
      return;
    }

    const duration = Number(duracion);
    const price = Number(precio);
    const quantity = Number(cantidad);

    if (!Number.isFinite(duration) || duration <= 0) {
      setError("La duración debe ser mayor a 0 minutos.");
      return;
    }
    if (!Number.isFinite(price) || price < 0) {
      setError("El precio no puede ser negativo.");
      return;
    }
    if (!Number.isFinite(quantity) || quantity < 1) {
      setError("La cantidad debe ser al menos 1.");
      return;
    }

    const payload = {
      nombre: nombre.trim(),
      descripcion: descripcion.trim() || null,
      duracion_minutos: duration,
      precio: price,
      categoria_servicio: categoria,
      cantidad_servicio: quantity,
      estado_servicio: estado,
      profesional_ids: profesionalIds,
    };

    setLoading(true);
    try {
      if (service) {
        await editService(shopId, service.id_servicio, payload);
      } else {
        await createService(shopId, payload);
      }
      await onSaved();
      onClose();
    } catch (err) {
      setError(
        err instanceof Error
          ? err.message
          : editing
            ? "No pudimos actualizar el servicio."
            : "No pudimos registrar el servicio.",
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={editing ? "Editar servicio" : "Nuevo servicio"}
      description={
        editing
          ? "Actualiza la información, el equipo y la visibilidad del servicio."
          : "Define qué ofreces, cuánto dura y quién puede atenderlo."
      }
    >
      <div className="space-y-4">
        <Field label="Nombre del servicio" htmlFor="service-name" required>
          <Input
            id="service-name"
            value={nombre}
            onChange={(event) => setNombre(event.target.value)}
            placeholder="Ej. Corte de cabello"
          />
        </Field>

        <Field
          label="Descripción"
          htmlFor="service-description"
          hint="Ayuda a tus clientes a entender qué incluye."
        >
          <Textarea
            id="service-description"
            value={descripcion}
            onChange={(event) => setDescripcion(event.target.value)}
            placeholder="Ej. Corte personalizado con lavado y peinado."
          />
        </Field>

        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Duración (minutos)" htmlFor="service-duration" required>
            <Input
              id="service-duration"
              type="number"
              min={5}
              step={5}
              value={duracion}
              onChange={(event) => setDuracion(event.target.value)}
            />
          </Field>

          <Field label="Precio (MXN)" htmlFor="service-price" required>
            <Input
              id="service-price"
              type="number"
              min={0}
              step="0.01"
              value={precio}
              onChange={(event) => setPrecio(event.target.value)}
            />
          </Field>

          <Field label="Categoría" htmlFor="service-category">
            <Select
              id="service-category"
              value={categoria}
              onChange={(event) => setCategoria(event.target.value)}
            >
              {SERVICE_CATEGORIES.map((category) => (
                <option key={category.value} value={category.value}>
                  {category.label}
                </option>
              ))}
            </Select>
          </Field>

          <Field
            label="Capacidad"
            htmlFor="service-quantity"
            hint="Personas que pueden atenderse a la vez."
          >
            <Input
              id="service-quantity"
              type="number"
              min={1}
              step={1}
              value={cantidad}
              onChange={(event) => setCantidad(event.target.value)}
            />
          </Field>
        </div>

        <label
          htmlFor="service-active"
          className="flex cursor-pointer items-center justify-between gap-3 rounded-xl border border-border/70 bg-surface/60 px-4 py-3"
        >
          <span>
            <span className="block text-sm font-semibold text-foreground">
              Servicio activo
            </span>
            <span className="mt-0.5 block text-xs text-secondary-text">
              {estado
                ? "Tus clientes pueden reservarlo."
                : "No aparecerá disponible para reservar."}
            </span>
          </span>
          <input
            id="service-active"
            type="checkbox"
            checked={estado}
            onChange={(event) => setEstado(event.target.checked)}
            className="size-5 shrink-0 accent-primary"
          />
        </label>

        <div>
          <div className="mb-2 flex items-center justify-between">
            <p className="text-sm font-semibold text-foreground">Profesionales</p>
            <span className="text-xs text-secondary-text">Opcional</span>
          </div>

          {professionals.length === 0 ? (
            <div className="rounded-xl border border-dashed border-border-strong bg-surface/60 px-4 py-3 text-xs text-secondary-text">
              Aún no tienes profesionales registrados. Podrás asignarlos más adelante.
            </div>
          ) : (
            <div className="grid gap-2 sm:grid-cols-2">
              {professionals.map((professional) => {
                const selected = profesionalIds.includes(professional.id_profesional);
                return (
                  <button
                    key={professional.id_profesional}
                    type="button"
                    onClick={() => toggleProfessional(professional.id_profesional)}
                    className={`flex items-center gap-2.5 rounded-xl border px-3 py-2.5 text-left transition-colors ${
                      selected
                        ? "border-primary-soft bg-primary-tint text-primary"
                        : "border-border bg-card text-secondary-text hover:border-border-strong"
                    }`}
                  >
                    <span
                      className={`flex size-5 shrink-0 items-center justify-center rounded-md border ${
                        selected
                          ? "border-primary bg-primary text-white"
                          : "border-border-strong text-transparent"
                      }`}
                    >
                      <LuCheck size={12} />
                    </span>
                    <span className="min-w-0">
                      <span className="block truncate text-xs font-semibold">
                        {professional.nombre}
                      </span>
                      <span className="block truncate text-[10px] text-secondary-text">
                        {professional.especialidad || "Sin especialidad"}
                      </span>
                    </span>
                  </button>
                );
              })}
            </div>
          )}
        </div>

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
            leftIcon={<LuSparkles size={15} />}
          >
            {editing ? "Guardar cambios" : "Guardar servicio"}
          </Button>
        </div>
      </div>
    </Modal>
  );
}
