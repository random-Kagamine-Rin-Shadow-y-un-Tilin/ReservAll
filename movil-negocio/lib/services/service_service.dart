import '../models/service_model.dart';
import 'api_service.dart';

class ServiceService {
  final ApiService _apiService = ApiService();

  Future<Service> createService(int shopId, ServiceCreateRequest request) async {
    final response = await _apiService.post(
      '/service/register/$shopId',
      body: request.toJson(),
      requiresAuth: true,
    );

    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      return Service.fromJson(response.data as Map<String, dynamic>);
    } else {
      final errorData = response.data as Map<String, dynamic>?;
      throw Exception(errorData?['detail'] ?? 'Error al crear servicio');
    }
  }

  Future<List<Service>> getServices(int shopId) async {
    final response = await _apiService.get(
      '/service/list/$shopId',
      requiresAuth: true,
    );

    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      final data = response.data as List;
      return data.map((e) => Service.fromJson(e)).toList();
    } else {
      return [];
    }
  }

  Future<Service> editService(int shopId, int serviceId, ServiceEditRequest request) async {
    final response = await _apiService.put(
      '/service/edit/$shopId/$serviceId',
      body: request.toJson(),
      requiresAuth: true,
    );

    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      return Service.fromJson(response.data as Map<String, dynamic>);
    } else {
      final errorData = response.data as Map<String, dynamic>?;
      throw Exception(errorData?['detail'] ?? 'Error al editar servicio');
    }
  }


  Future<void> deleteService(int shopId, int serviceId) async {
    final response = await _apiService.delete(
      '/service/delete/$shopId/$serviceId',
      requiresAuth: true,
    );

    if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
      final errorData = response.data as Map<String, dynamic>?;
      throw Exception(errorData?['detail'] ?? 'Error al eliminar servicio');
    }
  }
}