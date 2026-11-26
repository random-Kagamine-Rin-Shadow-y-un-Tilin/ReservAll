import 'package:flutter/foundation.dart';

import '../models/location_model.dart';
import '../services/location_service.dart';

class LocationController extends ChangeNotifier {
  final LocationService _service;
  LocationController(this._service);

  List<GeocodeResult> _results = [];
  List<GeocodeResult> get results => _results;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> buscar(String query, {String? pais}) async {
    final q = query.trim();
    if (q.length < 3) {
      _results = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _results = await _service.geocode(q, pais: pais);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _results = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ReverseGeocodeResult?> reverse(double lat, double lng) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await _service.reverse(lat, lng);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void limpiar() {
    _results = [];
    _errorMessage = null;
    notifyListeners();
  }
}
