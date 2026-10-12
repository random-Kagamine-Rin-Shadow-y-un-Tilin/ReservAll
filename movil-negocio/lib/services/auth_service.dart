import '../models/auth_model.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  // Registrar usuario
  Future<User> register(RegisterRequest registerRequest) async {
    try {
      final response = await _apiService.post(
        '/auth/register',
        body: registerRequest.toJson(),
        requiresAuth: false,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        if (response.data == null) {
          throw Exception('Respuesta vacía del servidor');
        }

        if (response.data is! Map<String, dynamic>) {
          throw Exception('Formato de respuesta inválido');
        }

        final data = response.data as Map<String, dynamic>;
        return User.fromJson(data);
      } else {
        final errorData = response.data as Map<String, dynamic>?;
        final message =
            errorData?['detail'] ??
            errorData?['message'] ??
            'Error al registrarse';
        throw Exception(message);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Iniciar sesión
  Future<User> login(LoginRequest loginRequest) async {
    try {
      final response = await _apiService.post(
        '/auth/login',
        body: loginRequest.toJson(),
        requiresAuth: false,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        if (response.data == null) {
          throw Exception('Respuesta vacía del servidor');
        }

        if (response.data is! Map<String, dynamic>) {
          throw Exception('Formato de respuesta inválido');
        }

        final data = response.data as Map<String, dynamic>;

        return User(
          id: data['id'],
          nombre: data['nombre'] ?? '',
          correo: data['correo'] ?? '',
          rol: data['rol'] ?? 'dueno_negocio',
          token: 'session_active',
          refreshToken: null,
        );
      } else {
        final errorData = response.data as Map<String, dynamic>?;
        final message =
            errorData?['detail'] ??
            errorData?['message'] ??
            'Error al iniciar sesión';
        throw Exception(message);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Refrescar token
  Future<bool> refreshToken() async {
    try {
      final response = await _apiService.post(
        '/auth/refresh',
        requiresAuth: true,
      );

      return (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300);
    } catch (e) {
      return false;
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    try {
      await _apiService.post('/auth/logout', requiresAuth: true);
    } catch (e) {
      // Ignorar errores
    } finally {
      await _apiService.clearCookies();
    }
  }

  // Obtener perfil del usuario actual
  Future<User?> getCurrentUser() async {
    try {
      final response = await _apiService.get('/profile/me', requiresAuth: true);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        if (response.data == null) return null;
        if (response.data is! Map<String, dynamic>) return null;

        final data = response.data as Map<String, dynamic>;
        return User.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Verificar si hay sesión activa
  Future<bool> hasActiveSession() async {
    try {
      final cookies = await _apiService.getCookies();

      if (cookies == null || cookies.isEmpty) {
        return false;
      }

      final hasAccessToken = cookies.any(
        (cookie) => cookie.name == 'SNRL_access_token',
      );

      return hasAccessToken;
    } catch (e) {
      return false;
    }
  }
}
