import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../controllers/reserva_controller.dart';
import '../../models/reserva_model.dart';
import '../widgets/reserva_card.dart';
import '../widgets/rechazar_reserva_dialogo.dart';
import 'reserva_detail_screen.dart';

class ReservasListScreen extends StatefulWidget {
  final int negocioId;
  const ReservasListScreen({super.key, required this.negocioId});

  @override
  State<ReservasListScreen> createState() => _ReservasListScreenState();
}

class _ReservasListScreenState extends State<ReservasListScreen> {
  final _scroll = ScrollController();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final ctrl = context.read<ReservaController>();
    _searchCtrl.text = ctrl.filtroSearch ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.cargar(negocioId: widget.negocioId);
      ctrl.cargarProfesionales(widget.negocioId);
    });
    _scroll.addListener(() {
      if (_scroll.position.pixels >=
          _scroll.position.maxScrollExtent - 200) {
        context.read<ReservaController>().cargarMas(widget.negocioId);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final ctrl = context.read<ReservaController>();
    ctrl.setFiltroSearch(_searchCtrl.text);
    await ctrl.cargar(negocioId: widget.negocioId);
  }

  Future<void> _cambiarModo(bool historial) async {
    final ctrl = context.read<ReservaController>();
    ctrl.setHistorial(historial);
    await ctrl.cargar(negocioId: widget.negocioId);
  }

  Future<void> _confirmarReserva(ReservaListItem r) async {
    final ctrl = context.read<ReservaController>();
    final ok = await ctrl.confirmar(widget.negocioId, r.idReserva);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? '✅ Reserva #${r.idReserva} confirmada'
            : (ctrl.errorMessage ?? 'No se pudo confirmar')),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _rechazarReserva(ReservaListItem r) async {
    final motivo = await showRechazarReservaDialog(context);
    if (motivo == null || !mounted) return;
    final ctrl = context.read<ReservaController>();
    final ok = await ctrl.rechazar(widget.negocioId, r.idReserva, motivo);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Reserva #${r.idReserva} rechazada'
            : (ctrl.errorMessage ?? 'No se pudo rechazar')),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Reservas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _abrirFiltros(context),
          ),
        ],
      ),
      body: Consumer<ReservaController>(
        builder: (context, ctrl, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: TextField(
                  controller: _searchCtrl,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _buscar(),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Buscar por cliente o correo',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Limpiar búsqueda',
                      onPressed: () {
                        _searchCtrl.clear();
                        _buscar();
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Próximas'),
                      selected: !ctrl.historial,
                      selectedColor: AppColors.primary.withOpacity(0.15),
                      onSelected: (_) => _cambiarModo(false),
                    ),
                    ChoiceChip(
                      label: const Text('Historial'),
                      selected: ctrl.historial,
                      selectedColor: AppColors.primary.withOpacity(0.15),
                      onSelected: (_) => _cambiarModo(true),
                    ),
                    if (ctrl.hayFiltrosActivos)
                      ActionChip(
                        avatar: const Icon(Icons.filter_alt_off, size: 16),
                        label: const Text('Limpiar filtros'),
                        onPressed: () {
                          ctrl.limpiarFiltros();
                          _searchCtrl.clear();
                          ctrl.cargar(negocioId: widget.negocioId);
                        },
                      ),
                  ],
                ),
              ),
              _FiltrosActivos(
                ctrl: ctrl,
                negocioId: widget.negocioId,
                onLimpiarSearch: () => _searchCtrl.clear(),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ctrl.cargar(negocioId: widget.negocioId),
                  child: _buildBody(context, ctrl),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, ReservaController ctrl) {
    if (ctrl.isLoading && ctrl.items.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (ctrl.errorMessage != null && ctrl.items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Column(
              children: [
                Text(ctrl.errorMessage!,
                    style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => ctrl.cargar(negocioId: widget.negocioId),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (ctrl.items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: Text('No hay reservas para estos filtros')),
        ],
      );
    }

    return ListView.builder(
      controller: _scroll,
      itemCount: ctrl.items.length + (ctrl.hasMore ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i >= ctrl.items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }
        final r = ctrl.items[i];
        final enCurso = ctrl.accionEnCursoId == r.idReserva;
        return ReservaCard(
          reserva: r,
          accionEnCurso: enCurso,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReservaDetailScreen(
                    negocioId: widget.negocioId,
                    idReserva: r.idReserva,
                  ),
            ),
          ),
          onConfirmar: enCurso ? null : () => _confirmarReserva(r),
          onRechazar: enCurso ? null : () => _rechazarReserva(r),
        );
      },
    );
  }

  Future<void> _abrirFiltros(BuildContext context) async {
    final ctrl = context.read<ReservaController>();
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (_) => _FiltrosSheet(
        estado: ctrl.filtroEstado,
        fecha: ctrl.filtroFecha,
        profesionalId: ctrl.filtroProfesionalId,
        profesionales: ctrl.profesionales,
      ),
    );
    if (result == null) return;
    ctrl.setFiltroEstado(result['estado'] as EstadoReserva?);
    ctrl.setFiltroFecha(result['fecha'] as DateTime?);
    ctrl.setFiltroProfesional(result['profesionalId'] as int?);
    await ctrl.cargar(negocioId: widget.negocioId);
  }
}

