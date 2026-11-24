import { useEffect, useState, type FormEvent } from "react";
import { LuCircleAlert, LuUser } from "react-icons/lu";
import { useAuth } from "../hooks/useAuth";
import type { ProfileUpdatePayload, User } from "../types";
import { Button } from "../../../shared/components/ui/Button";
import { Field, Input } from "../../../shared/components/ui/Field";
import { Modal } from "../../../shared/components/Modal";
import { validateEmail, validatePassword } from "../../../shared/utils/validators";

interface ProfileEditModalProps {
  isOpen: boolean;
  onClose: () => void;
  user: User;
  onSaved?: () => void;
}

export function ProfileEditModal({
  isOpen,
  onClose,
  user,
  onSaved,
}: ProfileEditModalProps) {
  const { updateProfile } = useAuth();
  const [nombre, setNombre] = useState(user.nombre);
  const [correo, setCorreo] = useState(user.correo);
  const [passwordActual, setPasswordActual] = useState("");
  const [passwordNueva, setPasswordNueva] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!isOpen) return;
    setNombre(user.nombre);
    setCorreo(user.correo);
    setPasswordActual("");
    setPasswordNueva("");
    setConfirmPassword("");
    setError(null);
  }, [isOpen, user]);

  function buildPayload(): ProfileUpdatePayload | string {
    const payload: ProfileUpdatePayload = {};
    const nombreLimpio = nombre.trim();
    const correoLimpio = correo.trim();
    const cambiaNombre = nombreLimpio !== user.nombre;
    const cambiaCorreo = correoLimpio !== user.correo;
    const cambiaPassword = Boolean(
      passwordActual || passwordNueva || confirmPassword,
    );

    if (cambiaNombre) {
      if (nombreLimpio.length < 2) {
        return "El nombre debe tener al menos 2 caracteres.";
      }
      payload.nombre = nombreLimpio;
    }
    if (cambiaCorreo) {
      if (!validateEmail(correoLimpio)) {
        return "Ingresa un correo electrónico válido.";
      }
      payload.correo = correoLimpio;
    }

    if (cambiaPassword) {
      if (!passwordActual) {
        return "La contraseña actual es obligatoria para cambiar la contraseña.";
      }
      const passwordError = validatePassword(passwordNueva);
      if (passwordError) return passwordError;
      if (passwordNueva !== confirmPassword) {
        return "Las contraseñas nuevas no coinciden.";
      }
      payload.password_actual = passwordActual;
      payload.password_nueva = passwordNueva;
      payload.confirm_password = confirmPassword;
    }

    if (cambiaCorreo && !payload.password_actual) {
      return "La contraseña actual es obligatoria para cambiar el correo.";
    }
    if (!Object.keys(payload).length) {
      return "No hay cambios para guardar.";
    }
    return payload;
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError(null);

    const payload = buildPayload();
    if (typeof payload === "string") {
      setError(payload);
      return;
    }

    setLoading(true);
    try {
      await updateProfile(payload);
      onSaved?.();
      onClose();
    } catch (err) {
      setError(
        err instanceof Error
          ? err.message
          : "No pudimos actualizar tu perfil.",
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Editar mi perfil"
      description="El cambio de correo o contraseña requiere tu contraseña actual."
      size="sm"
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        <Field label="Nombre" htmlFor="profile-name" required>
          <Input
            id="profile-name"
            value={nombre}
            onChange={(event) => setNombre(event.target.value)}
            autoComplete="name"
          />
        </Field>

        <Field
          label="Correo electrónico"
          htmlFor="profile-email"
          hint="Necesitas confirmar con tu contraseña actual si lo cambias."
          required
        >
          <Input
            id="profile-email"
            type="email"
            value={correo}
            onChange={(event) => setCorreo(event.target.value)}
            autoComplete="email"
          />
        </Field>

        <div className="border-t border-border/70 pt-4">
          <p className="mb-3 text-xs font-bold uppercase tracking-wide text-secondary-text">
            Cambiar contraseña (opcional)
          </p>
          <div className="space-y-4">
            <Field label="Contraseña actual" htmlFor="profile-current-password">
              <Input
                id="profile-current-password"
                type="password"
                value={passwordActual}
                onChange={(event) => setPasswordActual(event.target.value)}
                autoComplete="current-password"
              />
            </Field>
            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="Nueva contraseña" htmlFor="profile-new-password">
                <Input
                  id="profile-new-password"
                  type="password"
                  value={passwordNueva}
                  onChange={(event) => setPasswordNueva(event.target.value)}
                  autoComplete="new-password"
                />
              </Field>
              <Field
                label="Confirmar contraseña"
                htmlFor="profile-confirm-password"
              >
                <Input
                  id="profile-confirm-password"
                  type="password"
                  value={confirmPassword}
                  onChange={(event) => setConfirmPassword(event.target.value)}
                  autoComplete="new-password"
                />
              </Field>
            </div>
          </div>
        </div>

        {error && (
          <div className="flex items-start gap-2 rounded-xl border border-error/20 bg-error-tint px-3.5 py-3 text-xs font-medium text-error">
            <LuCircleAlert size={15} className="mt-0.5 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        <div className="flex flex-col-reverse gap-2 border-t border-border/70 pt-4 sm:flex-row sm:justify-end">
          <Button type="button" variant="outline" onClick={onClose}>
            Cancelar
          </Button>
          <Button
            type="submit"
            loading={loading}
            leftIcon={<LuUser size={15} />}
          >
            Guardar cambios
          </Button>
        </div>
      </form>
    </Modal>
  );
}
