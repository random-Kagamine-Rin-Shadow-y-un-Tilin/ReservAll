import { useEffect } from "react";
import { formatClock } from "../../../lib/format";
import { hasPushSubscriptionFlag, showLocalNotification } from "../../../lib/push";
import type { Reservation } from "../types";

const MAX_LOOKAHEAD_MS = 1000 * 60 * 60 * 12; // 12 horas

function reservationStart(reservation: Reservation): Date | null {
  if (!reservation.fecha || !reservation.hora_inicio) return null;

  const clock = reservation.hora_inicio.slice(0, 5);
  const date = new Date(`${reservation.fecha}T${clock}:00`);
  return Number.isNaN(date.getTime()) ? null : date;
}

/**
 * Aviso local de respaldo: si el navegador tiene permiso de notificaciones
 * pero el usuario todavía no activó el push del servidor, la app avisa a la
 * hora de la reserva mientras permanezca abierta.
 */
export function useReservationReminders(
  reservations: Reservation[],
  enabled = true,
): void {
  useEffect(() => {
    if (!enabled) return;
    if (typeof Notification === "undefined" || Notification.permission !== "granted") {
      return;
    }
    if (hasPushSubscriptionFlag()) return;

    const now = Date.now();
    const timers: number[] = [];

    reservations.forEach((reservation) => {
      if (
        reservation.estado !== "pendiente" &&
        reservation.estado !== "confirmada"
      ) {
        return;
      }

      const start = reservationStart(reservation);
      if (!start) return;

      const delay = start.getTime() - now;
      if (delay < 0 || delay > MAX_LOOKAHEAD_MS) return;

      const timer = window.setTimeout(() => {
        void showLocalNotification("Tu reserva empieza ahora", {
          body: `${reservation.cliente_nombre} · ${reservation.servicio_nombre} a las ${formatClock(
            reservation.hora_inicio,
          )}`,
          tag: `reservall-reserva-${reservation.id_reserva}`,
          icon: "/icons/icon-192.png",
          badge: "/icons/icon-192.png",
          data: { url: "/reservas" },
        });
      }, Math.max(1000, delay));

      timers.push(timer);
    });

    return () => {
      timers.forEach((timer) => window.clearTimeout(timer));
    };
  }, [reservations, enabled]);
}
