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

  // ---- Filtros ----

 EstadoReserva? _filtroEstado;
  EstadoReserva? get filtroEstado => _filtroEstado;

  DateTime? _filtroFecha;
  DateTime? get filtroFecha => _filtroFecha;

  int? _filtroProfesionalId;
  int? get filtroProfesionalId => _filtroProfesionalId;

  String? _filtroSearch;
  String? get filtroSearch => _filtroSearch;

  bool _historial = false;
  bool get historial => _historial;

  bool get hayFiltrosActivos =>
      _filtroEstado != null ||
      _filtroFecha != null ||
      _filtroProfesionalId != null ||
      (_filtroSearch != null && _filtroSearch!.isNotEmpty);

  // ---- Profesionales del negocio ----
  final List<ProfesionalItem> _profesionales = [];
  List<ProfesionalItem> get profesionales => _profesionales;

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
      final res = _historial
          ? await _service.historial(
              negocioId: negocioId,
              estado: _filtroEstado,
              fechaDesde: _filtroFecha,
              fechaHasta: _filtroFecha,
              profesionalId: _filtroProfesionalId,
              search: _filtroSearch,
              limit: _pageSize,
              offset: _page * _pageSize,
            )
          : await _service.listarPorNegocio(
              negocioId: negocioId,
              estado: _filtroEstado,
              fecha: _filtroFecha,
              profesionalId: _filtroProfesionalId,
              search: _filtroSearch,
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

  void setFiltroProfesional(int? id) {
    _filtroProfesionalId = id;
    notifyListeners();
  }

  void setFiltroSearch(String? search) {
    final value = (search ?? '').trim();
    _filtroSearch = value.isEmpty ? null : value;
    notifyListeners();
  }

  void setHistorial(bool value) {
    if (_historial == value) return;
    _historial = value;
    _items = [];
    _total = 0;
    _page = 0;
    notifyListeners();
  }

  void limpiarFiltros() {
    _filtroEstado = null;
    _filtroFecha = null;
    _filtroProfesionalId = null;
    _filtroSearch = null;
    notifyListeners();
  }

  Future<void> cargarProfesionales(int negocioId) async {
    try {
      _profesionales
        ..clear()
        ..addAll(await _service.listarProfesionales(negocioId));
    } catch (e) {
      _errorMessage = _msg(e);
    }
    notifyListeners();
  }

  // ================= DETALLE =================
  Future<void> cargarDetalle(int negocioId, int idReserva) async {
    _isLoading = true;
    _errorMessage = null;
    _detalle = null;
    notifyListeners();
    try {
      _detalle = await _service.detalle(negocioId, idReserva);
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
      await _service.confirmar(negocioId, idReserva);
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
      await _service.rechazar(negocioId, idReserva, motivo);
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

  // ================= COMPLETAR =================
  Future<bool> completar(int negocioId, int idReserva) async {
    _accionEnCursoId = idReserva;
    _errorMessage = null;
    notifyListeners();

    final idx = _items.indexWhere((r) => r.idReserva == idReserva);
    final previo = idx >= 0 ? _items[idx] : null;
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(estado: EstadoReserva.completada);
      notifyListeners();
    }

    try {
      await _service.completar(negocioId, idReserva);
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

  // ================= CAMBIO DE ESTADO =================
  Future<bool> actualizarEstado(
    int negocioId,
    int idReserva,
    EstadoReserva estado, {
    String? motivo,
  }) async {
    _accionEnCursoId = idReserva;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.actualizarEstado(
        negocioId,
        idReserva,
        estado,
        motivo: motivo,
      );
      await cargar(negocioId: negocioId, reset: true);
      return true;
    } catch (e) {
      _errorMessage = _msg(e);
      notifyListeners();
      return false;
    } finally {
      _accionEnCursoId = null;
      notifyListeners();
    }
  }

  // ================= ASIGNAR PROFESIONAL =================
  Future<bool> actualizarProfesional(
    int negocioId,
    int idReserva,
    int? profesionalId,
  ) async {
    _accionEnCursoId = idReserva;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.actualizarProfesional(
        negocioId,
        idReserva,
        profesionalId,
      );
      await cargar(negocioId: negocioId, reset: true);
      if (_detalle?.idReserva == idReserva) {
        await cargarDetalle(negocioId, idReserva);
      }
      return true;
    } catch (e) {
      _errorMessage = _msg(e);
      notifyListeners();
      return false;
    } finally {
      _accionEnCursoId = null;
      notifyListeners();
    }
  }

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');
}