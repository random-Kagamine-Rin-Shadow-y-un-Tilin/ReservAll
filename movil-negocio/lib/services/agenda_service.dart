import '../models/agenda_model.dart';
import 'api_service.dart';

class AgendaService {
  final ApiService _apiService = ApiService();

  /// GET /owner/{shopId}/agenda
  Future<AgendaResponse> getAgenda(
    int shopId, {
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int? servicioId,
    int? profesionalId,
    int? intervaloMinutos,
    int? descansoMinutos,
  }) async {
    final query = <String, dynamic>{
      if (fechaDesde != null) 'fecha_desde': _d(fechaDesde),
      if (fechaHasta != null) 'fecha_hasta': _d(fechaHasta),
      if (servicioId != null) 'servicio_id': servicioId,
      if (profesionalId != null) 'profesional_id': profesionalId,
      if (intervaloMinutos != null) 'intervalo_minutos': intervaloMinutos,
      if (descansoMinutos != null) 'descanso_minutos': descansoMinutos,
    };

    final response = await _apiService.get(
      '/owner/$shopId/agenda',
      queryParams: query,
      requiresAuth: true,
    );
    return AgendaResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /owner/{shopId}/blocks
  Future<BlockListResponse> getBlocks(
    int shopId, {
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    final response = await _apiService.get(
      '/owner/$shopId/blocks',
      queryParams: {
        if (fechaDesde != null) 'fecha_desde': _d(fechaDesde),
        if (fechaHasta != null) 'fecha_hasta': _d(fechaHasta),
      },
      requiresAuth: true,
    );
    return BlockListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /owner/{shopId}/blocks
  ///
  /// Sin horas bloquea el día completo; con ambas bloquea solo ese rango.
  Future<AgendaBlock> createBlock(
    int shopId, {
    required DateTime fecha,
    String? horaInicio,
    String? horaFin,
    String? motivo,
  }) async {
    final response = await _apiService.post(
      '/owner/$shopId/blocks',
      body: {
        'fecha': _d(fecha),
        'hora_inicio': horaInicio,
        'hora_fin': horaFin,
        'motivo': (motivo != null && motivo.trim().isNotEmpty)
            ? motivo.trim()
            : null,
      },
      requiresAuth: true,
    );
    return AgendaBlock.fromJson(response.data as Map<String, dynamic>);
  }

  /// DELETE /owner/{shopId}/blocks/{blockId}
  Future<void> deleteBlock(int shopId, int blockId) async {
    await _apiService.delete(
      '/owner/$shopId/blocks/$blockId',
      requiresAuth: true,
    );
  }

  String _d(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
