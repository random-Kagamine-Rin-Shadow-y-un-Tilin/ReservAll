# web-negocio (PWA)

Frontend React + TypeScript + Vite del panel de negocio. Es una PWA instalable:
funciona sin conexión con la agenda/reservas ya cargadas y muestra avisos push
cuando llega la hora de una reserva.

## Desarrollo local

```bash
pnpm install
cp .env.example .env
pnpm dev
```

`.env` no se versiona. Copia `.env.example` y ajusta los valores. Si no se
definen, el código usa el backend desplegado (`https://reservall.onrender.com/api/v1`)
y la API key queda vacía, así que **la API key siempre debe configurarse**.

## Despliegue (Vercel / Netlify)

- Directorio/base: `web-negocio`
- Comando de build: `pnpm build`
- Directorio de salida: `dist`
- Variables de entorno del build:

| Variable | Valor |
|---|---|
| `VITE_API_URL` | `https://reservall.onrender.com/api/v1` |
| `VITE_API_KEY` | la misma API key del backend |

`vercel.json` / `netlify.toml` ya incluyen el rewrite a `index.html` para
React Router y las cabeceras del service worker (`Service-Worker-Allowed: /`,
`Cache-Control: no-cache`).

## Backend (Render)

Para que el login con cookies y CORS funcionen desde `https://reservall.vercel.app`,
el servicio de Render debe tener:

```text
CORS_ORIGINS=https://reservall.vercel.app
COOKIE_SECURE=true
COOKIE_SAMESITE=none
PUSH_ENABLED=true
VAPID_PUBLIC_KEY=<pública del backend>
VAPID_PRIVATE_KEY=<privada del backend>
PUSH_LEAD_MINUTES=0
PUSH_CHECK_INTERVAL_SECONDS=30
```

`COOKIE_SAMESITE=none` es necesario porque web y backend están en dominios
distintos; sin él el navegador no envía la cookie de sesión en las peticiones
cross-site. La clave pública VAPID **no** se pone en el frontend: el backend la
entrega en `GET /api/v1/push/public-key`.

## Offline y notificaciones

- Las respuestas GET autenticadas se guardan en `localStorage` y se sirven sin red.
- El service worker precarga el shell y los bundles del build.
- Para recibir avisos con la web cerrada, el navegador debe tener permiso de
  notificaciones y la suscripción push activa (botón "Activar notificaciones").
- Cerrar sesión desactiva la suscripción y borra la caché offline.
