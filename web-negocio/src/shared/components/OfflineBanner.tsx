import { LuWifiOff } from "react-icons/lu";
import { useOnlineStatus } from "../hooks/useOnlineStatus";

export function OfflineBanner() {
  const online = useOnlineStatus();
  if (online) return null;

  return (
    <div
      role="status"
      className="flex items-start gap-2 border-b border-highlight/30 bg-highlight-tint px-4 py-2.5 text-xs font-semibold text-foreground sm:px-6 lg:px-8"
    >
      <LuWifiOff size={15} className="mt-0.5 shrink-0 text-highlight" />
      <p>
        Sin conexión. Sigues viendo la agenda y las reservas guardadas en este
        dispositivo; los cambios se podrán guardar cuando vuelvas a conectarte.
      </p>
    </div>
  );
}
