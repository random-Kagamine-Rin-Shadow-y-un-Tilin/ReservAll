/// HU_14: categoría devuelta por `CategoryView` en el backend.
class Category {
  final int idCategoria;
  final String nombreCategoria;
  final int negociosCount;
  final String? descripcion;
  final bool estado;

  Category({
    required this.idCategoria,
    required this.nombreCategoria,
    this.negociosCount = 0,
    this.descripcion,
    this.estado = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      idCategoria: json['id_categoria'] is int
          ? json['id_categoria'] as int
          : int.tryParse(json['id_categoria']?.toString() ?? '') ?? 0,
      nombreCategoria: json['nombre_categoria'] ?? '',
      negociosCount: json['negocios_count'] is int
          ? json['negocios_count'] as int
          : int.tryParse(json['negocios_count']?.toString() ?? '') ?? 0,
      descripcion: json['descripcion'] as String?,
      estado: json['estado'] ?? true,
    );
  }
}

/// HU_14: payload de alta/edición (`CategoryCreate` / `CategoryUpdate`).
class CategoryInput {
  final String? nombreCategoria;
  final String? descripcion;
  final bool? estado;

  CategoryInput({this.nombreCategoria, this.descripcion, this.estado});

  Map<String, dynamic> toJson() => {
    if (nombreCategoria != null) 'nombre_categoria': nombreCategoria!.trim(),
    if (descripcion != null)
      'descripcion': descripcion!.trim().isEmpty ? null : descripcion!.trim(),
    if (estado != null) 'estado': estado,
  };
}
