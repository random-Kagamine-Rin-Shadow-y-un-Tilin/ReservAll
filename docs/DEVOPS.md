# Flujo DevOps de ReservAll

| Herramienta | Uso | Dónde vive |
|---|---|---|
| GitHub Projects V2 | Planificación (backlog, sprint, estados) | Tablero del Project |
| GitHub Actions | CI/CD | `.github/workflows/` |
| Slack | Alertas y comunicación | App de GitHub + webhook de Actions |
| Make | Automatización complementaria | Escenarios en make.com |

## Flujo de trabajo

1. Se crea un issue con la plantilla **Tarea** o **Bug** → entra al Project (Todo).
2. Se crea una rama `feature/<issue>-descripcion` desde `develop`.
3. Se abre un PR con `Closes #<issue>` → el Project lo mueve a **In progress / Review**.
4. Actions corre **CI** (solo en los módulos que cambiaron). Si falla, llega alerta a Slack.
5. Al hacer merge, el issue se cierra y el Project lo pasa a **Done**.
6. Para entregar una versión solo se hace merge a `main`: el workflow **Semantic Release** calcula la versión con Conventional Commits, crea el tag y el GitHub Release; luego **Release** genera APKs + build web y los adjunta. No se crean tags manualmente.

## 1. GitHub Actions

Workflows incluidos:

- `semantic-release.yml`: en cada push a `main` (y ejecución manual). Analiza los commits convencionales, actualiza `VERSION`, `CHANGELOG.md`, `package.json`, `web-negocio/package.json` y los `pubspec.yaml`, crea el tag `vX.Y.Z` y publica el GitHub Release.
- `ci.yml`: en cada push/PR a `main` y `develop`.
  - **backend**: instala `requirements.txt`, revisa errores graves con ruff y compila.
  - **web-negocio**: `pnpm install`, `pnpm lint`, `pnpm build` (guarda `dist` como artifact en `main`).
  - **movil-cliente / movil-negocio**: `flutter analyze` y `flutter test` (si existe `test/`).
  - **notify-slack**: manda alerta si algo falla.
- `release.yml`: al publicarse un Release (o ejecución manual), construye ambos APK y el build web y los adjunta al Release existente.
- `project.yml` (opcional): agrega issues/PRs al Project.

Activa además la protección de rama: **Settings → Branches → Add rule** para `main` y `develop`:
- Require a pull request before merging
- Require status checks to pass (elige los jobs de CI después de la primera ejecución)

## 2. Slack

Ya tienes la app de GitHub en Slack (notificaciones de issues/PRs). Para las alertas de Actions:

1. Entra a https://api.slack.com/apps → **Create New App** → From scratch.
2. **Incoming Webhooks** → activar → **Add New Webhook to Workspace** → elige el canal (ej. `#reservall-ci`).
3. Copia la URL (`https://hooks.slack.com/services/...`).
4. En GitHub: **Settings → Secrets and variables → Actions → New repository secret**
   - Nombre: `SLACK_WEBHOOK_URL`
   - Valor: la URL del webhook.

Suscripciones útiles con la app de GitHub en Slack (escribir en el canal):

```
/github subscribe random-Kagamine-Rin-Shadow-y-un-Tilin/ReservAll issues pulls reviews releases
/github subscribe random-Kagamine-Rin-Shadow-y-un-Tilin/ReservAll workflows:{branch:"main"}
```

## 3. GitHub Projects V2

En el Project → **⋯ → Workflows** activa los integrados:
- **Auto-add to project**: filtro `is:issue,pr is:open` para este repo.
- **Item closed** → Status = Done.
- **Pull request merged** → Status = Done.
- **Item reopened** → Status = Todo.

Campos recomendados: `Status` (Todo, In progress, Review, Done), `Prioridad`, `Módulo` (backend, web, móvil cliente, móvil negocio), `Iteration` (sprints) y `Estimación`.

Si prefieres hacerlo con Actions en lugar de Make o del auto-add integrado, usa `project.yml`:
- Variable `PROJECT_URL` (Settings → Secrets and variables → Actions → Variables).
- Secreto `PROJECT_TOKEN`: PAT classic con scopes `project` y `repo`.

Usa **solo una** de las tres opciones para agregar items (auto-add, Make o `project.yml`) para no duplicar.

## 4. Make (complementario)

Ideas de escenarios que no cubren Actions ni la app de Slack:
- **Resumen diario/semanal**: GitHub (listar issues del Project por estado) → Slack mensaje al canal.
- **Issue desde Slack**: Slack (mensaje con emoji 🐛 o comando) → GitHub crear issue con etiqueta `bug`.
- **Recordatorio de PRs sin revisar**: cada mañana, PRs abiertos > 24 h → Slack mención al revisor.
- **Bitácora**: Release publicado (webhook GitHub) → Google Sheets / Notion.

## 5. Variables de despliegue

El backend está en Render (`https://reservall.onrender.com`), la web en Vercel
(`https://reservall.vercel.app`) y la API key es común a todos los frentes.

En GitHub (Settings → Secrets and variables → Actions), configurar:

| Tipo | Nombre | Valor |
|---|---|---|
| Variable | `VITE_API_URL` | `https://reservall.onrender.com/api/v1` |
| Variable | `API_URL` | `https://reservall.onrender.com` (Flutter) |
| Secreto | `VITE_API_KEY` | API key del backend (build web) |
| Secreto | `API_KEY` | API key del backend (APK) |

Si no se crean las variables, los workflows usan la URL de Render por defecto.
Si `API_KEY` no está definido, el APK conserva la clave por defecto del código.

En Render, además de `DATABASE_URL`, `JWT_SECRET`, `API_KEY` y Supabase, hay que
configurar `CORS_ORIGINS=https://reservall.vercel.app`, `COOKIE_SECURE=true`,
`COOKIE_SAMESITE=none`, `PUSH_ENABLED=true`, `VAPID_PUBLIC_KEY`,
`VAPID_PRIVATE_KEY`, `PUSH_LEAD_MINUTES=0` y `PUSH_CHECK_INTERVAL_SECONDS=30`.
En Vercel/Netlify, solo `VITE_API_URL` y `VITE_API_KEY`.

## 6. Versionado automático

El versionado lo hace `semantic-release` (configuración en `.releaserc.json`,
dependencias en el `package.json` raíz). Solo publica desde `main` y entiende
Conventional Commits: `fix:` → patch, `feat:` → minor, `BREAKING CHANGE:` → major.
`docs:`, `chore:`, `config:` y `refactor:` no generan versión.

Antes del release se actualizan:

- `VERSION` y `CHANGELOG.md`
- `package.json` (raíz) y `web-negocio/package.json`
- `movil-negocio/pubspec.yaml` y `movil-cliente/pubspec.yaml` (sube `+build`)

El release creado dispara `release.yml`, que adjunta los APK y el zip de la web.
El commit de versión lleva `[skip ci]` para no repetir CI. Si la protección de
rama de `main` impide el push, crear el secreto `GH_TOKEN` (PAT con `repo` /
`contents: write`); si no existe, se usa `GITHUB_TOKEN`.

Probar sin publicar:

```powershell
pnpm install
pnpm release:dry
```

## Pendientes detectados

- En `main`, `web-negocio` no compila (variables sin usar, TS6133, y el import `EditShopPayloal` en `src/modules/shop/api.ts`). En `develop` ya compila.
- `backend` no tiene pruebas; se recomienda agregar `pytest` y un job de pruebas.
- `movil-negocio` no tiene carpeta `test/`.
