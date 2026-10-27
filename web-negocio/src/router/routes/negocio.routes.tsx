import { Navigate, Route } from "react-router-dom";
import { AccountPage } from "../../modules/negocio/pages/AccountPage";
import { BusinessProfilePage } from "../../modules/negocio/pages/BusinessProfilePage";
import { DashboardPage } from "../../modules/negocio/pages/DashboardPage";
import { ProfessionalsPage } from "../../modules/negocio/pages/ProfessionalsPage";
import { SchedulesPage } from "../../modules/negocio/pages/SchedulesPage";
import { ServicesPage } from "../../modules/negocio/pages/ServicesPage";
import { ReservationsPage } from "../../modules/reservas/pages/ReservationsPage";
import { ClientsPage } from "../../modules/clientes/pages/ClientsPage";
import { ReportsPage } from "../../modules/reportes/pages/ReportsPage";
import { RegisterShopPage } from "../../modules/shop/pages/RegisterShopPage";

export const negocioRoutes = (
  <>
    <Route path="/dashboard" element={<DashboardPage />} />
    <Route path="/negocio" element={<BusinessProfilePage />} />
    <Route path="/negocio/registrar" element={<RegisterShopPage />} />
    <Route path="/servicios" element={<ServicesPage />} />
    <Route path="/profesionales" element={<ProfessionalsPage />} />
    <Route path="/horarios" element={<SchedulesPage />} />
    <Route path="/reservas" element={<ReservationsPage />} />
    <Route path="/clientes" element={<ClientsPage />} />
    <Route path="/reportes" element={<ReportsPage />} />
    <Route path="/perfil" element={<AccountPage />} />

    {/* Compatibilidad con enlaces anteriores */}
    <Route path="/shop" element={<Navigate to="/negocio" replace />} />
    <Route path="/shop/:shopId" element={<Navigate to="/negocio" replace />} />
  </>
);
