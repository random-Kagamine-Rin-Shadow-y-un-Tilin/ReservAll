class User {
  final int? id;
  final String nombre;
  final String correo;
  final String? rol;
  final String? token;
  final String? refreshToken;

  User({
    this.id,
    required this.nombre,
    required this.correo,
    this.rol,
    this.token,
    this.refreshToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      correo: json['correo'] ?? '',
      rol: json['rol'] ?? 'negocio',
      token: json['token'],
      refreshToken: json['refresh_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
      'token': token,
      'refresh_token': refreshToken,
    };
  }

  User copyWith({
    int? id,
    String? nombre,
    String? correo,
    String? rol,
    String? token,
    String? refreshToken,
  }) {
    return User(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      rol: rol ?? this.rol,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}