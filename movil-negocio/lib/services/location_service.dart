import '../models/location_model.dart';
import 'api_service.dart';

class LocationService {
  final ApiService _apiService = ApiService();

  /// GET /locations/geocode
  Future<List<GeocodeResult>> geocode(
    String query, {
    int limit = 5,
    String? pais,
  }) async {
    final response = await _apiService.get(
      '/locations/geocode',
      queryParams: {
        'q': query.trim(),
        'limit': limit,
        if (pais != null && pais.isNotEmpty) 'pais': pais,
      },
      requiresAuth: true,
    );
    final data = response.data;
    if (data is! List) {
      throw Exception('Formato de respuesta inválido');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(GeocodeResult.fromJson)
        .toList();
  }

  /// GET /locations/reverse
  Future<ReverseGeocodeResult> reverse(
    double lat,
    double lng, {
    int zoom = 18,
  }) async {
    final response = await _apiService.get(
      '/locations/reverse',
      queryParams: {'lat': lat, 'lng': lng, 'zoom': zoom},
      requiresAuth: true,
    );
    return ReverseGeocodeResult.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
