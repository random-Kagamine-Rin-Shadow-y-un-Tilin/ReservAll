import 'reserva_model.dart';

class ClienteResumen {
  final int clienteId;
  final String nombre;
  final String correo;
  final int totalReservas;
  final int completadas;
  final int canceladas;
  final int activas;
  final DateTime? primeraReserva;
  final DateTime? ultimaReserva;
  final double totalGastado;
  final String? servicioFavorito;

  ClienteResumen({
    required this.clienteId,
    required this.nombre,
    required this.correo,
    required this.totalReservas,
    required this.completadas,
    required this.canceladas,
    required this.activas,
    this.primeraReserva,
    this.ultimaReserva,
    required this.totalGastado,
    this.servicioFavorito,
  });

  factory ClienteResumen.fromJson(Map<String, dynamic> json) => ClienteResumen(
        clienteId: int.tryParse('${json['cliente_id']}') ?? 0,
        nombre: json['nombre']?.toString() ?? '',
        correo: json['correo']?.toString() ?? '',
        totalReservas: int.tryParse('${json['total_reservas']}') ?? 0,
        completadas: int.tryParse('${json['completadas']}') ?? 0,
        canceladas: int.tryParse('${json['canceladas']}') ?? 0,
        activas: int.tryParse('${json['activas']}') ?? 0,
        primeraReserva: json['primera_reserva'] == null
            ? null
            : DateTime.tryParse('${json['primera_reserva']}'),
        ultimaReserva: json['ultima_reserva'] == null
            ? null
            : DateTime.tryParse('${json['ultima_reserva']}'),
        totalGastado: double.tryParse('${json['total_gastado']}') ?? 0.0,
        servicioFavorito: json['servicio_favorito']?.toString(),
      );
}

class ClientesListResponse {
  final List<ClienteResumen> items;
  final int total;

  ClientesListResponse({required this.items, required this.total});

  factory ClientesListResponse.fromJson(Map<String, dynamic> json) =>
      ClientesListResponse(
        items: (json['items'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ClienteResumen.fromJson)
            .toList(),
        total: int.tryParse('${json['total']}') ?? 0,
      );
}

class ClienteDetalle extends ClienteResumen {
  final List<ReservaListItem> reservas;

  ClienteDetalle({
    required super.clienteId,
    required super.nombre,
    required super.correo,
    required super.totalReservas,
    required super.completadas,
    required super.canceladas,
    required super.activas,
    super.primeraReserva,
    super.ultimaReserva,
    required super.totalGastado,
    super.servicioFavorito,
    this.reservas = const [],
  });

  factory ClienteDetalle.fromJson(Map<String, dynamic> json) {
    final base = ClienteResumen.fromJson(json);
    return ClienteDetalle(
      clienteId: base.clienteId,
      nombre: base.nombre,
      correo: base.correo,
      totalReservas: base.totalReservas,
      completadas: base.completadas,
      canceladas: base.canceladas,
      activas: base.activas,
      primeraReserva: base.primeraReserva,
      ultimaReserva: base.ultimaReserva,
      totalGastado: base.totalGastado,
      servicioFavorito: base.servicioFavorito,
      reservas: (json['reservas'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ReservaListItem.fromJson)
          .toList(),
    );
  }
}
