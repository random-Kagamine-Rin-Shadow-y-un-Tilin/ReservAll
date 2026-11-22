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
    String? search,
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
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };

    final res = await _api.get('/owner/$negocioId/reservations',
        queryParams: query);
    return ReservasListResponse.fromJson(res.data as Map<String, dynamic>);
  }

  /// GET /owner/{negocioId}/reservations/history
  Future<ReservasListResponse> historial({
    required int negocioId,
    EstadoReserva? estado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int? profesionalId,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    final query = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      if (estado != null) 'estado': estado.name,
      if (fechaDesde != null) 'fecha_desde': _d(fechaDesde),
      if (fechaHasta != null) 'fecha_hasta': _d(fechaHasta),
      if (profesionalId != null) 'profesional_id': profesionalId,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };

    final res = await _api.get(
      '/owner/$negocioId/reservations/history',
      queryParams: query,
    );
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

  /// POST /owner/{negocioId}/reservations/{idReserva}/complete
  Future<ReservaListItem> completar(int negocioId, int idReserva) async {
    final res = await _api.post(
      '/owner/$negocioId/reservations/$idReserva/complete',
    );
    return ReservaListItem.fromJson(res.data as Map<String, dynamic>);
  }

  /// PATCH /owner/{negocioId}/reservations/{idReserva}/status
  Future<ReservaListItem> actualizarEstado(
    int negocioId,
    int idReserva,
    EstadoReserva estado, {
    String? motivo,
  }) async {
    final res = await _api.patch(
      '/owner/$negocioId/reservations/$idReserva/status',
      body: {
        'estado': estado.name,
        'motivo': (motivo != null && motivo.trim().isNotEmpty) ? motivo.trim() : null,
      },
    );
    return ReservaListItem.fromJson(res.data as Map<String, dynamic>);
  }

  /// PATCH /owner/{negocioId}/reservations/{idReserva}
  ///
  /// Asigna o quita (con `null`) el profesional de la reserva.
  Future<ReservaListItem> actualizarProfesional(
    int negocioId,
    int idReserva,
    int? profesionalId,
  ) async {
    final res = await _api.patch(
      '/owner/$negocioId/reservations/$idReserva',
      body: {'profesional_id': profesionalId},
    );
    return ReservaListItem.fromJson(res.data as Map<String, dynamic>);
  }

  String _d(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}