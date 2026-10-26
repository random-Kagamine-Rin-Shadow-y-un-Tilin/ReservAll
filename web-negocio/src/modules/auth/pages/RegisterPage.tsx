import { RegisterForm } from "../components/RegisterForm";
import { AuthLayout } from "../components/AuthLayout";

export function RegisterPage() {
  return (
    <AuthLayout
      title="Crea tu cuenta de negocio"
      subtitle="Un solo lugar para tus servicios, tu equipo y tus horarios. Sin tarjeta de crédito."
    >
      <RegisterForm />
    </AuthLayout>
  );
}
