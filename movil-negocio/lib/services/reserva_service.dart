import '../models/reserva_model.dart';
import 'api_service.dart';

class ReservaService {
  final ApiService _api;
  ReservaService(this._api);

  /// GET /reservations/negocio/{negocioId}
  Future<ReservasListResponse> listarPorNegocio({
    required int negocioId,
    EstadoReserva? estado,
    DateTime? fecha,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int? profesionalId,
    int limit = 20,
    int offset = 0,
  }) async {
    final query = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      if (estado != null) 'estado': estado.name,
      if (fecha != null) 'fecha': _d(fecha),
      if (fechaDesde != null) 'fecha_desde': _d(fechaDesde),
      if (fechaHasta != null) 'fecha_hasta': _d(fechaHasta),
      if (profesionalId != null) 'profesional_id': profesionalId,
    };

    // AJUSTA: si tu ApiService devuelve Response de Dio
    final res = await _api.get('/reservations/negocio/$negocioId',
        queryParameters: query);
    // AJUSTA: si devuelve wrapper -> res.data['data']
    return ReservasListResponse.fromJson(res.data as Map<String, dynamic>);
  }

  /// GET /reservations/{id}
  Future<ReservaDetalle> detalle(int idReserva) async {
    final res = await _api.get('/reservations/$idReserva');
    return ReservaDetalle.fromJson(res.data as Map<String, dynamic>);
  }

  /// PATCH /reservations/{id}/confirm
  Future<void> confirmar(int idReserva) async {
    await _api.patch('/reservations/$idReserva/confirm');
  }

  /// PATCH /reservations/{id}/reject
  Future<void> rechazar(int idReserva, String motivo) async {
    await _api.patch(
      '/reservations/$idReserva/reject',
      data: {'motivo': motivo},
    );
  }

  String _d(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}