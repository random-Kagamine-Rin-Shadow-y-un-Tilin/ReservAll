import { useState, type FormEvent } from "react";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import {
  LuArrowLeft,
  LuCircleAlert,
  LuEye,
  LuEyeOff,
  LuKeyRound,
} from "react-icons/lu";
import { AuthLayout } from "../components/AuthLayout";
import { confirmPasswordReset } from "../api";
import { Button } from "../../../shared/components/ui/Button";
import { Field, Input } from "../../../shared/components/ui/Field";
import { validateEmail, validatePassword } from "../../../shared/utils/validators";

export function ResetPasswordPage() {
  const [params] = useSearchParams();
  const navigate = useNavigate();

  const [correo, setCorreo] = useState(params.get("correo") ?? "");
  const [codigo, setCodigo] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError(null);

    const email = correo.trim();
    if (!validateEmail(email)) {
      setError("Ingresa un correo electrónico válido.");
      return;
    }
    if (!/^\d{6}$/.test(codigo)) {
      setError("El código debe tener 6 dígitos.");
      return;
    }
    const passwordError = validatePassword(password);
    if (passwordError) {
      setError(passwordError);
      return;
    }
    if (password !== confirmPassword) {
      setError("Las contraseñas no coinciden.");
      return;
    }

    setLoading(true);
    try {
      await confirmPasswordReset({
        correo: email,
        codigo,
        nueva_password: password,
        confirm_password: confirmPassword,
      });
      navigate("/login", {
        replace: true,
        state: { message: "Contraseña actualizada. Inicia sesión de nuevo." },
      });
    } catch (err) {
      setError(
        err instanceof Error
          ? err.message
          : "No pudimos actualizar tu contraseña.",
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <AuthLayout
      title="Nueva contraseña"
      subtitle="Introduce el código que recibiste y elige una contraseña segura."
    >
      <div className="rounded-2xl border border-border bg-card p-6 shadow-soft sm:p-7">
        <form onSubmit={handleSubmit} className="space-y-4">
          <Field label="Correo electrónico" htmlFor="new-password-email" required>
            <Input
              id="new-password-email"
              type="email"
              autoComplete="email"
              value={correo}
              onChange={(event) => setCorreo(event.target.value)}
              placeholder="tu@negocio.com"
            />
          </Field>

          <Field
            label="Código de verificación"
            htmlFor="reset-code"
            hint="6 dígitos enviados a tu correo."
            required
          >
            <Input
              id="reset-code"
              inputMode="numeric"
              autoComplete="one-time-code"
              maxLength={6}
              value={codigo}
              onChange={(event) =>
                setCodigo(event.target.value.replace(/\D/g, "").slice(0, 6))
              }
              className="font-mono tracking-[0.3em]"
              placeholder="000000"
            />
          </Field>

          <Field label="Nueva contraseña" htmlFor="new-password" required>
            <div className="relative">
              <Input
                id="new-password"
                type={showPassword ? "text" : "password"}
                autoComplete="new-password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                className="pr-10"
                placeholder="Mínimo 8 caracteres"
              />
              <button
                type="button"
                onClick={() => setShowPassword((value) => !value)}
                aria-label={showPassword ? "Ocultar contraseña" : "Mostrar contraseña"}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-secondary-text transition-colors hover:text-foreground"
              >
                {showPassword ? <LuEyeOff size={16} /> : <LuEye size={16} />}
              </button>
            </div>
          </Field>

          <Field
            label="Confirmar contraseña"
            htmlFor="confirm-new-password"
            required
          >
            <Input
              id="confirm-new-password"
              type={showPassword ? "text" : "password"}
              autoComplete="new-password"
              value={confirmPassword}
              onChange={(event) => setConfirmPassword(event.target.value)}
              placeholder="Repite la contraseña"
            />
          </Field>

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
            leftIcon={<LuKeyRound size={16} />}
          >
            Actualizar contraseña
          </Button>

          <div className="border-t border-border/70 pt-5 text-center text-xs text-secondary-text">
            <Link
              to="/forgot-password"
              className="inline-flex items-center gap-1.5 font-semibold text-primary hover:underline"
            >
              <LuArrowLeft size={14} />
              Solicitar otro código
            </Link>
          </div>
        </form>
      </div>
    </AuthLayout>
  );
}
