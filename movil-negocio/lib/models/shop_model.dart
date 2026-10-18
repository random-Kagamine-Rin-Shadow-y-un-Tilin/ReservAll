class Shop {
  final int? id;
  final String nombre;
  final String descripcion;
  final String? imagenNegocio;
  final String? categoriaNegocio;
  final int? idCategoria;
  final int? duenoId;
  final bool? estadoNegocio;
  final String? fechaCreacion;

  Shop({
    this.id,
    required this.nombre,
    required this.descripcion,
    this.imagenNegocio,
    this.categoriaNegocio,
    this.idCategoria,
    this.duenoId,
    this.estadoNegocio,
    this.fechaCreacion,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    final shop = Shop(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      imagenNegocio: json['imagen_negocio'],
      categoriaNegocio: json['categoria_negocio']?.toString(),
      idCategoria: json['id_categoria'] is int
          ? json['id_categoria']
          : int.tryParse(json['id_categoria']?.toString() ?? ''),
      duenoId: json['dueno_id'],
      estadoNegocio: json['estado_negocio'] ?? true,
      fechaCreacion: json['fecha_creacion'],
    );

    return shop;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'imagen_negocio': imagenNegocio,
      'categoria_negocio': categoriaNegocio,
      'id_categoria': idCategoria,
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
    String? categoriaNegocio,
    int? idCategoria,
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
      idCategoria: idCategoria ?? this.idCategoria,
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

class ShopEditRequest {
  final String nombre;
  final String descripcion;
  final String? imagenNegocio;
  final int fkCategoria;

  ShopEditRequest({
    required this.nombre,
    required this.descripcion,
    this.imagenNegocio,
    required this.fkCategoria,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'descripcion': descripcion,
    'imagen_negocio': imagenNegocio ?? 'null',
    'fk_categoria': fkCategoria,
  };
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

  Map<String, dynamic> toJson() => {
    'id_social': idSocial,
    'nombre_red': nombreRed,
    'url': url,
  };
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

  Map<String, dynamic> toJson() => {
    'id_horario': idHorario,
    'dia': dia,
    'hora_apertura': horaApertura,
    'hora_cierre': horaCierre,
    'hora_descanso': horaDescanso,
    'estado_horario': estadoHorario,
  };
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

class ShopContactCreateRequest {
  final String nombreRed;
  final String url;

  ShopContactCreateRequest({required this.nombreRed, required this.url});

  Map<String, dynamic> toJson() => {'nombre_red': nombreRed, 'url': url};
}
