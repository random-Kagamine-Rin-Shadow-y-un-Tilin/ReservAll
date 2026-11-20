import '../services/service_description_helper.dart';

class ServiceModel {
  final int idServicio;
  final int negocioId;
  final String nombre;
  final int duracionMinutos;
  final double precio;
  final String descripcion;
  final String categoriaServicio;
  final int cantidadServicio;
  final bool estadoServicio;
  final String? nombreNegocio;
  final String? horarioDisponibilidad;

  ServiceModel({
    required this.idServicio,
    required this.negocioId,
    required this.nombre,
    required this.duracionMinutos,
    required this.precio,
    required this.descripcion,
    this.categoriaServicio = 'servicio',
    this.cantidadServicio = 1,
    this.estadoServicio = true,
    this.nombreNegocio,
    this.horarioDisponibilidad,
  });

  static bool _parseEstadoServicio(dynamic rawEstado) {
    if (rawEstado == null) return true;
    if (rawEstado is bool) return rawEstado;
    if (rawEstado is num) return rawEstado != 0;
    final normalized = rawEstado.toString().trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'null') return true;
    return normalized == 'true' || normalized == '1' || normalized == 'activo';
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final nestedNegocio = json['negocio'] is Map<String, dynamic>
        ? json['negocio'] as Map<String, dynamic>
        : null;

    final int parsedId =
        int.tryParse((json['id_servicio'] ?? json['id'] ?? 0).toString()) ?? 0;
    final String parsedName =
        (json['nombre'] ?? 'Servicio sin nombre').toString().trim();

    return ServiceModel(
      idServicio: parsedId,
      negocioId: int.tryParse((json['negocio_id'] ?? 0).toString()) ?? 0,
      nombre: parsedName.isEmpty ? 'Servicio sin nombre' : parsedName,
      duracionMinutos:
          int.tryParse((json['duracion_minutos'] ?? 60).toString()) ?? 60,
      precio: double.tryParse((json['precio'] ?? 0).toString()) ?? 0.0,
      descripcion: ServiceDescriptionHelper.resolve(
        raw: json,
        serviceId: parsedId > 0 ? parsedId : null,
        serviceName: parsedName,
      ),
      categoriaServicio: (json['categoria_servicio'] ?? 'servicio').toString(),
      cantidadServicio:
          int.tryParse((json['cantidad_servicio'] ?? 1).toString()) ?? 1,
      estadoServicio: _parseEstadoServicio(json['estado_servicio']),
      nombreNegocio: (json['nombre_negocio'] ??
              nestedNegocio?['nombre'] ??
              nestedNegocio?['nombre_negocio'])
          ?.toString(),
      horarioDisponibilidad: (json['disponibilidad'] ??
              json['horario_disponibilidad'] ??
              nestedNegocio?['horario'])
          ?.toString(),
    );
  }

  ServiceModel copyWith({
    int? idServicio,
    int? negocioId,
    String? nombre,
    int? duracionMinutos,
    double? precio,
    String? descripcion,
    String? categoriaServicio,
    int? cantidadServicio,
    bool? estadoServicio,
    String? nombreNegocio,
    String? horarioDisponibilidad,
  }) {
    return ServiceModel(
      idServicio: idServicio ?? this.idServicio,
      negocioId: negocioId ?? this.negocioId,
      nombre: nombre ?? this.nombre,
      duracionMinutos: duracionMinutos ?? this.duracionMinutos,
      precio: precio ?? this.precio,
      descripcion: descripcion ?? this.descripcion,
      categoriaServicio: categoriaServicio ?? this.categoriaServicio,
      cantidadServicio: cantidadServicio ?? this.cantidadServicio,
      estadoServicio: estadoServicio ?? this.estadoServicio,
      nombreNegocio: nombreNegocio ?? this.nombreNegocio,
      horarioDisponibilidad:
          horarioDisponibilidad ?? this.horarioDisponibilidad,
    );
  }

  bool get estaDisponible => estadoServicio && cantidadServicio > 0;

  String get duracionFormateada {
    if (duracionMinutos < 60) return '$duracionMinutos min';
    final horas = duracionMinutos ~/ 60;
    final mins = duracionMinutos % 60;
    if (mins == 0) return horas == 1 ? '1 hora' : '$horas horas';
    return '${horas}h${mins}m';
  }
}