// lib/config/app_config.dart
class AppConfig {
  // Cambia esta IP por la que obtuviste con ipconfig
  static const String apiUrl = 'http://10.0.0.11:8000';
  static const String apiKey = '25c78a3206e58231c87783cdbc8359584767c6718f1fcaedb9a406c5a6971e4c';
  
  static const String apiVersion = 'v1';
  static String get baseUrl => '$apiUrl/api/$apiVersion';
  static const Duration connectionTimeout = Duration(seconds: 60);
}