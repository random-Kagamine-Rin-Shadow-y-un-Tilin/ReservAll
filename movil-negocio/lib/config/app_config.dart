class AppConfig {
  /// URL del backend.
  ///
  /// Por defecto usa `http://localhost:8000`, que funciona con el celular
  /// conectado por USB después de ejecutar:
  ///
  ///   adb reverse tcp:8000 tcp:8000
  ///
  /// También se puede usar la IP de la PC en la misma red:
  ///
  ///   flutter run --dart-define=API_URL=http://192.168.1.10:8000
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue:
        '25c78a3206e58231c87783cdbc8359584767c6718f1fcaedb9a406c5a6971e4c',
  );

  static const String apiVersion = 'v1';
  static String get baseUrl => '$apiUrl/api/$apiVersion';
  static const Duration connectionTimeout = Duration(seconds: 60);
}
