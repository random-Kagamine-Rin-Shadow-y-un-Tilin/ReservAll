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

  LoginRequest({required this.correo, required this.password});

  Map<String, dynamic> toJson() {
    return {'correo': correo, 'password': password};
  }
}

// HU_03: respuesta de POST /auth/forgot-password
class PasswordResetRequestOut {
  final String mensaje;
  final int expiraEnMinutos;
  // Solo se rellena si el backend corre con PASSWORD_RESET_RETURN_CODE=true.
  final String? codigo;

  PasswordResetRequestOut({
    required this.mensaje,
    required this.expiraEnMinutos,
    this.codigo,
  });

  factory PasswordResetRequestOut.fromJson(Map<String, dynamic> json) {
    final expira = json['expira_en_minutos'];
    return PasswordResetRequestOut(
      mensaje: json['mensaje'] ?? 'Código de recuperación enviado.',
      expiraEnMinutos: expira is int
          ? expira
          : int.tryParse(expira?.toString() ?? '') ?? 15,
      codigo: json['codigo'] as String?,
    );
  }
}

// HU_03: request de POST /auth/reset-password
class PasswordResetConfirmRequest {
  final String correo;
  final String codigo;
  final String nuevaPassword;
  final String confirmPassword;

  PasswordResetConfirmRequest({
    required this.correo,
    required this.codigo,
    required this.nuevaPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
    'correo': correo.trim(),
    'codigo': codigo.trim(),
    'nueva_password': nuevaPassword,
    'confirm_password': confirmPassword,
  };
}

// HU_05: request de PATCH /profile/me.
// Solo se envían los campos que el usuario cambió; el id se toma del token
// en el backend, nunca del cliente.
class ProfileUpdateRequest {
  final String? nombre;
  final String? correo;
  final String? passwordActual;
  final String? passwordNueva;
  final String? confirmPassword;

  ProfileUpdateRequest({
    this.nombre,
    this.correo,
    this.passwordActual,
    this.passwordNueva,
    this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
    if (nombre != null) 'nombre': nombre!.trim(),
    if (correo != null) 'correo': correo!.trim(),
    if (passwordActual != null && passwordActual!.isNotEmpty)
      'password_actual': passwordActual,
    if (passwordNueva != null && passwordNueva!.isNotEmpty)
      'password_nueva': passwordNueva,
    if (confirmPassword != null && confirmPassword!.isNotEmpty)
      'confirm_password': confirmPassword,
  };
}

// Request para refresh token
class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() {
    return {'refresh_token': refreshToken};
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
