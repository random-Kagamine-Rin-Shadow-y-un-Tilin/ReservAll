import 'profesional_model.dart';

class Service {
  final int idServicio;
  final int negocioId;
  final String nombre;
  final String? descripcion;
  final int duracionMinutos;
  final double precio;
  final String categoriaServicio;
  final int cantidadServicio;
  final bool estadoServicio;
  final List<Professional> profesionales;

  Service({
    required this.idServicio,
    required this.negocioId,
    required this.nombre,
    this.descripcion,
    required this.duracionMinutos,
    required this.precio,
    this.categoriaServicio = 'servicio',
    this.cantidadServicio = 1,
    this.estadoServicio = true,
    this.profesionales = const [],
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      idServicio: json['id_servicio'] is int
          ? json['id_servicio']
          : int.tryParse(json['id_servicio'].toString()) ?? 0,
      negocioId: json['negocio_id'] is int
          ? json['negocio_id']
          : int.tryParse(json['negocio_id'].toString()) ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      duracionMinutos: json['duracion_minutos'] is int
          ? json['duracion_minutos']
          : int.tryParse(json['duracion_minutos'].toString()) ?? 60,
      precio: (json['precio'] is num)
          ? json['precio'].toDouble()
          : double.tryParse(json['precio'].toString()) ?? 0,
      categoriaServicio: json['categoria_servicio'] ?? 'servicio',
      cantidadServicio: json['cantidad_servicio'] is int
          ? json['cantidad_servicio']
          : int.tryParse(json['cantidad_servicio'].toString()) ?? 1,
      estadoServicio: json['estado_servicio'] ?? true,
      profesionales: (json['profesionales'] as List?)
              ?.map((e) => Professional.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ServiceCreateRequest {
  final String nombre;
  final String? descripcion;
  final int duracionMinutos;
  final double precio;
  final String categoriaServicio;
  final int cantidadServicio;
  final List<int> profesionalIds;

  ServiceCreateRequest({
    required this.nombre,
    this.descripcion,
    this.duracionMinutos = 60,
    this.precio = 0,
    this.categoriaServicio = 'servicio',
    this.cantidadServicio = 1,
    this.profesionalIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'descripcion': descripcion,
        'duracion_minutos': duracionMinutos,
        'precio': precio,
        'categoria_servicio': categoriaServicio,
        'cantidad_servicio': cantidadServicio,
        'profesional_ids': profesionalIds,
      };
 
}

class ServiceEditRequest {
  final String? nombre;
  final String? descripcion;
  final int? duracionMinutos;
  final double? precio;
  final String? categoriaServicio;
  final int? cantidadServicio;
  final bool? estadoServicio;
  final List<int>? profesionalIds;

  ServiceEditRequest({
    this.nombre,
    this.descripcion,
    this.duracionMinutos,
    this.precio,
    this.categoriaServicio,
    this.cantidadServicio,
    this.estadoServicio,
    this.profesionalIds,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (nombre != null) map['nombre'] = nombre;
    if (descripcion != null) map['descripcion'] = descripcion;
    if (duracionMinutos != null) map['duracion_minutos'] = duracionMinutos;
    if (precio != null) map['precio'] = precio;
    if (categoriaServicio != null) map['categoria_servicio'] = categoriaServicio;
    if (cantidadServicio != null) map['cantidad_servicio'] = cantidadServicio;
    if (estadoServicio != null) map['estado_servicio'] = estadoServicio;
    if (profesionalIds != null) map['profesional_ids'] = profesionalIds;
    return map;
  }
}