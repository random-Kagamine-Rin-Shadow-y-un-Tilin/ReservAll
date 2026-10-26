import { LoginForm } from "../components/LoginForm";
import { AuthLayout } from "../components/AuthLayout";

export function LoginPage() {
  return (
    <AuthLayout
      title="Bienvenido de nuevo"
      subtitle="Inicia sesión para administrar tu negocio, tu equipo y tu disponibilidad."
    >
      <LoginForm />
    </AuthLayout>
  );
}
