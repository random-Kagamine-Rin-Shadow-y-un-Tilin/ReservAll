# srln_negocio_app

App Flutter de negocio. Por defecto apunta al **backend local** en
`http://localhost:8000/api/v1`.

## 1. Backend local

Desde la carpeta `backend/` (con el entorno virtual activo):

```powershell
uvicorn app.main:app --reload --port 8000
```

Verifica que responda en <http://127.0.0.1:8000/docs>.

## 2. Celular conectado por USB (recomendado)

En un celular físico, `localhost` apunta al propio celular. Hay que redirigir
el puerto 8000 del teléfono al de la PC:

```powershell
adb reverse tcp:8000 tcp:8000
```

Eso se puede hacer automáticamente junto con el `flutter run`:

```powershell
.\scripts\run_local.ps1
```

También acepta argumentos de Flutter, por ejemplo:

```powershell
.\scripts\run_local.ps1 -d <id-del-dispositivo>
```

Si solo quieres preparar el USB sin ejecutar la app:

```powershell
.\scripts\setup_usb.ps1
```

> El `adb reverse` se pierde al desconectar/reconectar el cable o al reiniciar
> el servidor adb. Vuelve a ejecutar el script en cada sesión.

## 3. Alternativa: IP de la PC en la red

Si el celular está en la misma Wi‑Fi, se puede usar la IP de la PC en vez de
`adb reverse`. El backend debe escuchar en todas las interfaces:

```powershell
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

```powershell
flutter run --dart-define=API_URL=http://192.168.1.10:8000
```

La API key también es configurable:

```powershell
flutter run --dart-define=API_URL=http://192.168.1.10:8000 --dart-define=API_KEY=tu_clave
```

## Configuración

Los valores están en `lib/config/app_config.dart`:

| Variable (`--dart-define`) | Valor por defecto        |
| -------------------------- | ------------------------ |
| `API_URL`                  | `http://localhost:8000`  |
| `API_KEY`                  | clave del proyecto       |

La URL final es `$API_URL/api/v1`.

## Solución de problemas

- **"No se puede conectar al servidor"**: el backend no está corriendo o falta
  `adb reverse`; ejecuta `.\scripts\setup_usb.ps1`.
- **`CLEARTEXT communication not permitted`**: las variantes debug y profile ya
  incluyen `android:usesCleartextTraffic="true"`. Para builds release con HTTP,
  agrégalo también a `android/app/src/main/AndroidManifest.xml` (mejor usar
  HTTPS en producción).
- **El dispositivo no aparece**: activa "Depuración USB" en el celular y acepta el
  diálogo de autorización; comprueba con `adb devices`.
- **Sesión expirada**: vuelve a iniciar sesión; las cookies se guardan solo en
  memoria mientras la app está abierta.
