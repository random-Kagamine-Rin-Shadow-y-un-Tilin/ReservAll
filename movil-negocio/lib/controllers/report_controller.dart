import 'package:flutter/foundation.dart';

import '../models/report_model.dart';
import '../services/report_service.dart';

class ReportController extends ChangeNotifier {
  final ReportService _service;
  ReportController(this._service);

  Report? _report;
  Report? get report => _report;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  DateTime _desde = DateTime.now().subtract(const Duration(days: 29));
  DateTime _hasta = DateTime.now();

  DateTime get desde => _desde;
  DateTime get hasta => _hasta;

  Future<void> cargar(
    int shopId, {
    DateTime? desde,
    DateTime? hasta,
  }) async {
    if (desde != null) _desde = desde;
    if (hasta != null) _hasta = hasta;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _report = await _service.getReport(
        shopId,
        desde: _desde,
        hasta: _hasta,
      );
    } catch (e) {
      _errorMessage = _msg(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');
}
