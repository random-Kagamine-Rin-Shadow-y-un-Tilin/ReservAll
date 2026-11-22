import '../models/client_model.dart';
import 'api_service.dart';

class ClientService {
  final ApiService _apiService = ApiService();

  /// GET /owner/{shopId}/clients
  Future<ClientesListResponse> getClients(int shopId, {String? search}) async {
    final response = await _apiService.get(
      '/owner/$shopId/clients',
      queryParams: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
      requiresAuth: true,
    );
    return ClientesListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /owner/{shopId}/clients/{clientId}
  Future<ClienteDetalle> getClient(int shopId, int clientId) async {
    final response = await _apiService.get(
      '/owner/$shopId/clients/$clientId',
      requiresAuth: true,
    );
    return ClienteDetalle.fromJson(response.data as Map<String, dynamic>);
  }
}
