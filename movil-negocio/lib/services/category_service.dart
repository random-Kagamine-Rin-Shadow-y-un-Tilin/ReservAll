import '../models/category_model.dart';
import 'api_service.dart';

/// HU_14: catálogo público y administración de categorías.
class CategoryService {
  final ApiService _apiService;

  CategoryService([ApiService? apiService])
    : _apiService = apiService ?? ApiService();

  List<Category> _parseList(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Category.fromJson)
        .toList();
  }

  /// Catálogo active-only para el registro/edición de negocios.
  /// El router `/client` valida la x-api-key, ya configurada en ApiService.
  Future<List<Category>> listPublicCategories() async {
    final response = await _apiService.get(
      '/client/categories',
      requiresAuth: false,
    );
    return _parseList(response.data);
  }

  /// Listado de administración: requiere rol `admin` en el token.
  Future<List<Category>> listCategories({bool incluirInactivas = false}) async {
    final response = await _apiService.get(
      '/categories',
      queryParams: {'incluir_inactivas': incluirInactivas},
      requiresAuth: true,
    );
    return _parseList(response.data);
  }

  Future<Category> getCategory(int id) async {
    final response = await _apiService.get(
      '/categories/$id',
      requiresAuth: true,
    );
    return Category.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Category> createCategory(CategoryInput input) async {
    final response = await _apiService.post(
      '/categories',
      body: input.toJson(),
      requiresAuth: true,
    );
    return Category.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Category> updateCategory(int id, CategoryInput input) async {
    final response = await _apiService.put(
      '/categories/$id',
      body: input.toJson(),
      requiresAuth: true,
    );
    return Category.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCategory(int id) async {
    await _apiService.delete('/categories/$id', requiresAuth: true);
  }
}
