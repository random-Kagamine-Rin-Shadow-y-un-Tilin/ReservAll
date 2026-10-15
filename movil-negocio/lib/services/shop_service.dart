import 'dart:io';
import 'package:dio/dio.dart';
import '../models/shop_model.dart';
import '../models/shop_contact_model.dart';
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

        if (data['general'] != null && data['general'] is Map) {
          return Shop.fromJson(data['general'] as Map<String, dynamic>);
        }

        // Fallback: si viene plano (para compatibilidad)
        if (data['id'] != null) {
          return Shop.fromJson(data);
        }

        throw Exception('No se pudo obtener la información del negocio');
      } else {
        final errorData = response.data as Map<String, dynamic>?;
        throw Exception(errorData?['detail'] ?? 'Error al obtener el negocio');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<ShopFullProfile> getShopFullProfile(int shopId) async {
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
        return ShopFullProfile.fromJson(response.data as Map<String, dynamic>);
      } else {
        final errorData = response.data as Map<String, dynamic>?;
        throw Exception(errorData?['detail'] ?? 'Error al obtener el negocio');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<ShopContact> editContact(int shopId, int contactId, String url) async {
    try {
      final response = await _apiService.put(
        '/shop/edit-contact/$shopId/$contactId',
        body: {'url': url},
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
        return ShopContact.fromJson(response.data as Map<String, dynamic>);
      } else {
        final errorData = response.data as Map<String, dynamic>?;
        throw Exception(errorData?['detail'] ?? 'Error al editar contacto');
      }
    } catch (e) {
      rethrow;
    }
  }

  // HU_12: Eliminar contacto
  Future<void> deleteContact(int shopId, int contactId) async {
    try {
      final response = await _apiService.delete(
        '/shop/delete-contact/$shopId/$contactId',
        requiresAuth: true,
      );

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        final errorData = response.data as Map<String, dynamic>?;
        throw Exception(errorData?['detail'] ?? 'Error al eliminar contacto');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<ShopSchedule> editSchedule(
    int shopId,
    int scheduleId, {
    String? horaApertura,
    String? horaCierre,
    String? horaDescanso,
    bool? estadoHorario,
  }) async {
    final body = <String, dynamic>{};
    if (horaApertura != null) body['hora_apertura'] = horaApertura;
    if (horaCierre != null) body['hora_cierre'] = horaCierre;
    if (horaDescanso != null) body['hora_descanso'] = horaDescanso;
    if (estadoHorario != null) body['estado_horario'] = estadoHorario;

    final response = await _apiService.put(
      '/shop/edit-schedule/$shopId/$scheduleId',
      body: body,
      requiresAuth: true,
    );

    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return ShopSchedule.fromJson(response.data as Map<String, dynamic>);
    } else {
      final errorData = response.data as Map<String, dynamic>?;
      throw Exception(errorData?['detail'] ?? 'Error al editar horario');
    }
  }

  // HU_13: Eliminar horario
  Future<void> deleteSchedule(int shopId, int scheduleId) async {
    try {
      final response = await _apiService.delete(
        '/shop/delete-schedule/$shopId/$scheduleId',
        requiresAuth: true,
      );
      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        final errorData = response.data as Map<String, dynamic>?;
        throw Exception(errorData?['detail'] ?? 'Error al eliminar horario');
      }
    } catch (e) {
      rethrow;
    }
  }

  // HU_14: Eliminar negocio (soft delete)
  Future<void> deleteShop(int shopId) async {
    try {
      final response = await _apiService.delete(
        '/shop/delete-shop/$shopId',
        requiresAuth: true,
      );

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        final errorData = response.data as Map<String, dynamic>?;
        throw Exception(errorData?['detail'] ?? 'Error al eliminar negocio');
      }
    } catch (e) {
      rethrow;
    }
  }

  // HU_15: Activar/desactivar negocio
  Future<Shop> toggleShopStatus(int shopId, bool estado) async {
    try {
      final response = await _apiService.patch(
        '/shop/toggle-status/$shopId',
        body: {'estado_negocio': estado},
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

        // El backend devuelve { message: "...", shop: {...} }
        if (data['shop'] != null && data['shop'] is Map) {
          return Shop.fromJson(data['shop'] as Map<String, dynamic>);
        }

        // Fallback si devuelve el shop directo
        if (data['id'] != null) {
          return Shop.fromJson(data);
        }

        throw Exception('Formato de respuesta inesperado');
      } else {
        final errorData = response.data as Map<String, dynamic>?;
        throw Exception(errorData?['detail'] ?? 'Error al cambiar estado');
      }
    } catch (e) {
      rethrow;
    }
  }

  // HU_12: Editar contacto
Future<ShopContact> editContact(int shopId, int contactId, String url) async {
  try {
    final response = await _apiService.put(
      '/shop/edit-contact/$shopId/$contactId',
      body: {'url': url},
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
      return ShopContact.fromJson(response.data as Map<String, dynamic>);
    } else {
      final errorData = response.data as Map<String, dynamic>?;
      throw Exception(errorData?['detail'] ?? 'Error al editar contacto');
    }
  } catch (e) {
    rethrow;
  }
}

// HU_12: Eliminar contacto
Future<void> deleteContact(int shopId, int contactId) async {
  try {
    final response = await _apiService.delete(
      '/shop/delete-contact/$shopId/$contactId',
      requiresAuth: true,
    );

    if (response.statusCode == null ||
        response.statusCode! < 200 ||
        response.statusCode! >= 300) {
      final errorData = response.data as Map<String, dynamic>?;
      throw Exception(errorData?['detail'] ?? 'Error al eliminar contacto');
    }
  } catch (e) {
    rethrow;
  }
}
}

Future<List<ShopContact>> getContacts(int shopId) async {
  try {
    final response = await _apiService.get(
      '/shop/get-contacts/$shopId',
      requiresAuth: true,
    );
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      final data = response.data;
      if (data is List) {
        return data.map((e) => ShopContact.fromJson(e)).toList();
      }
    }
    return [];
  } catch (e) {
    return [];
  }
}