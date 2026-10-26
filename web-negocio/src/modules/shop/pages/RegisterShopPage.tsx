import { ShopRegisterForm } from "../components/forms/register/ShopRegisterForm";
import { PageHeader } from "../../../shared/components/ui/PageHeader";

export function RegisterShopPage() {
  return (
    <div>
      <PageHeader
        eyebrow="Nuevo negocio"
        title="Registra tu negocio"
        description="Crea el perfil que tus clientes verán. Podrás completar contactos, dirección y horarios después."
      />
      <ShopRegisterForm />
    </div>
  );
}
