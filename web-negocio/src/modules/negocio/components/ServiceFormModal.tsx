import { useEffect, useState } from "react";
import { LuCheck, LuSparkles } from "react-icons/lu";
import { Modal } from "../../../shared/components/Modal";
import { Button } from "../../../shared/components/ui/Button";
import { Field, Input, Select, Textarea } from "../../../shared/components/ui/Field";
import { createService } from "../api";
import { SERVICE_CATEGORIES } from "../constants";
import type { Professional } from "../types";

interface ServiceFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  shopId: number;
  professionals: Professional[];
  onSaved: () => Promise<void> | void;
}

export function ServiceFormModal({
  isOpen,
  onClose,
  shopId,
  professionals,
  onSaved,
}: ServiceFormModalProps) {
  const [nombre, setNombre] = useState("");
  const [descripcion, setDescripcion] = useState("");
  const [duracion, setDuracion] = useState("60");
  const [precio, setPrecio] = useState("0");
  const [categoria, setCategoria] = useState("servicio");
  const [cantidad, setCantidad] = useState("1");
  const [profesionalIds, setProfesionalIds] = useState<number[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!isOpen) return;
    setNombre("");
    setDescripcion("");
    setDuracion("60");
    setPrecio("0");
    setCategoria("servicio");
    setCantidad("1");
    setProfesionalIds([]);
    setError(null);
  }, [isOpen]);

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

    setLoading(true);
    try {
      await createService(shopId, {
        nombre: nombre.trim(),
        descripcion: descripcion.trim() || null,
        duracion_minutos: duration,
        precio: price,
        categoria_servicio: categoria,
        cantidad_servicio: quantity,
        estado_servicio: true,
        profesional_ids: profesionalIds,
      });
      await onSaved();
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : "No pudimos registrar el servicio.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Nuevo servicio"
      description="Define qué ofreces, cuánto dura y quién puede atenderlo."
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
            Guardar servicio
          </Button>
        </div>
      </div>
    </Modal>
  );
}
