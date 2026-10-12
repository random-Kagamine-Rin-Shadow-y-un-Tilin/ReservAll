import 'user_model.dart';

// Request para registro
class RegisterRequest {
  final String nombre;
  final String correo;
  final String password;
  final String confirmPassword;
  final String rol;

  RegisterRequest({
    required this.nombre,
    required this.correo,
    required this.password,
    required this.confirmPassword,
    this.rol = 'negocio',
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'correo': correo,
      'password': password,
      'confirm_password': confirmPassword,
      'rol': rol,
    };
  }
}

// Request para login
class LoginRequest {
  final String correo;
  final String password;

  LoginRequest({
    required this.correo,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'correo': correo,
      'password': password,
    };
  }
}

// Request para refresh token
class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({
    required this.refreshToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'refresh_token': refreshToken,
    };
  }
}

// Response de autenticación
class AuthResponse {
  final User user;
  final String token;
  final String refreshToken;

  AuthResponse({
    required this.user,
    required this.token,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    
    return AuthResponse(
      user: User.fromJson(data),
      token: data['token'] ?? '',
      refreshToken: data['refresh_token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
      'refresh_token': refreshToken,
    };
  }
}