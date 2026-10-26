import { LuCalendar, LuTrendingUp, LuUsers } from "react-icons/lu";
import { ComingSoon } from "../../../shared/components/ui/ComingSoon";

export function ReservationsPage() {
  return (
    <ComingSoon
      title="La agenda de reservas está en camino"
      description="Aquí podrás ver las solicitudes de tus clientes, confirmar citas, registrar cancelaciones y organizar tu día."
      icon={<LuCalendar />}
      features={[
        "Vista de agenda diaria y semanal",
        "Confirmar, cancelar y completar reservas",
        "Filtros por profesional y servicio",
        "Recordatorios y estados de cada cita",
      ]}
    />
  );
}

export function ClientsPage() {
  return (
    <ComingSoon
      title="El directorio de clientes está en camino"
      description="Conocerás a las personas que reservan contigo, su historial de citas y sus servicios favoritos."
      icon={<LuUsers />}
      features={[
        "Listado de clientes con datos de contacto",
        "Historial de reservas por cliente",
        "Clientes frecuentes y última visita",
        "Notas internas y seguimiento",
      ]}
    />
  );
}

export function ReportsPage() {
  return (
    <ComingSoon
      title="Los reportes están en camino"
      description="Tendrás una vista clara de tus ingresos, servicios más solicitados y horarios con mayor demanda."
      icon={<LuTrendingUp />}
      features={[
        "Ingresos por periodo y por servicio",
        "Servicios y profesionales más solicitados",
        "Ocupación por día y hora",
        "Exportación de métricas",
      ]}
    />
  );
}
