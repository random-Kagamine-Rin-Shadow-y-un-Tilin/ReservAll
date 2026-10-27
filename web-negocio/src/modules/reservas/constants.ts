import type { BadgeTone } from "../../shared/components/ui/Badge";
import type { ReservationStatus } from "./types";

interface StatusMeta {
  value: ReservationStatus;
  label: string;
  tone: BadgeTone;
  description: string;
}

export const RESERVATION_STATUSES: StatusMeta[] = [
  {
    value: "pendiente",
    label: "Pendiente",
    tone: "gold",
    description: "Esperando confirmación del negocio.",
  },
  {
    value: "confirmada",
    label: "Confirmada",
    tone: "secondary",
    description: "Cita confirmada con el cliente.",
  },
  {
    value: "completada",
    label: "Completada",
    tone: "success",
    description: "La cita se atendió y cuenta como ingreso.",
  },
  {
    value: "cancelada",
    label: "Cancelada",
    tone: "danger",
    description: "La cita se canceló y no cuenta como ingreso.",
  },
];

export function statusMeta(status: ReservationStatus): StatusMeta {
  return (
    RESERVATION_STATUSES.find((item) => item.value === status) ?? {
      value: status,
      label: status,
      tone: "neutral",
      description: "",
    }
  );
}
