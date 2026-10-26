import { useEffect, useState } from "react";
import { LuUserPlus } from "react-icons/lu";
import { Modal } from "../../../shared/components/Modal";
import { Button } from "../../../shared/components/ui/Button";
import { Field, Input } from "../../../shared/components/ui/Field";
import { createProfessional, editProfessional } from "../api";
import type { Professional } from "../types";

interface ProfessionalFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  shopId: number;
  professional?: Professional | null;
  onSaved: () => Promise<void> | void;
}

export function ProfessionalFormModal({
  isOpen,
  onClose,
  shopId,
  professional,
  onSaved,
}: ProfessionalFormModalProps) {
  const [nombre, setNombre] = useState("");
  const [especialidad, setEspecialidad] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const isEditing = Boolean(professional);

  useEffect(() => {
    if (!isOpen) return;
    setNombre(professional?.nombre ?? "");
    setEspecialidad(professional?.especialidad ?? "");
    setError(null);
  }, [isOpen, professional]);

  async function handleSubmit() {
    setError(null);

    if (!nombre.trim()) {
      setError("El nombre del profesional es obligatorio.");
      return;
    }

    setLoading(true);
    try {
      if (professional) {
        await editProfessional(shopId, professional.id_profesional, {
          nombre: nombre.trim(),
          especialidad: especialidad.trim() || null,
        });
      } else {
        await createProfessional(shopId, {
          nombre: nombre.trim(),
          especialidad: especialidad.trim() || null,
        });
      }
      await onSaved();
      onClose();
    } catch (err) {
      setError(
        err instanceof Error
          ? err.message
          : "No pudimos guardar al profesional.",
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={isEditing ? "Editar profesional" : "Nuevo profesional"}
      description={
        isEditing
          ? "Actualiza los datos del integrante de tu equipo."
          : "Agrega a alguien de tu equipo para asignarle servicios."
      }
      size="sm"
    >
      <div className="space-y-4">
        <Field label="Nombre completo" htmlFor="professional-name" required>
          <Input
            id="professional-name"
            value={nombre}
            onChange={(event) => setNombre(event.target.value)}
            placeholder="Ej. Ana Martínez"
          />
        </Field>

        <Field
          label="Especialidad"
          htmlFor="professional-specialty"
          hint="Ej. Barbero, estilista, terapeuta, mesero."
        >
          <Input
            id="professional-specialty"
            value={especialidad}
            onChange={(event) => setEspecialidad(event.target.value)}
            placeholder="Ej. Especialista en color"
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
            leftIcon={<LuUserPlus size={15} />}
          >
            {isEditing ? "Guardar cambios" : "Agregar profesional"}
          </Button>
        </div>
      </div>
    </Modal>
  );
}
