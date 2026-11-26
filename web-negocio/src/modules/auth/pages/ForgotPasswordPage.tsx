import { useState, type FormEvent } from "react";
import { Link } from "react-router-dom";
import { LuArrowLeft, LuCircleAlert, LuMail } from "react-icons/lu";
import { AuthLayout } from "../components/AuthLayout";
import { requestPasswordReset } from "../api";
import type { PasswordResetRequestOut } from "../types";
import { Button } from "../../../shared/components/ui/Button";
import { Field, Input } from "../../../shared/components/ui/Field";
import { validateEmail } from "../../../shared/utils/validators";

export function ForgotPasswordPage() {
  const [correo, setCorreo] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<PasswordResetRequestOut | null>(null);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError(null);

    const email = correo.trim();
    if (!validateEmail(email)) {
      setError("Ingresa un correo electrónico válido.");
      return;
    }

    setLoading(true);
    try {
      const response = await requestPasswordReset(email);
      setResult(response);
    } catch (err) {
      setError(
        err instanceof Error
          ? err.message
          : "No pudimos solicitar el código de recuperación.",
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <AuthLayout
      title="Recuperar contraseña"
      subtitle="Te enviaremos un código de 6 dígitos para restablecer el acceso a tu panel."
    >
      <div className="rounded-2xl border border-border bg-card p-6 shadow-soft sm:p-7">
        {result ? (
          <div className="space-y-5">
            <div className="rounded-xl border border-success/20 bg-success-tint px-4 py-3 text-sm font-medium text-success">
              {result.mensaje}
            </div>
            <p className="text-sm leading-relaxed text-secondary-text">
              El código es válido durante {result.expira_en_minutos} minutos.
              {result.codigo ? (
                <>
                  {" "}
                  Como el entorno está en modo desarrollo, tu código es{" "}
                  <strong className="font-mono text-foreground">{result.codigo}</strong>.
                </>
              ) : null}
            </p>
            <Link
              to={`/reset-password?correo=${encodeURIComponent(correo.trim())}`}
              className="inline-flex text-sm font-semibold text-primary hover:underline"
            >
              Ya tengo el código, continuar
            </Link>
            <div className="border-t border-border/70 pt-4">
              <Link
                to="/login"
                className="inline-flex items-center gap-1.5 text-xs font-semibold text-secondary-text hover:text-foreground"
              >
                <LuArrowLeft size={14} />
                Volver al inicio de sesión
              </Link>
            </div>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-4">
            <Field label="Correo electrónico" htmlFor="reset-email" required>
              <div className="relative">
                <LuMail
                  size={16}
                  className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-secondary-text"
                />
                <Input
                  id="reset-email"
                  type="email"
                  autoComplete="email"
                  value={correo}
                  onChange={(event) => setCorreo(event.target.value)}
                  className="pl-10"
                  placeholder="tu@negocio.com"
                />
              </div>
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
              leftIcon={<LuMail size={16} />}
            >
              Enviar código
            </Button>

            <div className="border-t border-border/70 pt-5 text-center text-xs text-secondary-text">
              <Link
                to="/login"
                className="inline-flex items-center gap-1.5 font-semibold text-primary hover:underline"
              >
                <LuArrowLeft size={14} />
                Volver al inicio de sesión
              </Link>
            </div>
          </form>
        )}
      </div>
    </AuthLayout>
  );
}
