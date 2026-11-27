let registrationPromise: Promise<ServiceWorkerRegistration | null> | null = null;

export function supportsServiceWorker(): boolean {
  return typeof window !== "undefined" && "serviceWorker" in navigator;
}

export function registerServiceWorker(): Promise<ServiceWorkerRegistration | null> {
  if (!supportsServiceWorker()) return Promise.resolve(null);
  if (registrationPromise) return registrationPromise;

  const secureContext =
    window.isSecureContext ||
    window.location.hostname === "localhost" ||
    window.location.hostname === "127.0.0.1";

  if (!secureContext) return Promise.resolve(null);

  registrationPromise = navigator.serviceWorker
    .register("/sw.js", { scope: "/", updateViaCache: "none" })
    .then((registration) => {
      // Buscar actualizaciones sin bloquear el arranque de la app.
      void registration.update().catch(() => undefined);
      return registration;
    })
    .catch((error) => {
      console.warn("No se pudo registrar el service worker de ReservAll.", error);
      return null;
    });

  return registrationPromise;
}

export async function getServiceWorkerRegistration(): Promise<ServiceWorkerRegistration | null> {
  if (!supportsServiceWorker()) return null;

  const existing = await navigator.serviceWorker.getRegistration("/");
  if (existing) return existing;

  return registerServiceWorker();
}

export async function waitForServiceWorker(): Promise<ServiceWorkerRegistration | null> {
  if (!supportsServiceWorker()) return null;

  try {
    return await navigator.serviceWorker.ready;
  } catch {
    return getServiceWorkerRegistration();
  }
}
