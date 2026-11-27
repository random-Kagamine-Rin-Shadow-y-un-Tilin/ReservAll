/* ReservAll · Service Worker
 * - Guarda el shell de la app para abrirla sin internet.
 * - Cachea los assets estáticos con estrategia stale-while-revalidate.
 * - Muestra las notificaciones push de las reservas.
 */

const CACHE_VERSION = "reservall-shell-v3";
const SHELL_URLS = [
  "/",
  "/index.html",
  "/manifest.webmanifest",
  "/favicon.svg",
  "/icons/icon-192.png",
  "/icons/icon-512.png",
  "/icons/icon-maskable-512.png",
  "/icons/apple-touch-icon.png",
];

const OFFLINE_HTML = `<!doctype html>
<html lang="es">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>ReservAll · Sin conexión</title>
    <style>
      body { margin: 0; min-height: 100vh; display: grid; place-items: center; background: #faf6f0; color: #241c16; font-family: system-ui, sans-serif; }
      main { max-width: 28rem; padding: 2rem; text-align: center; }
      h1 { font-size: 1.4rem; margin: 0 0 .5rem; }
      p { color: #7a7267; line-height: 1.6; margin: 0; }
    </style>
  </head>
  <body>
    <main>
      <h1>ReservAll está sin conexión</h1>
      <p>Abre la app al menos una vez con internet para guardar la agenda y las reservas en este dispositivo.</p>
    </main>
  </body>
</html>`;

// Descubre los bundles con hash que referencia el index.html para poder
// abrir la app sin conexión justo después de instalarla.
async function precacheBuildAssets(cache) {
  try {
    const response = await fetch("/index.html", { cache: "no-store" });
    if (!response.ok) return;

    const html = await response.text();
    const matches = html.matchAll(/(?:src|href)="([^"]+\.(?:js|css))"/g);
    const assets = new Set();

    for (const match of matches) {
      const path = match[1];
      if (!path.startsWith("/") || path.startsWith("/src/")) continue;
      assets.add(path);
    }

    await Promise.allSettled(
      [...assets].map((path) => cache.add(path)),
    );
  } catch {
    // Si falla, los assets se cachean en la primera visita.
  }
}

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches
      .open(CACHE_VERSION)
      .then(async (cache) => {
        await Promise.allSettled(SHELL_URLS.map((url) => cache.add(url)));
        await precacheBuildAssets(cache);
      })
      .then(() => self.skipWaiting()),
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(
          keys
            .filter(
              (key) => key.startsWith("reservall-") && key !== CACHE_VERSION,
            )
            .map((key) => caches.delete(key)),
        ),
      )
      .then(() => self.clients.claim()),
  );
});

function isDevAsset(url) {
  return (
    url.pathname.startsWith("/src/") ||
    url.pathname.startsWith("/@") ||
    url.pathname.startsWith("/node_modules/")
  );
}

async function networkFirstNavigation(request) {
  const cache = await caches.open(CACHE_VERSION);

  try {
    const response = await fetch(request);
    if (response.ok) {
      cache.put("/index.html", response.clone());
    }
    return response;
  } catch {
    return (
      (await cache.match(request, { ignoreVary: true })) ||
      (await cache.match("/index.html", { ignoreVary: true })) ||
      (await cache.match("/", { ignoreVary: true })) ||
      new Response(OFFLINE_HTML, {
        headers: { "Content-Type": "text/html; charset=utf-8" },
      })
    );
  }
}

async function staleWhileRevalidate(request) {
  const cache = await caches.open(CACHE_VERSION);
  // ignoreVary: el servidor responde con `Vary: Origin` y el navegador no
  // envía ese encabezado igual al pedir un script que al precargarlo.
  const cached = await cache.match(request, { ignoreVary: true });

  const network = fetch(request)
    .then((response) => {
      if (response.ok) cache.put(request, response.clone());
      return response;
    })
    .catch(() => null);

  return cached || (await network) || Response.error();
}

self.addEventListener("fetch", (event) => {
  const request = event.request;

  if (request.method !== "GET") return;

  const url = new URL(request.url);

  // Las llamadas a la API las gestiona la app con su caché offline propia.
  if (url.origin !== self.location.origin || url.pathname.startsWith("/api/")) {
    return;
  }

  if (request.mode === "navigate") {
    event.respondWith(networkFirstNavigation(request));
    return;
  }

  if (isDevAsset(url)) return;

  event.respondWith(staleWhileRevalidate(request));
});

self.addEventListener("push", (event) => {
  let data = {};

  try {
    data = event.data ? event.data.json() : {};
  } catch {
    data = { body: event.data ? event.data.text() : "" };
  }

  const title = data.title || "ReservAll";
  const options = {
    body: data.body || "Tienes una reserva próxima.",
    icon: data.icon || "/icons/icon-192.png",
    badge: data.badge || "/icons/icon-192.png",
    tag: data.tag || "reservall-reserva",
    renotify: true,
    vibrate: [200, 100, 200],
    data: { url: data.url || "/agenda" },
  };

  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();

  const target = new URL(
    (event.notification.data && event.notification.data.url) || "/agenda",
    self.location.origin,
  ).href;

  event.waitUntil(
    self.clients
      .matchAll({ type: "window", includeUncontrolled: true })
      .then((clientList) => {
        for (const client of clientList) {
          if (client.url.startsWith(self.location.origin)) {
            client.navigate(target);
            return client.focus();
          }
        }
        return self.clients.openWindow(target);
      }),
  );
});

self.addEventListener("message", (event) => {
  const data = event.data || {};

  if (data.type === "SKIP_WAITING") {
    self.skipWaiting();
    return;
  }

  if (data.type === "SHOW_NOTIFICATION") {
    event.waitUntil(
      self.registration.showNotification(data.title || "ReservAll", {
        body: data.body || "",
        icon: data.icon || "/icons/icon-192.png",
        badge: data.badge || "/icons/icon-192.png",
        tag: data.tag || "reservall-local",
        data: { url: data.url || "/reservas" },
      }),
    );
  }
});
