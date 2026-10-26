import { useCallback, useState } from "react";
import { Navigate, Outlet } from "react-router-dom";
import { useAuth } from "./modules/auth/hooks/useAuth";
import { ShopProvider } from "./modules/shop/context/ShopContext";
import { Sidebar } from "./shared/components/layout/Sidebar";
import { Topbar } from "./shared/components/layout/Topbar";
import { Spinner } from "./shared/components/ui/Feedback";

export function App() {
  const { user, loading } = useAuth();
  const [sidebarOpen, setSidebarOpen] = useState(false);

  const closeSidebar = useCallback(() => setSidebarOpen(false), []);
  const openSidebar = useCallback(() => setSidebarOpen(true), []);

  if (loading) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center gap-4 text-secondary-text">
        <Spinner className="size-9" />
        <p className="text-sm font-semibold">Preparando tu panel...</p>
      </div>
    );
  }

  if (user === null) {
    return <Navigate to="/login" replace />;
  }

  return (
    <ShopProvider>
      <div className="flex min-h-screen">
        <Sidebar open={sidebarOpen} onClose={closeSidebar} />
        <div className="flex min-w-0 flex-1 flex-col">
          <Topbar onMenuClick={openSidebar} />
          <main className="flex-1 px-4 py-6 sm:px-6 lg:px-8">
            <div className="mx-auto w-full max-w-7xl">
              <Outlet />
            </div>
          </main>
        </div>
      </div>
    </ShopProvider>
  );
}

export default App;
