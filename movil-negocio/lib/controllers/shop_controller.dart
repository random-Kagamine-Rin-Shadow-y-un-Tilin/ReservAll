import 'package:flutter/material.dart';
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
          _errorMessage = 'Negocio registrado, pero falló la imagen: ${e.toString()}';
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
  Future<bool> getShopById(int shopId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentShop = await _shopService.getShopById(shopId);
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

  // Subir imagen a un negocio existente
  Future<bool> uploadShopImage(File imageFile, int shopId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final imageUrl = await _shopService.uploadImage(imageFile, shopId);
      
      // Actualizar el negocio en la lista
      final index = _myShops.indexWhere((s) => s.id == shopId);
      if (index != -1) {
        _myShops[index] = _myShops[index].copyWith(imagenNegocio: imageUrl);
      }
      
      if (_currentShop?.id == shopId) {
        _currentShop = _currentShop?.copyWith(imagenNegocio: imageUrl);
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

  // Limpiar datos
  void clearShops() {
    _myShops = [];
    _currentShop = null;
    _errorMessage = null;
    notifyListeners();
  }
}