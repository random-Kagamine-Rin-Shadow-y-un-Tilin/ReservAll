import 'package:flutter/material.dart';
import '../models/profesional_model.dart';
import '../services/profesional_service.dart';

class ProfesionalController extends ChangeNotifier {
  final ProfesionalService _service = ProfesionalService();

  List<Professional> _professionals = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Professional> get professionals => _professionals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfessionals(int shopId) async {
  // Diferimos el cambio de estado para que no choque con el build
  await Future.microtask(() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  });

  try {
    _professionals = await _service.getProfessionals(shopId);
  } catch (e) {
    _errorMessage = e.toString().replaceFirst('Exception: ', '');
  } finally {
    await Future.microtask(() {
      _isLoading = false;
      notifyListeners();
    });
  }
}

  Future<bool> createProfessional(
    int shopId,
    ProfessionalCreateRequest request,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final newProf = await _service.createProfessional(shopId, request);
      _professionals.add(newProf);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProfessional(int shopId, int professionalId) async {
    try {
      await _service.deleteProfessional(shopId, professionalId);
      _professionals.removeWhere((p) => p.idProfesional == professionalId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
