import '../models/profesional_model.dart';
import 'api_service.dart';

class ProfesionalService {
  final ApiService _apiService = ApiService();

  Future<Professional> createProfessional(int shopId, ProfessionalCreateRequest request) async {
    final response = await _apiService.post(
      '/professional/register/$shopId',
      body: request.toJson(),
      requiresAuth: true,
    );

    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      return Professional.fromJson(response.data as Map<String, dynamic>);
    } else {
      final errorData = response.data as Map<String, dynamic>?;
      throw Exception(errorData?['detail'] ?? 'Error al crear profesional');
    }
  }

  Future<List<Professional>> getProfessionals(int shopId) async {
    final response = await _apiService.get(
      '/professional/list/$shopId',
      requiresAuth: true,
    );

    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      final data = response.data as List;
      return data.map((e) => Professional.fromJson(e)).toList();
    } else {
      return [];
    }
  }

  Future<void> deleteProfessional(int shopId, int professionalId) async {
    final response = await _apiService.delete(
      '/professional/delete/$shopId/$professionalId',
      requiresAuth: true,
    );

    if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
      final errorData = response.data as Map<String, dynamic>?;
      throw Exception(errorData?['detail'] ?? 'Error al eliminar profesional');
    }
  }
}