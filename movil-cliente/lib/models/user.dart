class User {
  final String id;
  final String nombre;
  final String correo;
  final String rol;

  User({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
  });

  // Constructor desde JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      nombre: json['nombre'] ?? '',
      correo: json['correo'] ?? '',
      rol: json['rol'] ?? 'cliente',
    );
  }

  // Convertir a JSON 
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
    };
  }
}
