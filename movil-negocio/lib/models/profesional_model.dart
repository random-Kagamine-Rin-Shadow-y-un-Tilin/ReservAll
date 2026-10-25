class Professional {
  final int idProfesional;
  final int negocioId;
  final String nombre;
  final String? especialidad;
  final bool activo;

  Professional({
    required this.idProfesional,
    required this.negocioId,
    required this.nombre,
    this.especialidad,
    this.activo = true,
  });

  factory Professional.fromJson(Map<String, dynamic> json) {
    return Professional(
      idProfesional: json['id_profesional'] is int
          ? json['id_profesional']
          : int.tryParse(json['id_profesional'].toString()) ?? 0,
      negocioId: json['negocio_id'] is int
          ? json['negocio_id']
          : int.tryParse(json['negocio_id'].toString()) ?? 0,
      nombre: json['nombre'] ?? '',
      especialidad: json['especialidad'],
      activo: json['activo'] ?? true,
    );
  }
}

class ProfessionalCreateRequest {
  final String nombre;
  final String? especialidad;

  ProfessionalCreateRequest({
    required this.nombre,
    this.especialidad,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'especialidad': especialidad
  };
}
