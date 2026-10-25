import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../services/service_service.dart';

class ServiceController extends ChangeNotifier {
  final ServiceService _service = ServiceService();

  List<Service> _services = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Service> get services => _services;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadServices(int shopId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _services = await _service.getServices(shopId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createService(int shopId, ServiceCreateRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final newService = await _service.createService(shopId, request);
      _services.add(newService);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> editService(int shopId, int serviceId, ServiceEditRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updated = await _service.editService(shopId, serviceId, request);
      final index = _services.indexWhere((s) => s.idServicio == serviceId);
      if (index != -1) {
        _services[index] = updated;
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteService(int shopId, int serviceId) async {
    try {
      await _service.deleteService(shopId, serviceId);
      _services.removeWhere((s) => s.idServicio == serviceId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}