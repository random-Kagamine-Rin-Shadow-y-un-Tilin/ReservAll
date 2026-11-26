import 'package:flutter/material.dart';
import '../models/address_model.dart';
import '../models/shop_model.dart';
import '../services/shop_service.dart';
import 'dart:io';

class ShopController extends ChangeNotifier {
  final ShopService _shopService = ShopService();

  List<Shop> _myShops = [];
  Shop? _currentShop;
  bool _isLoading = false;
  String? _errorMessage;

  List<Shop> get myShops => _myShops;
  Shop? get currentShop => _currentShop;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Registrar negocio
  Future<bool> registerShop({
    required String nombre,
    required String descripcion,
    required int categoriaNegocio,
    File? imageFile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Registrar el negocio
      final request = RegisterShopRequest(
        nombre: nombre.trim(),
        descripcion: descripcion.trim(),
        imagenNegocio: null,
        categoriaNegocio: categoriaNegocio,
      );

      final shop = await _shopService.registerShop(request);
      _currentShop = shop;

      // 2. Si hay imagen, subirla
      if (imageFile != null && shop.id != null) {
        try {
          final imageUrl = await _shopService.uploadImage(imageFile, shop.id!);
          _currentShop = shop.copyWith(imagenNegocio: imageUrl);

          // Actualizar en la lista si existe
          final index = _myShops.indexWhere((s) => s.id == shop.id);
          if (index != -1) {
            _myShops[index] = _myShops[index].copyWith(imagenNegocio: imageUrl);
          }
        } catch (e) {
          // Si falla la imagen, no fallar todo
          _errorMessage =
              'Negocio registrado, pero falló la imagen: ${e.toString()}';
        }
      }

      // 3. Actualizar lista de negocios
      await getMyShops();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // HU_11: Editar negocio
  Future<bool> editShop(int shopId, ShopEditRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updated = await _shopService.editShop(shopId, request);

      // Actualizar el negocio en la lista
      final idx = _myShops.indexWhere((s) => s.id == shopId);
      if (idx != -1) _myShops[idx] = updated;

      // Actualizar el actual
      if (_currentShop?.id == shopId) {
        _currentShop = updated;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // HU_08: Registrar contacto
  Future<bool> addContact(int shopId, ShopContactCreateRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _shopService.addContact(shopId, request);
      // Recargar el perfil completo para que aparezca la nueva red
      if (_currentShop?.id == shopId) {
        await getShopById(shopId);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Editar contacto
  Future<bool> editContact(int shopId, int contactId, String url) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _shopService.editContact(shopId, contactId, url);
      if (_currentShop?.id == shopId) {
        await getShopById(shopId);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // HU_12: Eliminar contacto
  Future<bool> deleteContact(int shopId, int contactId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _shopService.deleteContact(shopId, contactId);
      // Recargar el perfil completo para que la lista se actualice
      if (_currentShop?.id == shopId) {
        await getShopById(shopId);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Obtener mis negocios
  Future<bool> getMyShops() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myShops = await _shopService.getMyShops();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Obtener negocio por ID
  ShopFullProfile? _fullProfile;

  ShopFullProfile? get fullProfile => _fullProfile;

  ShopAddress? _address;
  ShopAddress? get address => _address;

  Set<int>? _publicShopIds;

  /// IDs de negocios visibles públicamente. `null` si no se pudo consultar.
  Set<int>? get publicShopIds => _publicShopIds;

  Future<bool> getShopById(int shopId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _fullProfile = await _shopService.getShopFullProfile(shopId);
      _currentShop = _fullProfile!.general;
      _address = _fullProfile!.direccion;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // recargar el negocio actual si ya se tiene cargado
  Future<void> reloadCurrentShop() async {
    if (_currentShop?.id != null) {
      await getShopById(_currentShop!.id!);
    }
  }

  // Subir imagen a un negocio existente
  Future<String?> uploadShopImage(File imageFile, int shopId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final url = await _shopService.uploadImage(imageFile, shopId);
      _isLoading = false;
      notifyListeners();
      return url;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> editSchedule(
    int shopId,
    int scheduleId, {
    String? horaApertura,
    String? horaCierre,
    String? horaDescanso,
    int? descansoDuracionMin,
    bool? estadoHorario,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _shopService.editSchedule(
        shopId,
        scheduleId,
        horaApertura: horaApertura,
        horaCierre: horaCierre,
        horaDescanso: horaDescanso,
        descansoDuracionMin: descansoDuracionMin,
        estadoHorario: estadoHorario,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // HU_13: Eliminar horario
  Future<bool> deleteSchedule(int shopId, int scheduleId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _shopService.deleteSchedule(shopId, scheduleId);
      if (_currentShop?.id == shopId) {
        await getShopById(shopId);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // HU_14: Eliminar negocio (soft delete)
  Future<bool> deleteShop(int shopId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _shopService.deleteShop(shopId);
      _myShops.removeWhere((s) => s.id == shopId);
      if (_currentShop?.id == shopId) {
        _currentShop = null;
        _fullProfile = null;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // HU_15: Activar/desactivar negocio
  Future<bool> toggleShopStatus(int shopId, bool estado) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updated = await _shopService.toggleShopStatus(shopId, estado);
      // Actualizar en la lista
      final idx = _myShops.indexWhere((s) => s.id == shopId);
      if (idx != -1) _myShops[idx] = updated;
      // Actualizar el actual
      if (_currentShop?.id == shopId) {
        _currentShop = updated;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Limpiar error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ==================== HORARIOS ====================

  /// POST /shop/register-schedule/{shopId}
  Future<bool> registerSchedule(
    int shopId, {
    required String dia,
    required String horaApertura,
    required String horaCierre,
    String? horaDescanso,
    int descansoDuracionMin = 60,
    bool estadoHorario = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _shopService.registerSchedule(
        shopId,
        dia: dia,
        horaApertura: horaApertura,
        horaCierre: horaCierre,
        horaDescanso: horaDescanso,
        descansoDuracionMin: descansoDuracionMin,
        estadoHorario: estadoHorario,
      );
      if (_currentShop?.id == shopId) {
        await getShopById(shopId);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== DIRECCIÓN ====================

  /// GET /shop/get-address/{shopId}
  Future<bool> loadAddress(int shopId) async {
    _errorMessage = null;
    try {
      _address = await _shopService.getAddress(shopId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// POST /shop/register-address/{shopId}
  Future<bool> registerAddress(
    int shopId,
    ShopAddressCreateRequest request,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _address = await _shopService.registerAddress(shopId, request);
      if (_currentShop?.id == shopId) {
        await getShopById(shopId);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// PUT /shop/edit-address/{shopId}
  Future<bool> editAddress(int shopId, ShopAddressUpdateRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _address = await _shopService.editAddress(shopId, request);
      if (_currentShop?.id == shopId) {
        await getShopById(shopId);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== VISIBILIDAD ====================

  /// GET /client/list-shops
  Future<void> loadPublicShopIds() async {
    try {
      final ids = await _shopService.getPublicShopIds();
      _publicShopIds = ids.toSet();
    } catch (_) {
      _publicShopIds = null;
    }
    notifyListeners();
  }

  bool? isShopPublic(int shopId) {
    final ids = _publicShopIds;
    if (ids == null) return null;
    return ids.contains(shopId);
  }

  // Limpiar datos
  void clearShops() {
    _myShops = [];
    _currentShop = null;
    _errorMessage = null;
    notifyListeners();
  }
}
