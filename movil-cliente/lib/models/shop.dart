class Shop {
  final int id;
  final String nombre;
  final String descripcion;
  final String imagenNegocio;
  final String categoriaNegocio;
  final int? idCategoria;
  final String? direccion;
  final String? ciudad;
  final double? valoracion;
  final double? precioMinimo;
  final double? precioMaximo;
  final int serviciosCount;
  final List<String> servicios;
  final double? distanciaKm;

  Shop({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.imagenNegocio,
    required this.categoriaNegocio,
    this.idCategoria,
    this.direccion,
    this.ciudad,
    this.valoracion,
    this.precioMinimo,
    this.precioMaximo,
    this.serviciosCount = 0,
    this.servicios = const [],
    this.distanciaKm,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: _toInt(json['id']) ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      imagenNegocio: json['imagen_negocio']?.toString() ?? '',
      categoriaNegocio: json['categoria_negocio']?.toString() ?? 'General',
      idCategoria: _toInt(json['id_categoria']),
      direccion: _toStringOrNull(json['direccion']),
      ciudad: _toStringOrNull(json['ciudad']),
      valoracion: _toDouble(json['valoracion']),
      precioMinimo: _toDouble(json['precio_minimo']),
      precioMaximo: _toDouble(json['precio_maximo']),
      serviciosCount: _toInt(json['servicios_count']) ?? 0,
      servicios: (json['servicios'] as List? ?? [])
          .map((item) => item.toString())
          .toList(),
      distanciaKm: _toDouble(json['distancia_km']),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static String? _toStringOrNull(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return null;
    return text;
  }
}

class ShopCategory {
  final int id;
  final String nombre;
  final int negociosCount;

  ShopCategory({
    required this.id,
    required this.nombre,
    required this.negociosCount,
  });

  factory ShopCategory.fromJson(Map<String, dynamic> json) {
    return ShopCategory(
      id: int.tryParse(json['id_categoria'].toString()) ?? 0,
      nombre: json['nombre_categoria']?.toString() ?? '',
      negociosCount: int.tryParse(json['negocios_count'].toString()) ?? 0,
    );
  }
}

class ShopDetail {
  final Shop general;
  final Map<String, dynamic>? direccion;
  final List<Map<String, dynamic>> horarios;
  final List<Map<String, dynamic>> servicios;

  ShopDetail({
    required this.general,
    this.direccion,
    this.horarios = const [],
    this.servicios = const [],
  });

  factory ShopDetail.fromJson(Map<String, dynamic> json) {
    return ShopDetail(
      general: Shop.fromJson(
        Map<String, dynamic>.from(json['general'] as Map? ?? {}),
      ),
      direccion: json['direccion'] == null
          ? null
          : Map<String, dynamic>.from(json['direccion'] as Map),
      horarios: (json['horarios'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(),
      servicios: (json['servicios'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(),
    );
  }
}
