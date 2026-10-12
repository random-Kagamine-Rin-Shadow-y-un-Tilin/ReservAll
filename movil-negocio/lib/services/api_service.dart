import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import '../config/app_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  late CookieJar _cookieJar;

  String get baseUrl => AppConfig.baseUrl;

  void init() {
    _cookieJar = CookieJar();
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'x-api-key': AppConfig.apiKey,
      },
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
    ));

    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 👇 POST CORREGIDO PARA MANEJAR FormData
  Future<Response> post(
    String endpoint, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    try {
      // Si body es FormData, no sobrescribir Content-Type
      final options = Options();
      
      if (body is FormData) {
        // FormData ya tiene su propio Content-Type
        options.headers = {
          'Accept': 'application/json',
          'x-api-key': AppConfig.apiKey,
        };
      }
      
      final response = await _dio.post(
        endpoint,
        data: body,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(
    String endpoint, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: body,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return Exception('Tiempo de espera agotado.');
    }

    if (e.type == DioExceptionType.connectionError) {
      return Exception('No se puede conectar al servidor.');
    }

    if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

      if (statusCode == 401 || statusCode == 403) {
        return Exception('Sesión expirada. Inicia sesión nuevamente.');
      }

      String message = 'Error del servidor';
      if (data != null) {
        if (data is Map) {
          message = data['detail'] ?? data['message'] ?? message;
        } else if (data is String) {
          message = data;
        }
      }
      return Exception(message);
    }

    return Exception('Error de conexión: ${e.message}');
  }

  Future<void> clearCookies() async {
    await _cookieJar.deleteAll();
  }

  Future<List<Cookie>?> getCookies() async {
    try {
      final uri = Uri.parse(baseUrl);
      return await _cookieJar.loadForRequest(uri);
    } catch (e) {
      return null;
    }
  }
}