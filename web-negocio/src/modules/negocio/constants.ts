export const SHOP_CATEGORIES = [
  { id: 1, nombre: "Barbería" },
  { id: 2, nombre: "Spa" },
  { id: 3, nombre: "Restaurante" },
  { id: 4, nombre: "Belleza" },
  { id: 5, nombre: "Otro" },
] as const;

export const WEEK_DAYS = [
  { value: "lunes", label: "Lunes", short: "Lun" },
  { value: "martes", label: "Martes", short: "Mar" },
  { value: "miercoles", label: "Miércoles", short: "Mié" },
  { value: "jueves", label: "Jueves", short: "Jue" },
  { value: "viernes", label: "Viernes", short: "Vie" },
  { value: "sabado", label: "Sábado", short: "Sáb" },
  { value: "domingo", label: "Domingo", short: "Dom" },
] as const;

export const SOCIAL_NETWORKS = [
  { value: "instagram", label: "Instagram" },
  { value: "facebook", label: "Facebook" },
  { value: "whatsapp", label: "WhatsApp" },
  { value: "tiktok", label: "TikTok" },
  { value: "x", label: "X / Twitter" },
  { value: "sitio_web", label: "Sitio web" },
  { value: "telefono", label: "Teléfono" },
] as const;

export const SERVICE_CATEGORIES = [
  { value: "servicio", label: "Servicio" },
  { value: "paquete", label: "Paquete" },
  { value: "consulta", label: "Consulta" },
  { value: "mesa", label: "Mesa / espacio" },
] as const;

export function serviceCategoryLabel(value: string | null | undefined): string {
  if (!value) return "Servicio";
  return (
    SERVICE_CATEGORIES.find((category) => category.value === value)?.label ??
    value.charAt(0).toUpperCase() + value.slice(1)
  );
}

export function dayLabel(value: string): string {
  return WEEK_DAYS.find((day) => day.value === value)?.label ?? value;
}

export function categoryLabel(value: string | number | null | undefined): string {
  if (value === null || value === undefined) return "Sin categoría";
  if (typeof value === "number") {
    return SHOP_CATEGORIES.find((category) => category.id === value)?.nombre ?? "Otro";
  }
  return value;
}

export function formatPrice(value: number): string {
  return new Intl.NumberFormat("es-MX", {
    style: "currency",
    currency: "MXN",
    maximumFractionDigits: 2,
  }).format(value);
}

export function formatTime(value: string | null | undefined): string {
  if (!value) return "—";
  return value.slice(0, 5);
}

export function formatDuration(minutes: number): string {
  if (minutes < 60) return `${minutes} min`;
  const hours = Math.floor(minutes / 60);
  const rest = minutes % 60;
  return rest === 0 ? `${hours} h` : `${hours} h ${rest} min`;
}

export function socialLabel(value: string): string {
  return SOCIAL_NETWORKS.find((network) => network.value === value)?.label ?? value;
}
