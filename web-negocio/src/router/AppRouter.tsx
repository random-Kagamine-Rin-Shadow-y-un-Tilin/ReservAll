import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { App } from "../App";
import { RouteProtect } from "./RouteProtect";
import { authRoutes } from "./routes/auth.routes";
import { negocioRoutes } from "./routes/negocio.routes";
import { NotFound } from "../shared/components/ui/NotFound";
import { CategoriesPage } from "../modules/categorias/pages/CategoriesPage";

export function AppRouter() {
  return (
    <BrowserRouter>
      <Routes>
        {authRoutes}

        <Route
          element={
            <RouteProtect requiredRol="negocio">
              <App />
            </RouteProtect>
          }
        >
          {negocioRoutes}
        </Route>

        {/* HU_14: la administración de categorías requiere rol admin. */}
        <Route
          path="/admin/categorias"
          element={
            <RouteProtect requiredRol="admin">
              <CategoriesPage />
            </RouteProtect>
          }
        />

        <Route path="/" element={<Navigate to="/dashboard" replace />} />
        <Route path="*" element={<NotFound />} />
      </Routes>
    </BrowserRouter>
  );
}
