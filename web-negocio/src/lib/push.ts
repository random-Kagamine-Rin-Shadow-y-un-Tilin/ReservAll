import { apiRequest, jsonRequest } from "./request";
import {
  getServiceWorkerRegistration,
  supportsServiceWorker,
  waitForServiceWorker,
} from "./pwa";

export type PushStatus =
  | "unsupported"
  | "denied"
  | "subscribed"
  | "available";

const SUBSCRIBED_FLAG = "reservall:push-subscribed:v1";

function supportsPush(): boolean {
  return (
    typeof window !== "undefined" &&
    supportsServiceWorker() &&
    "PushManager" in window &&
    "Notification" in window
  );
}

function markSubscribed(value: boolean): void {
  try {
    if (value) window.localStorage.setItem(SUBSCRIBED_FLAG, "1");
    else window.localStorage.removeItem(SUBSCRIBED_FLAG);
  } catch {
    // Sin acceso al almacenamiento.
  }
}

export function hasPushSubscriptionFlag(): boolean {
  try {
    return window.localStorage.getItem(SUBSCRIBED_FLAG) === "1";
  } catch {
    return false;
  }
}

function urlBase64ToUint8Array(base64String: string): Uint8Array<ArrayBuffer> {
  const padding = "=".repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding)
    .replace(/-/g, "+")
    .replace(/_/g, "/");
  const rawData = window.atob(base64);
  const output = new Uint8Array(new ArrayBuffer(rawData.length));

  for (let index = 0; index < rawData.length; index += 1) {
    output[index] = rawData.charCodeAt(index);
  }

  return output;
}

async function getVapidPublicKey(): Promise<string> {
  const data = await apiRequest<{ publicKey: string }>(
    "/push/public-key",
    {},
    "No pudimos preparar las notificaciones push.",
  );

  if (!data?.publicKey) {
    throw new Error("El servidor no tiene configuradas las notificaciones push.");
  }

  return data.publicKey;
}

async function postSubscription(subscription: PushSubscription): Promise<void> {
  const json = subscription.toJSON();
  const keys = json.keys;

  if (!keys?.p256dh || !keys?.auth) {
    throw new Error("El navegador no devolvió las claves de la suscripción push.");
  }

  await jsonRequest(
    "/push/subscribe",
    "POST",
    {
      endpoint: subscription.endpoint,
      expirationTime: subscription.expirationTime,
      keys: { p256dh: keys.p256dh, auth: keys.auth },
      user_agent: navigator.userAgent,
    },
    "No pudimos guardar la suscripción a notificaciones.",
  );
}

export async function getPushStatus(): Promise<PushStatus> {
  if (!supportsPush()) return "unsupported";
  if (Notification.permission === "denied") return "denied";

  try {
    const registration = await getServiceWorkerRegistration();
    if (!registration) return "available";

    const subscription = await registration.pushManager.getSubscription();
    if (subscription && Notification.permission === "granted") {
      markSubscribed(true);
      return "subscribed";
    }
  } catch {
    // Si el navegador falla al consultar la suscripción, se ofrece activarla.
  }

  return "available";
}

export async function enablePushNotifications(): Promise<PushStatus> {
  if (!supportsPush()) return "unsupported";

  const permission = await Notification.requestPermission();
  if (permission !== "granted") return permission === "denied" ? "denied" : "available";

  const registration = await waitForServiceWorker();
  if (!registration) {
    throw new Error("El service worker no está disponible en este navegador.");
  }

  const existing = await registration.pushManager.getSubscription();
  const subscription =
    existing ??
    (await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: urlBase64ToUint8Array(await getVapidPublicKey()),
    }));

  await postSubscription(subscription);
  markSubscribed(true);
  return "subscribed";
}

export async function disablePushNotifications(): Promise<PushStatus> {
  if (!supportsPush()) return "unsupported";

  const registration = await getServiceWorkerRegistration();
  const subscription = await registration?.pushManager.getSubscription();

  if (subscription) {
    try {
      await jsonRequest(
        "/push/unsubscribe",
        "POST",
        { endpoint: subscription.endpoint },
        "No pudimos quitar la suscripción a notificaciones.",
      );
    } catch {
      // Aunque el backend no responda, se desactiva en este dispositivo.
    }

    await subscription.unsubscribe().catch(() => undefined);
  }

  markSubscribed(false);
  return getPushStatus();
}

/**
 * Quita la suscripción del backend sin borrarla del navegador. Se usa al
 * cerrar sesión para que otra cuenta en el mismo dispositivo no reciba avisos
 * de la cuenta anterior. Al volver a entrar se registra de nuevo.
 */
export async function detachPushSubscriptionFromServer(): Promise<void> {
  if (!supportsPush()) return;

  try {
    const registration = await getServiceWorkerRegistration();
    const subscription = await registration?.pushManager.getSubscription();
    if (!subscription) return;

    await jsonRequest(
      "/push/unsubscribe",
      "POST",
      { endpoint: subscription.endpoint },
      "No pudimos quitar la suscripción a notificaciones.",
    );
    markSubscribed(false);
  } catch {
    // Si no hay conexión, el backend limpiará la suscripción cuando pueda.
  }
}

/**
 * Vuelve a registrar la suscripción existente en el backend. Sirve cuando el
 * navegador conserva la suscripción pero la base de datos del servidor cambió.
 */
export async function syncPushSubscription(): Promise<void> {
  if (!supportsPush() || Notification.permission !== "granted") return;

  try {
    const registration = await getServiceWorkerRegistration();
    const subscription = await registration?.pushManager.getSubscription();
    if (!subscription) return;

    await postSubscription(subscription);
    markSubscribed(true);
  } catch {
    // Sin conexión o backend no disponible: se reintenta en el próximo arranque.
  }
}

export async function sendTestPush(): Promise<void> {
  await jsonRequest(
    "/push/test",
    "POST",
    {},
    "No pudimos enviar la notificación de prueba.",
  );
}

export async function showLocalNotification(
  title: string,
  options: NotificationOptions = {},
): Promise<void> {
  if (typeof window === "undefined" || !("Notification" in window)) return;
  if (Notification.permission !== "granted") return;

  const payload: NotificationOptions = {
    icon: "/icons/icon-192.png",
    badge: "/icons/icon-192.png",
    ...options,
  };

  try {
    const registration = await getServiceWorkerRegistration();
    if (registration) {
      await registration.showNotification(title, payload);
      return;
    }
  } catch {
    // Se intenta con la API clásica.
  }

  try {
    new Notification(title, payload);
  } catch {
    // Algunos navegadores solo permiten notificaciones desde el service worker.
  }
}
