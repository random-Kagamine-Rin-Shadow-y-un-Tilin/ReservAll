enum EstadoReserva {
  pendiente,
  confirmada,
  cancelada,
  completada;

  static EstadoReserva fromString(String s) => EstadoReserva.values.firstWhere(
        (e) => e.name == s,
        orElse: () => EstadoReserva.pendiente,
      );

  String get label => switch (this) {
        EstadoReserva.pendiente => 'Pendiente',
        EstadoReserva.confirmada => 'Confirmada',
        EstadoReserva.cancelada => 'Cancelada',
        EstadoReserva.completada => 'Completada',
      };
}

class ReservaListItem {
  final int idReserva;
  final DateTime fecha;
  final String horaInicio;
  final String? horaFin;
  final EstadoReserva estado;
  final int clienteId;
  final String clienteNombre;
  final String clienteCorreo;
  final int servicioId;
  final String servicioNombre;
  final int servicioDuracion;
  final double servicioPrecio;
  final int? profesionalId;
  final String? profesionalNombre;

  ReservaListItem({
    required this.idReserva,
    required this.fecha,
    required this.horaInicio,
    this.horaFin,
    required this.estado,
    required this.clienteId,
    required this.clienteNombre,
    required this.clienteCorreo,
    required this.servicioId,
    required this.servicioNombre,
    required this.servicioDuracion,
    required this.servicioPrecio,
    this.profesionalId,
    this.profesionalNombre,
  });

  factory ReservaListItem.fromJson(Map<String, dynamic> j) => ReservaListItem(
        idReserva: int.tryParse('${j['id_reserva']}') ?? 0,
        fecha: DateTime.tryParse('${j['fecha']}') ?? DateTime.now(),
        horaInicio: j['hora_inicio']?.toString() ?? '',
        horaFin: j['hora_fin']?.toString(),
        estado: EstadoReserva.fromString(j['estado']?.toString() ?? 'pendiente'),
        clienteId: int.tryParse('${j['cliente_id']}') ?? 0,
        clienteNombre: j['cliente_nombre']?.toString() ?? '',
        clienteCorreo: j['cliente_correo']?.toString() ?? '',
        servicioId: int.tryParse('${j['servicio_id']}') ?? 0,
        servicioNombre: j['servicio_nombre']?.toString() ?? '',
        servicioDuracion: int.tryParse(
              '${j['duracion_minutos'] ?? j['servicio_duracion']}',
            ) ??
            0,
        servicioPrecio:
            double.tryParse('${j['precio'] ?? j['servicio_precio']}') ?? 0.0,
        profesionalId: j['profesional_id'] == null
            ? null
            : int.tryParse('${j['profesional_id']}'),
        profesionalNombre: j['profesional_nombre']?.toString(),
      );

  ReservaListItem copyWith({EstadoReserva? estado}) => ReservaListItem(
        idReserva: idReserva,
        fecha: fecha,
        horaInicio: horaInicio,
        horaFin: horaFin,
        estado: estado ?? this.estado,
        clienteId: clienteId,
        clienteNombre: clienteNombre,
        clienteCorreo: clienteCorreo,
        servicioId: servicioId,
        servicioNombre: servicioNombre,
        servicioDuracion: servicioDuracion,
        servicioPrecio: servicioPrecio,
        profesionalId: profesionalId,
        profesionalNombre: profesionalNombre,
      );
}

/// Reserva próxima junto con el negocio al que pertenece.
///
/// Se usa en el resumen del inicio, donde se combinan las reservas de
/// todos los negocios del dueño.
class ReservaProxima {
  final ReservaListItem reserva;
  final int negocioId;
  final String negocioNombre;

  ReservaProxima({
    required this.reserva,
    required this.negocioId,
    required this.negocioNombre,
  });
}

class ReservasListResponse {
  final int total;
  final int limit;
  final int offset;
  final List<ReservaListItem> items;

  ReservasListResponse({
    required this.total,
    required this.limit,
    required this.offset,
    required this.items,
  });

  factory ReservasListResponse.fromJson(Map<String, dynamic> j) {
    final items = (j['items'] as List? ?? [])
        .map((e) => ReservaListItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final summary = j['summary'];
    final total = summary is Map
        ? int.tryParse('${summary['total']}') ?? items.length
        : int.tryParse('${j['total']}') ?? items.length;

    return ReservasListResponse(
      total: total,
      limit: int.tryParse('${j['limit']}') ?? 20,
      offset: int.tryParse('${j['offset']}') ?? 0,
      items: items,
    );
  }
}

class ReservaDetalle {
  final int idReserva;
  final DateTime fecha;
  final String horaInicio;
  final String? horaFin;
  final EstadoReserva estado;
  final String? comentario;
  final String? motivo;
  final String clienteNombre;
  final String clienteCorreo;
  final String servicioNombre;
  final int servicioDuracion;
  final double servicioPrecio;
  final String? servicioCategoria;
  final int negocioId;
  final String negocioNombre;
  final int? profesionalId;
  final String? profesionalNombre;
  final String? profesionalEspecialidad;

  ReservaDetalle({
    required this.idReserva,
    required this.fecha,
    required this.horaInicio,
    this.horaFin,
    required this.estado,
    this.comentario,
    this.motivo,
    required this.clienteNombre,
    required this.clienteCorreo,
    required this.servicioNombre,
    required this.servicioDuracion,
    required this.servicioPrecio,
    this.servicioCategoria,
    required this.negocioId,
    required this.negocioNombre,
    this.profesionalId,
    this.profesionalNombre,
    this.profesionalEspecialidad,
  });

  factory ReservaDetalle.fromJson(Map<String, dynamic> j) => ReservaDetalle(
        idReserva: int.tryParse('${j['id_reserva']}') ?? 0,
        fecha: DateTime.tryParse('${j['fecha']}') ?? DateTime.now(),
        horaInicio: j['hora_inicio']?.toString() ?? '',
        horaFin: j['hora_fin']?.toString(),
        estado: EstadoReserva.fromString(j['estado']?.toString() ?? 'pendiente'),
        comentario: j['comentario']?.toString(),
        motivo: j['motivo']?.toString(),
        clienteNombre: j['cliente_nombre']?.toString() ?? '',
        clienteCorreo: j['cliente_correo']?.toString() ?? '',
        servicioNombre: j['servicio_nombre']?.toString() ?? '',
        servicioDuracion: int.tryParse(
              '${j['duracion_minutos'] ?? j['servicio_duracion']}',
            ) ??
            0,
        servicioPrecio:
            double.tryParse('${j['precio'] ?? j['servicio_precio']}') ?? 0.0,
        servicioCategoria: j['servicio_categoria']?.toString(),
        negocioId: int.tryParse('${j['negocio_id']}') ?? 0,
        negocioNombre: j['negocio_nombre']?.toString() ?? '',
        profesionalId: j['profesional_id'] == null
            ? null
            : int.tryParse('${j['profesional_id']}'),
        profesionalNombre: j['profesional_nombre']?.toString(),
        profesionalEspecialidad: j['profesional_especialidad']?.toString(),
      );
}

class ProfesionalItem {
  final int id;
  final String nombre;
  final String? especialidad;

  ProfesionalItem({required this.id, required this.nombre, this.especialidad});

  factory ProfesionalItem.fromJson(Map<String, dynamic> j) => ProfesionalItem(
        id: int.tryParse('${j['id_profesional']}') ?? 0,
        nombre: j['nombre']?.toString() ?? '',
        especialidad: j['especialidad']?.toString(),
      );
}