# Migraciones de ReservAll

Aplicar en orden sobre la base de datos configurada en `backend/.env`:

```bash
psql "$DATABASE_URL" -f migrations/001_create_bloqueos_agenda.sql
psql "$DATABASE_URL" -f migrations/002_reservas_historial.sql
psql "$DATABASE_URL" -f migrations/003_direcciones_negocio_ubicacion.sql
psql "$DATABASE_URL" -f migrations/004_password_reset_categorias.sql
psql "$DATABASE_URL" -f migrations/005_horarios_turnos_multiples.sql
psql "$DATABASE_URL" -f migrations/006_categorias_nombre_unico.sql
```

Todas son idempotentes. La `006` se omite si existen nombres de categoría
duplicados; en ese caso hay que limpiar los datos y volver a ejecutarla.

## Cuenta administradora (HU_14)

El registro público (`POST /api/v1/auth/register`) solo permite `cliente` y
`negocio`. La cuenta `admin` que gestiona categorías se crea fuera de la API:

1. Desde `backend/`, generar el hash:

   ```bash
   python -c "from app.core.security import hash_password; print(hash_password('ContraseñaSegura123'))"
   ```

2. Insertar la cuenta (sustituir nombre, correo y hash):

   ```sql
   INSERT INTO public.usuarios (nombre, correo, password_hash, rol, fecha_registro)
   VALUES ('Administrador', 'admin@reservall.local', '<hash>', 'admin', now());
   ```

3. Iniciar sesión normalmente. El access token incluye `rol=admin`, que es lo
   que valida `get_current_admin` en `/api/v1/categories`.

## Configuración de entorno

Variables nuevas usadas por el backend:

| Variable | Default | Uso |
|---|---|---|
| `CORS_ORIGINS` | `http://localhost:5173` | Orígenes permitidos, separados por coma |
| `COOKIE_SECURE` | `false` | Poner `true` en HTTPS/producción |
| `COOKIE_SAMESITE` | `lax` | Política SameSite de las cookies |
| `SMTP_HOST` / `SMTP_PORT` / `SMTP_FROM` | — | Envío del código de HU_03 |
| `SMTP_USER` / `SMTP_PASSWORD` | — | Credenciales SMTP (opcional) |
| `SMTP_USE_TLS` | `true` | STARTTLS |
| `PASSWORD_RESET_CODE_TTL_MINUTES` | `15` | Vigencia del código |
| `PASSWORD_RESET_RETURN_CODE` | `false` | Solo desarrollo: devuelve el código en la respuesta |

Sin SMTP ni `PASSWORD_RESET_RETURN_CODE=true`, `/forgot-password` responde
`503` para no crear códigos que nadie pueda recibir.

HU_03 permite como máximo 5 intentos por código antes de invalidarlo; el
contador se guarda en `password_reset_codes.intentos`.
