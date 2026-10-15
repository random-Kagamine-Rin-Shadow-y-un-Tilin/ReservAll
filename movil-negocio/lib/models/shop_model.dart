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

class ShopContact {
  final int idSocial;
  final String nombreRed;
  final String url;

  ShopContact({
    required this.idSocial,
    required this.nombreRed,
    required this.url,
  });

  factory ShopContact.fromJson(Map<String, dynamic> json) {
    return ShopContact(
      idSocial: json['id_social'] is int
          ? json['id_social']
          : int.tryParse(json['id_social'].toString()) ?? 0,
      nombreRed: json['nombre_red'] ?? '',
      url: json['url'] ?? '',
    );
  }
}

class ShopSchedule {
  final int idHorario;
  final String dia;
  final String horaApertura;
  final String horaCierre;
  final String? horaDescanso;
  final bool? estadoHorario;

  ShopSchedule({
    required this.idHorario,
    required this.dia,
    required this.horaApertura,
    required this.horaCierre,
    this.horaDescanso,
    this.estadoHorario,
  });

  factory ShopSchedule.fromJson(Map<String, dynamic> json) {
    return ShopSchedule(
      idHorario: json['id_horario'] is int
          ? json['id_horario']
          : int.tryParse(json['id_horario'].toString()) ?? 0,
      dia: json['dia'] ?? '',
      horaApertura: json['hora_apertura'] ?? '',
      horaCierre: json['hora_cierre'] ?? '',
      horaDescanso: json['hora_descanso'],
      estadoHorario: json['estado_horario'] ?? true,
    );
  }

  
}

class ShopFullProfile {
  final Shop general;
  final List<ShopContact> contacts;
  final List<ShopSchedule> schedules;

  ShopFullProfile({
    required this.general,
    this.contacts = const [],
    this.schedules = const [],
  });

  factory ShopFullProfile.fromJson(Map<String, dynamic> json) {
    return ShopFullProfile(
      general: Shop.fromJson(json['general'] ?? {}),
      contacts:
          (json['contacto'] as List?)
              ?.map((e) => ShopContact.fromJson(e))
              .toList() ??
          [],
      schedules:
          (json['horario'] as List?)
              ?.map((e) => ShopSchedule.fromJson(e))
              .toList() ??
          [],
    );
  }
}
