import 'dart:io';
import 'package:dio/dio.dart';
import '../models/shop_model.dart';
import 'api_service.dart';

class ShopService {
  final ApiService _apiService = ApiService();

  // Registrar un nuevo negocio
  Future<Shop> registerShop(RegisterShopRequest request) async {
    try {
      final response = await _apiService.post(
        '/shop/register-shop',
        body: request.toJson(),
        requiresAuth: true,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        if (response.data == null) {
          throw Exception('Respuesta vacía del servidor');
        }

        if (response.data is! Map<String, dynamic>) {
          throw Exception('Formato de respuesta inválido');
        }

        final data = response.data as Map<String, dynamic>;

        if (data['success'] == true && data['data'] != null) {
          return Shop.fromJson(data['data']);
        } else if (data['id'] != null) {
          return Shop.fromJson(data);
        } else {
          throw Exception(data['message'] ?? 'Error al registrar el negocio');
        }
      } else {
        final errorData = response.data as Map<String, dynamic>?;
        final message =
            errorData?['detail'] ??
            errorData?['message'] ??
            'Error al registrar el negocio';
        throw Exception(message);
      }
    } catch (e) {
      rethrow;
    }
  }

  //  SUBIR IMAGEN
  Future<String> uploadImage(File imageFile, int shopId) async {
    try {
      // Crear FormData con el archivo
      final formData = FormData.fromMap({
        'shop_id': shopId.toString(),
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
          contentType: DioMediaType('image', 'jpeg'),
        ),
      });

      final response = await _apiService.post(
        '/shop/upload-image',
        body: formData,
        requiresAuth: true,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        if (response.data == null) {
          throw Exception('Respuesta vacía del servidor');
        }

        if (response.data is! Map<String, dynamic>) {
          throw Exception('Formato de respuesta inválido');
        }

        final data = response.data as Map<String, dynamic>;

        // Buscar la URL de la imagen en diferentes formatos de respuesta
        final imageUrl =
            data['data']?['image_url'] ??
            data['data']?['url'] ??
            data['image_url'] ??
            data['url'] ??
            '';

        if (imageUrl.isEmpty) {
          throw Exception('No se pudo obtener la URL de la imagen');
        }

        return imageUrl;
      } else {
        final errorData = response.data as Map<String, dynamic>?;
        throw Exception(errorData?['detail'] ?? 'Error al subir la imagen');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Obtener mis negocios
  Future<List<Shop>> getMyShops() async {
    try {
      final response = await _apiService.get(
        '/shop/my-shops',
        requiresAuth: true,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        if (response.data == null) {
          return [];
        }

        List<dynamic> shopsData = [];
        final data = response.data;

        if (data is Map<String, dynamic>) {
          if (data['success'] == true && data['data'] != null) {
            if (data['data'] is List) {
              shopsData = data['data'] as List<dynamic>;
            }
          } else if (data['shops'] != null && data['shops'] is List) {
            shopsData = data['shops'] as List<dynamic>;
          } else if (data['data'] is Map) {
            // Algunos backends devuelven { data: { shops: [...] } }
            final innerData = data['data'] as Map<String, dynamic>;
            if (innerData['shops'] != null && innerData['shops'] is List) {
              shopsData = innerData['shops'] as List<dynamic>;
            }
          }
        } else if (data is List<dynamic>) {
          shopsData = data;
        }

        return shopsData.map((json) => Shop.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener los negocios');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Obtener negocio por ID
  Future<Shop> getShopById(int shopId) async {
    try {
      final response = await _apiService.get(
        '/shop/get-shop/$shopId',
        requiresAuth: true,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        if (response.data == null) {
          throw Exception('Respuesta vacía del servidor');
        }

        if (response.data is! Map<String, dynamic>) {
          throw Exception('Formato de respuesta inválido');
        }

        final data = response.data as Map<String, dynamic>;

        if (data['success'] == true && data['data'] != null) {
          return Shop.fromJson(data['data']);
        } else if (data['id'] != null) {
          return Shop.fromJson(data);
        } else {
          throw Exception('No se pudo obtener la información del negocio');
        }
      } else {
        throw Exception('Error al obtener el negocio');
      }
    } catch (e) {
      rethrow;
    }
  }
}
