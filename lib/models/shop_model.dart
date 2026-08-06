class Shop {
  final int? id;
  final String nombre;
  final String descripcion;
  final String? imagenNegocio;
  final int categoriaNegocio;
  final int? duenoId;
  final bool? estadoNegocio;
  final String? fechaCreacion;

  Shop({
    this.id,
    required this.nombre,
    required this.descripcion,
    this.imagenNegocio,
    required this.categoriaNegocio,
    this.duenoId,
    this.estadoNegocio,
    this.fechaCreacion,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()),
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      imagenNegocio: json['imagen_negocio'] ?? json['imagenNegocio'],
      // 👇 CONVERTIR A INT DE FORMA SEGURA
      categoriaNegocio: json['categoria_negocio'] is int 
          ? json['categoria_negocio'] 
          : int.tryParse(json['categoria_negocio'].toString()) ?? 0,
      duenoId: json['dueno_id'] is int 
          ? json['dueno_id'] 
          : int.tryParse(json['dueno_id'].toString()),
      estadoNegocio: json['estado_negocio'] ?? json['estadoNegocio'],
      fechaCreacion: json['fecha_creacion'] ?? json['fechaCreacion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'imagen_negocio': imagenNegocio,
      'categoria_negocio': categoriaNegocio,
      'dueno_id': duenoId,
      'estado_negocio': estadoNegocio,
      'fecha_creacion': fechaCreacion,
    };
  }

  Shop copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    String? imagenNegocio,
    int? categoriaNegocio,
    int? duenoId,
    bool? estadoNegocio,
    String? fechaCreacion,
  }) {
    return Shop(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      imagenNegocio: imagenNegocio ?? this.imagenNegocio,
      categoriaNegocio: categoriaNegocio ?? this.categoriaNegocio,
      duenoId: duenoId ?? this.duenoId,
      estadoNegocio: estadoNegocio ?? this.estadoNegocio,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}


class RegisterShopRequest {
  final String nombre;
  final String descripcion;
  final String? imagenNegocio;
  final int categoriaNegocio;

  RegisterShopRequest({
    required this.nombre,
    required this.descripcion,
    this.imagenNegocio,
    required this.categoriaNegocio,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'imagen_negocio': imagenNegocio ?? 'null',
      'categoria_negocio': categoriaNegocio,
    };
  }
}