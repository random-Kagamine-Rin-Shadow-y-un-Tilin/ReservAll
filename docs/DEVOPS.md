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
6. Para entregar una versión: `git tag v1.0.0 && git push origin v1.0.0` → workflow **Release** genera APKs + build web en un GitHub Release y avisa en Slack.

## 1. GitHub Actions

Workflows incluidos:

- `ci.yml`: en cada push/PR a `main` y `develop`.
  - **backend**: instala `requirements.txt`, revisa errores graves con ruff y compila.
  - **web-negocio**: `pnpm install`, `pnpm lint`, `pnpm build` (guarda `dist` como artifact en `main`).
  - **movil-cliente / movil-negocio**: `flutter analyze` y `flutter test` (si existe `test/`).
  - **notify-slack**: manda alerta si algo falla.
- `release.yml`: al crear un tag `v*`, construye ambos APK y el build web y los publica en un Release.
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

## Pendientes detectados

- En `main`, `web-negocio` no compila (variables sin usar, TS6133, y el import `EditShopPayloal` en `src/modules/shop/api.ts`). En `develop` ya compila.
- `backend` no tiene pruebas; se recomienda agregar `pytest` y un job de pruebas.
- `movil-negocio` no tiene carpeta `test/`.
