import 'package:flutter/foundation.dart';

import '../models/client_model.dart';
import '../services/client_service.dart';

class ClientController extends ChangeNotifier {
  final ClientService _service;
  ClientController(this._service);

  List<ClienteResumen> _items = [];
  List<ClienteResumen> get items => _items;

  int _total = 0;
  int get total => _total;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _search = '';
  String get search => _search;

  ClienteDetalle? _detalle;
  ClienteDetalle? get detalle => _detalle;

  bool _isLoadingDetalle = false;
  bool get isLoadingDetalle => _isLoadingDetalle;

  Future<void> cargar(int shopId, {String? search}) async {
    if (search != null) _search = search;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _service.getClients(shopId, search: _search);
      _items = res.items;
      _total = res.total;
    } catch (e) {
      _errorMessage = _msg(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarDetalle(int shopId, int clientId) async {
    _isLoadingDetalle = true;
    _errorMessage = null;
    _detalle = null;
    notifyListeners();

    try {
      _detalle = await _service.getClient(shopId, clientId);
    } catch (e) {
      _errorMessage = _msg(e);
    } finally {
      _isLoadingDetalle = false;
      notifyListeners();
    }
  }

  void limpiarBusqueda() {
    if (_search.isEmpty) return;
    _search = '';
    notifyListeners();
  }

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');
}
