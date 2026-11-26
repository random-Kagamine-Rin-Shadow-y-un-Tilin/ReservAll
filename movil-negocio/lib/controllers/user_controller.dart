import 'package:flutter/material.dart';
import '../models/auth_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class UserController extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // Obtener el perfil del usuario actual
  Future<bool> getUserProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/profile/me', requiresAuth: true);

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

        if (data['id'] != null) {
          _currentUser = User.fromJson(data);
        } else if (data['success'] == true && data['data'] != null) {
          _currentUser = User.fromJson(data['data']);
        } else {
          throw Exception('No se pudo obtener el perfil del usuario');
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('Error al obtener el perfil');
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // HU_05: actualizar perfil propio (antes se llamaba a /profile/update,
  // una ruta que el backend ya no expone).
  Future<bool> updateUserProfile(ProfileUpdateRequest userData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.patch(
        '/profile/me',
        body: userData.toJson(),
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

        if (data['id'] != null) {
          _currentUser = User.fromJson(data);
        } else if (data['success'] == true && data['data'] != null) {
          _currentUser = User.fromJson(data['data']);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('Error al actualizar el perfil');
      }
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

  // Limpiar usuario
  void clearUser() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }
}
