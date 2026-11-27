# ReservAll

Sistema para reservas de negocios locales (ReservAll).

## Versionado automático (semantic-release)

Las versiones y el `CHANGELOG.md` se generan automáticamente con
[semantic-release](https://semantic-release.gitbook.io/semantic-release/) cuando
se hace merge en `main`. No hay que crear tags a mano.

Los mensajes de commit deben seguir **Conventional Commits**:

| Mensaje | Versión resultante |
|---|---|
| `fix(...): ...` | patch (`1.0.0` → `1.0.1`) |
| `feat(...): ...` | minor (`1.0.0` → `1.1.0`) |
| `feat(...): ...` con `BREAKING CHANGE:` en el cuerpo | major (`1.0.0` → `2.0.0`) |
| `docs:`, `chore:`, `config:`, `refactor:` | no generan release |

Flujo:

1. `develop` → PR a `main`.
2. El workflow **Semantic Release** analiza los commits, actualiza `VERSION`,
   `CHANGELOG.md`, `package.json`, `web-negocio/package.json` y los `pubspec.yaml`
   (sube el número de build de Flutter), crea el tag `vX.Y.Z` y publica el GitHub
   Release con las notas.
3. El workflow **Release** se dispara con ese Release, compila los APK y el zip
   web y los adjunta al Release.

Para probar la configuración sin publicar:

```bash
pnpm install
pnpm release:dry
```

Si `main` tiene protección de rama que impide el push del commit de versión,
configura el secreto `GH_TOKEN` con un PAT que tenga permiso `contents: write`.
