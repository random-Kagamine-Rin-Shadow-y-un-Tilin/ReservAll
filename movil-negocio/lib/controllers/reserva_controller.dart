import 'package:flutter/foundation.dart';
import '../models/reserva_model.dart';
import '../services/reserva_service.dart';

class ReservaController extends ChangeNotifier {
  final ReservaService _service;
  ReservaController(this._service);

  // ---- Listado ----
  List<ReservaListItem> _items = [];
  List<ReservaListItem> get items => _items;

  int _total = 0;
  int get total => _total;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  EstadoReserva? _filtroEstado;
  EstadoReserva? get filtroEstado => _filtroEstado;

  DateTime? _filtroFecha;
  DateTime? get filtroFecha => _filtroFecha;

  int _page = 0;
  static const _pageSize = 20;
  bool get hasMore => _items.length < _total;

  // ---- Detalle ----
  ReservaDetalle? _detalle;
  ReservaDetalle? get detalle => _detalle;

  // ---- Acción en curso (para deshabilitar botones) ----
  int? _accionEnCursoId;
  int? get accionEnCursoId => _accionEnCursoId;

  // ================= LISTADO =================
  Future<void> cargar({required int negocioId, bool reset = true}) async {
    if (reset) {
      _page = 0;
      _items = [];
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _service.listarPorNegocio(
        negocioId: negocioId,
        estado: _filtroEstado,
        fecha: _filtroFecha,
        limit: _pageSize,
        offset: _page * _pageSize,
      );
      _total = res.total;
      _items = reset ? res.items : [..._items, ...res.items];
    } catch (e) {
      _errorMessage = _msg(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarMas(int negocioId) async {
    if (_isLoading || !hasMore) return;
    _page += 1;
    await cargar(negocioId: negocioId, reset: false);
  }

  void setFiltroEstado(EstadoReserva? e) {
    _filtroEstado = e;
    notifyListeners();
  }

  void setFiltroFecha(DateTime? f) {
    _filtroFecha = f;
    notifyListeners();
  }

  // ================= DETALLE =================
  Future<void> cargarDetalle(int idReserva) async {
    _isLoading = true;
    _errorMessage = null;
    _detalle = null;
    notifyListeners();
    try {
      _detalle = await _service.detalle(idReserva);
    } catch (e) {
      _errorMessage = _msg(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ================= CONFIRMAR =================
  Future<bool> confirmar(int negocioId, int idReserva) async {
    _accionEnCursoId = idReserva;
    _errorMessage = null;
    notifyListeners();

    // Optimistic UI
    final idx = _items.indexWhere((r) => r.idReserva == idReserva);
    final previo = idx >= 0 ? _items[idx] : null;
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(estado: EstadoReserva.confirmada);
      notifyListeners();
    }

    try {
      await _service.confirmar(idReserva);
      // Refresco silencioso para traer datos del backend
      await cargar(negocioId: negocioId, reset: true);
      return true;
    } catch (e) {
      // Rollback
      if (idx >= 0 && previo != null) {
        _items[idx] = previo;
      }
      _errorMessage = _msg(e);
      notifyListeners();
      return false;
    } finally {
      _accionEnCursoId = null;
      notifyListeners();
    }
  }

  // ================= RECHAZAR =================
  Future<bool> rechazar(int negocioId, int idReserva, String motivo) async {
    _accionEnCursoId = idReserva;
    _errorMessage = null;
    notifyListeners();

    final idx = _items.indexWhere((r) => r.idReserva == idReserva);
    final previo = idx >= 0 ? _items[idx] : null;
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(estado: EstadoReserva.cancelada);
      notifyListeners();
    }

    try {
      await _service.rechazar(idReserva, motivo);
      await cargar(negocioId: negocioId, reset: true);
      return true;
    } catch (e) {
      if (idx >= 0 && previo != null) {
        _items[idx] = previo;
      }
      _errorMessage = _msg(e);
      notifyListeners();
      return false;
    } finally {
      _accionEnCursoId = null;
      notifyListeners();
    }
  }

  String _msg(Object e) => e.toString();
}