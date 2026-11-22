import '../models/report_model.dart';
import 'api_service.dart';

class ReportService {
  final ApiService _apiService = ApiService();

  /// GET /owner/{shopId}/reports/summary
  Future<Report> getReport(
    int shopId, {
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final response = await _apiService.get(
      '/owner/$shopId/reports/summary',
      queryParams: {
        'fecha_desde': _d(desde),
        'fecha_hasta': _d(hasta),
      },
      requiresAuth: true,
    );
    return Report.fromJson(response.data as Map<String, dynamic>);
  }

  String _d(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
