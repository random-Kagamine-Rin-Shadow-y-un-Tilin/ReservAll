/** Configuración compartida del frontend. Se puede sobrescribir con variables
 * de entorno en Vercel/Netlify; si no están, se usa el backend desplegado. */
export const API_URL = (
  import.meta.env.VITE_API_URL || "https://reservall.onrender.com/api/v1"
).replace(/\/$/, "");

export const API_KEY = import.meta.env.VITE_API_KEY || "";
