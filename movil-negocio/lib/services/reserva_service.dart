import '../models/reserva_model.dart';
import 'api_service.dart';

class ReservaService {
  final ApiService _api;
  ReservaService(this._api);

  /// GET /owner/{negocioId}/reservations
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
      ...(fecha != null
          ? {'fecha_desde': _d(fecha), 'fecha_hasta': _d(fecha)}
          : <String, String>{}),
      if (fechaDesde != null) 'fecha_desde': _d(fechaDesde),
      if (fechaHasta != null) 'fecha_hasta': _d(fechaHasta),
      if (profesionalId != null) 'profesional_id': profesionalId,
    };

    final res = await _api.get('/owner/$negocioId/reservations',
        queryParams: query);
    return ReservasListResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<ProfesionalItem>> listarProfesionales(int negocioId) async {
    final res = await _api.get('/professional/list/$negocioId');
    final data = res.data;
    final list = (data is Map && data['data'] is List)
        ? data['data'] as List
        : (data is List ? data : []);
    return list
        .map((e) => ProfesionalItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /owner/{negocioId}/reservations/{idReserva}
  Future<ReservaDetalle> detalle(int negocioId, int idReserva) async {
    final res = await _api.get('/owner/$negocioId/reservations/$idReserva');
    return ReservaDetalle.fromJson(res.data as Map<String, dynamic>);
  }

  /// POST /owner/{negocioId}/reservations/{idReserva}/confirm
  Future<void> confirmar(int negocioId, int idReserva) async {
    await _api.post('/owner/$negocioId/reservations/$idReserva/confirm');
  }

  /// POST /owner/{negocioId}/reservations/{idReserva}/reject
  Future<void> rechazar(int negocioId, int idReserva, String motivo) async {
    await _api.post(
      '/owner/$negocioId/reservations/$idReserva/reject',
      body: {'motivo': motivo},
    );
  }

  String _d(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}