// ---------- Chips de filtros activos ----------
class _FiltrosActivos extends StatelessWidget {
  final ReservaController ctrl;
  final int negocioId;
  final VoidCallback onLimpiarSearch;
  const _FiltrosActivos({
    required this.ctrl,
    required this.negocioId,
    required this.onLimpiarSearch,
  });

  @override
  Widget build(BuildContext context) {
    if (!ctrl.hayFiltrosActivos) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.surface,
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (ctrl.filtroSearch != null)
            Chip(
              label: Text('“${ctrl.filtroSearch}”'),
              onDeleted: () {
                ctrl.setFiltroSearch(null);
                onLimpiarSearch();
                ctrl.cargar(negocioId: negocioId);
              },
            ),
          if (ctrl.filtroEstado != null)
            Chip(
              label: Text(ctrl.filtroEstado!.label),
              onDeleted: () {
                ctrl.setFiltroEstado(null);
                ctrl.cargar(negocioId: negocioId);
              },
            ),
          if (ctrl.filtroFecha != null)
            Chip(
              label: Text(
                  '${ctrl.filtroFecha!.day}/${ctrl.filtroFecha!.month}/${ctrl.filtroFecha!.year}'),
              onDeleted: () {
                ctrl.setFiltroFecha(null);
                ctrl.cargar(negocioId: negocioId);
              },
            ),
          if (ctrl.filtroProfesionalId != null)
            Chip(
              label: Text(
                ctrl.profesionales
                    .firstWhere(
                      (p) => p.id == ctrl.filtroProfesionalId,
                      orElse: () => ProfesionalItem(id: 0, nombre: 'Profesional'),
                    )
                    .nombre,
              ),
              onDeleted: () {
                ctrl.setFiltroProfesional(null);
                ctrl.cargar(negocioId: negocioId);
              },
            ),
        ],
      ),
    );
  }
}

// ---------- Bottom sheet de filtros ----------
class _FiltrosSheet extends StatefulWidget {
  final EstadoReserva? estado;
  final DateTime? fecha;
  final int? profesionalId;
  final List<ProfesionalItem> profesionales;

  const _FiltrosSheet({
    this.estado,
    this.fecha,
    this.profesionalId,
    required this.profesionales,
  });

  @override
  State<_FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends State<_FiltrosSheet> {
  EstadoReserva? _estado;
  DateTime? _fecha;
  int? _profesionalId;

  @override
  void initState() {
    super.initState();
    _estado = widget.estado;
    _fecha = widget.fecha;
    _profesionalId = widget.profesionalId;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtrar reservas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Estado'),
            Wrap(
              spacing: 8,
              children: EstadoReserva.values.map((e) {
                return ChoiceChip(
                  label: Text(e.label),
                  selected: _estado == e,
                  selectedColor: AppColors.primary.withOpacity(.2),
                  onSelected: (v) => setState(() => _estado = v ? e : null),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Fecha'),
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_fecha == null
                      ? 'Elegir fecha'
                      : '${_fecha!.day}/${_fecha!.month}/${_fecha!.year}'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _fecha ?? DateTime.now(),
                      firstDate: DateTime.now()
                          .subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _fecha = picked);
                  },
                ),
                if (_fecha != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _fecha = null),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Personal'),
            DropdownButtonFormField<int?>(
              value: _profesionalId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Todos'),
                ),
                ...widget.profesionales.map(
                  (p) => DropdownMenuItem<int?>(
                    value: p.id,
                    child: Text(p.nombre),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _profesionalId = v),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, {
                      'estado': null,
                      'fecha': null,
                      'profesionalId': null,
                    }),
                    child: const Text('Limpiar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary),
                    onPressed: () => Navigator.pop(context, {
                      'estado': _estado,
                      'fecha': _fecha,
                      'profesionalId': _profesionalId,
                    }),
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}