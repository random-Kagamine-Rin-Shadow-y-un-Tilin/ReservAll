import { useState, type FormEvent } from "react";
import { Link } from "react-router-dom";
import {
  LuArrowRight,
  LuCheck,
  LuCircleAlert,
  LuEye,
  LuEyeOff,
  LuLock,
  LuMail,
  LuStore,
  LuUser,
} from "react-icons/lu";
import { useAuth } from "../hooks/useAuth";
import { validateEmail, validatePassword } from "../../../shared/utils/validators";
import { Button } from "../../../shared/components/ui/Button";
import { Field, Input } from "../../../shared/components/ui/Field";

export function RegisterForm() {
  const { register } = useAuth();

  const [name, setName] = useState("");
  const [correo, setCorreo] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError(null);

    if (!name.trim() || !correo.trim() || !password || !confirmPassword) {
      setError("Todos los campos son obligatorios.");
      return;
    }
    if (!validateEmail(correo.trim())) {
      setError("Ingresa un correo electrónico válido.");
      return;
    }
    if (password !== confirmPassword) {
      setError("Las contraseñas no coinciden.");
      return;
    }
    const passwordError = validatePassword(password);
    if (passwordError) {
      setError(passwordError);
      return;
    }

    setLoading(true);
    try {
      await register({
        nombre: name.trim(),
        correo: correo.trim(),
        password,
        confirm_password: confirmPassword,
        rol: "negocio",
      });
      setSuccess(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : "No pudimos crear tu cuenta.");
    } finally {
      setLoading(false);
    }
  }

  if (success) {
    return (
      <div className="rounded-2xl border border-border bg-card p-8 text-center shadow-soft">
        <span className="mx-auto flex size-14 items-center justify-center rounded-2xl bg-success-tint text-2xl text-success">
          <LuCheck />
        </span>
        <h2 className="mt-4 font-display text-xl font-bold text-foreground">
          Tu cuenta está lista
        </h2>
        <p className="mx-auto mt-2 max-w-sm text-sm leading-relaxed text-secondary-text">
          Ya puedes iniciar sesión y registrar la información de tu negocio.
        </p>
        <Link to="/login" className="mt-6 inline-block">
          <Button rightIcon={<LuArrowRight size={16} />}>Ir a iniciar sesión</Button>
        </Link>
      </div>
    );
  }

  return (
    <div className="rounded-2xl border border-border bg-card p-6 shadow-soft sm:p-7">
      <div className="mb-5 flex items-start gap-2.5 rounded-xl border border-primary/15 bg-primary-tint/50 px-3.5 py-3">
        <LuStore size={16} className="mt-0.5 shrink-0 text-primary" />
        <p className="text-xs leading-relaxed text-secondary-text">
          Estás creando una <strong className="text-foreground">cuenta de negocio</strong>.
          Podrás administrar tu local desde el panel de ReservAll.
        </p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        <Field label="Nombre completo" htmlFor="register-name" required>
          <div className="relative">
            <LuUser
              size={16}
              className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-secondary-text"
            />
            <Input
              id="register-name"
              autoComplete="name"
              value={name}
              onChange={(event) => setName(event.target.value)}
              className="pl-10"
              placeholder="Ej. Juan Pérez"
            />
          </div>
        </Field>

        <Field label="Correo electrónico" htmlFor="register-email" required>
          <div className="relative">
            <LuMail
              size={16}
              className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-secondary-text"
            />
            <Input
              id="register-email"
              type="email"
              autoComplete="email"
              value={correo}
              onChange={(event) => setCorreo(event.target.value)}
              className="pl-10"
              placeholder="tu@negocio.com"
            />
          </div>
        </Field>

        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Contraseña" htmlFor="register-password" required>
            <div className="relative">
              <LuLock
                size={16}
                className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-secondary-text"
              />
              <Input
                id="register-password"
                type={showPassword ? "text" : "password"}
                autoComplete="new-password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                className="pl-10 pr-9"
                placeholder="Mín. 8 caracteres"
              />
              <button
                type="button"
                onClick={() => setShowPassword((value) => !value)}
                aria-label={showPassword ? "Ocultar contraseña" : "Mostrar contraseña"}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-secondary-text transition-colors hover:text-foreground"
              >
                {showPassword ? <LuEyeOff size={15} /> : <LuEye size={15} />}
              </button>
            </div>
          </Field>

          <Field label="Confirmar contraseña" htmlFor="register-confirm" required>
            <div className="relative">
              <LuLock
                size={16}
                className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-secondary-text"
              />
              <Input
                id="register-confirm"
                type={showPassword ? "text" : "password"}
                autoComplete="new-password"
                value={confirmPassword}
                onChange={(event) => setConfirmPassword(event.target.value)}
                className="pl-10"
                placeholder="Repite la contraseña"
              />
            </div>
          </Field>
        </div>

        <p className="text-[11px] leading-relaxed text-secondary-text">
          La contraseña debe tener al menos 8 caracteres e incluir una mayúscula, una
          minúscula y un número.
        </p>

        {error && (
          <div className="flex items-start gap-2 rounded-xl border border-error/20 bg-error-tint px-3.5 py-3 text-xs font-medium text-error">
            <LuCircleAlert size={15} className="mt-0.5 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        <Button
          type="submit"
          loading={loading}
          className="w-full"
          rightIcon={<LuArrowRight size={16} />}
        >
          Crear cuenta de negocio
        </Button>
      </form>

      <p className="mt-6 border-t border-border/70 pt-5 text-center text-xs text-secondary-text">
        ¿Ya tienes una cuenta?{" "}
        <Link to="/login" className="font-semibold text-primary hover:underline">
          Inicia sesión
        </Link>
      </p>
    </div>
  );
}
