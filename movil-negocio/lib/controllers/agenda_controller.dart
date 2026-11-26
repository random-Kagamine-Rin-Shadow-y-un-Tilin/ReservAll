import 'package:flutter/foundation.dart';

import '../models/agenda_model.dart';
import '../services/agenda_service.dart';

class AgendaController extends ChangeNotifier {
  final AgendaService _service;
  AgendaController(this._service);

  AgendaResponse? _agenda;
  AgendaResponse? get agenda => _agenda;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _accionEnCurso = false;
  bool get accionEnCurso => _accionEnCurso;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int? _shopId;
  DateTime _desde = DateTime.now();
  DateTime _hasta = DateTime.now().add(const Duration(days: 6));
  int? _profesionalId;

  DateTime get desde => _desde;
  DateTime get hasta => _hasta;
  int? get profesionalId => _profesionalId;

  Future<void> cargar(
    int shopId, {
    DateTime? desde,
    DateTime? hasta,
    int? servicioId,
    int? profesionalId,
    bool resetProfesional = false,
  }) async {
    _shopId = shopId;
    if (desde != null) _desde = desde;
    if (hasta != null) _hasta = hasta;
    if (resetProfesional) {
      _profesionalId = profesionalId;
    } else if (profesionalId != null) {
      _profesionalId = profesionalId;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _agenda = await _service.getAgenda(
        shopId,
        fechaDesde: _desde,
        fechaHasta: _hasta,
        servicioId: servicioId,
        profesionalId: _profesionalId,
        intervaloMinutos: 30,
        descansoMinutos: 0,
      );
    } catch (e) {
      _errorMessage = _msg(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> recargar() async {
    final id = _shopId;
    if (id == null) return false;
    await cargar(id);
    return _errorMessage == null;
  }

  Future<bool> crearBloqueo(
    int shopId, {
    required DateTime fecha,
    String? horaInicio,
    String? horaFin,
    String? motivo,
  }) async {
    _accionEnCurso = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.createBlock(
        shopId,
        fecha: fecha,
        horaInicio: horaInicio,
        horaFin: horaFin,
        motivo: motivo,
      );
      await recargar();
      return true;
    } catch (e) {
      _errorMessage = _msg(e);
      return false;
    } finally {
      _accionEnCurso = false;
      notifyListeners();
    }
  }

  Future<bool> eliminarBloqueo(int shopId, int blockId) async {
    _accionEnCurso = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.deleteBlock(shopId, blockId);
      await recargar();
      return true;
    } catch (e) {
      _errorMessage = _msg(e);
      return false;
    } finally {
      _accionEnCurso = false;
      notifyListeners();
    }
  }

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');
}
