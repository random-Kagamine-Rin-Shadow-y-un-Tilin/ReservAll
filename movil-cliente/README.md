# movil-cliente

App Flutter del cliente. Está configurada contra el backend desplegado en
`https://reservall.onrender.com/api/v1`.

## Ejecutar

```bash
flutter pub get
flutter run
```

La URL y la API key se pueden sobrescribir al compilar:

```powershell
flutter run --dart-define=API_URL=http://192.168.1.10:8000 --dart-define=API_KEY=tu_clave
```

Los valores por defecto están en `lib/services/api_service.dart`
(`serverUrl`, `baseUrl` y `apiKey`). La autenticación usa la cookie de sesión
`SNRL_access_token`, guardada en `SharedPreferences` tras el login.

## Notificaciones

Los avisos push se implementan en la PWA (`web-negocio`) y en la app de negocio
(`movil-negocio`). Esta app del cliente solo consume la API; no tiene SDK de
notificaciones instalado.
