import { useState, type FormEvent } from "react";
import { Link, useNavigate } from "react-router-dom";
import {
  LuArrowRight,
  LuCircleAlert,
  LuEye,
  LuEyeOff,
  LuLock,
  LuMail,
} from "react-icons/lu";
import { useAuth } from "../hooks/useAuth";
import { Button } from "../../../shared/components/ui/Button";
import { Field, Input } from "../../../shared/components/ui/Field";

export function LoginForm() {
  const { login } = useAuth();
  const navigate = useNavigate();

  const [correo, setCorreo] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError(null);

    if (!correo.trim() || !password.trim()) {
      setError("Ingresa tu correo y contraseña.");
      return;
    }

    setLoading(true);
    try {
      await login({ correo: correo.trim(), password });
      navigate("/dashboard", { replace: true });
    } catch (err) {
      setError(err instanceof Error ? err.message : "No pudimos iniciar sesión.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="rounded-2xl border border-border bg-card p-6 shadow-soft sm:p-7">
      <form onSubmit={handleSubmit} className="space-y-4">
        <Field label="Correo electrónico" htmlFor="login-email" required>
          <div className="relative">
            <LuMail
              size={16}
              className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-secondary-text"
            />
            <Input
              id="login-email"
              type="email"
              autoComplete="email"
              value={correo}
              onChange={(event) => setCorreo(event.target.value)}
              className="pl-10"
              placeholder="tu@negocio.com"
            />
          </div>
        </Field>

        <Field label="Contraseña" htmlFor="login-password" required>
          <div className="relative">
            <LuLock
              size={16}
              className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-secondary-text"
            />
            <Input
              id="login-password"
              type={showPassword ? "text" : "password"}
              autoComplete="current-password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              className="pl-10 pr-10"
              placeholder="Tu contraseña"
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
          Entrar al panel
        </Button>
      </form>

      <p className="mt-6 border-t border-border/70 pt-5 text-center text-xs text-secondary-text">
        ¿Aún no tienes cuenta?{" "}
        <Link to="/register" className="font-semibold text-primary hover:underline">
          Crea tu cuenta de negocio
        </Link>
      </p>
    </div>
  );
}
