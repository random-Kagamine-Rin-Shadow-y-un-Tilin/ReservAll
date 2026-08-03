class Shop {
  final int id;
  final String nombre;
  final String descripcion;
  final String imagenNegocio;
  final String categoriaNegocio;

  Shop({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.imagenNegocio,
    required this.categoriaNegocio,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      imagenNegocio: json['imagen_negocio'],
      categoriaNegocio: json['categoria_negocio'],
    );
  }
}
