import 'package:flutter/material.dart';
import '../models/auth_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthController() {
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _user = await _storageService.getUser();
      if (_user != null) {
        // Verificar si la sesión sigue activa
        final hasSession = await _authService.hasActiveSession();
        if (!hasSession) {
          _user = null;
          await _storageService.clearUser();
        }
      }
    } catch (e) {
      _errorMessage = 'Error al cargar usuario';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Registro
  Future<bool> register({
    required String nombre,
    required String correo,
    required String password,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final registerRequest = RegisterRequest(
        nombre: nombre.trim(),
        correo: correo.trim(),
        password: password,
        confirmPassword: confirmPassword,
        rol: 'dueno_negocio',
      );

      final user = await _authService.register(registerRequest);
      _user = user;
      await _storageService.saveUser(user);
      
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

  // Login - Las cookies se guardan automáticamente
  Future<bool> login(String correo, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loginRequest = LoginRequest(
        correo: correo.trim(),
        password: password,
      );

      final user = await _authService.login(loginRequest);
      _user = user;
      await _storageService.saveUser(user);
      
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

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
    } catch (e) {
      // Ignorar errores
    } finally {
      _user = null;
      await _storageService.clearUser();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refrescar usuario
  Future<bool> refreshUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _user = user;
        await _storageService.saveUser(user);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}