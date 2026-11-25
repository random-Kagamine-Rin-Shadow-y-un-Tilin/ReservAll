import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../controllers/agenda_controller.dart';
import '../../models/agenda_model.dart';

class AgendaScreen extends StatefulWidget {
  final int shopId;
  const AgendaScreen({super.key, required this.shopId});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgendaController>().cargar(widget.shopId);
    });
  }

  Future<void> _recargar() =>
      context.read<AgendaController>().cargar(widget.shopId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Agenda'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _recargar,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        onPressed: _abrirNuevoBloqueo,
        icon: const Icon(Icons.block),
        label: const Text('Bloquear'),
      ),
      body: Consumer<AgendaController>(
        builder: (context, ctrl, _) {
          if (ctrl.isLoading && ctrl.agenda == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (ctrl.errorMessage != null && ctrl.agenda == null) {
            return _EstadoError(
              mensaje: ctrl.errorMessage!,
              onRetry: _recargar,
            );
          }
          final agenda = ctrl.agenda;
          if (agenda == null) {
            return const Center(child: Text('No hay información de agenda'));
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _recargar,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              children: [
                _ResumenCard(resumen: agenda.resumen),
                const SizedBox(height: 12),
                _RangoSelector(ctrl: ctrl, shopId: widget.shopId),
                const SizedBox(height: 12),
                if (agenda.dias.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        'No hay días en este rango',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ...agenda.dias.map(
                  (dia) => _DiaCard(
                    dia: dia,
                    accionEnCurso: ctrl.accionEnCurso,
                    onEliminarBloqueo: _confirmarEliminarBloqueo,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _abrirNuevoBloqueo() async {
    final result = await showDialog<_BloqueoDraft>(
      context: context,
      builder: (_) => const _NuevoBloqueoDialog(),
    );
    if (result == null || !mounted) return;

    final ctrl = context.read<AgendaController>();
    final ok = await ctrl.crearBloqueo(
      widget.shopId,
      fecha: result.fecha,
      horaInicio: result.horaInicio,
      horaFin: result.horaFin,
      motivo: result.motivo,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '✅ Bloqueo creado'
              : (ctrl.errorMessage ?? 'No se pudo crear el bloqueo'),
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _confirmarEliminarBloqueo(AgendaBlock bloqueo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar bloqueo'),
        content: Text(
          bloqueo.diaCompleto
              ? 'Se liberará el día ${_fmtFecha(bloqueo.fecha)} completo.'
              : 'Se liberará el rango ${_hhmm(bloqueo.horaInicio)} - '
                  '${_hhmm(bloqueo.horaFin)} del ${_fmtFecha(bloqueo.fecha)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final ctrl = context.read<AgendaController>();
    final eliminado = await ctrl.eliminarBloqueo(
      widget.shopId,
      bloqueo.idBloqueo,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          eliminado
              ? '✅ Bloqueo eliminado'
              : (ctrl.errorMessage ?? 'No se pudo eliminar el bloqueo'),
        ),
        backgroundColor: eliminado ? AppColors.success : AppColors.error,
      ),
    );
  }
}

String _fmtFecha(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';

String _hhmm(String? value) {
  if (value == null || value.isEmpty) return '';
  return value.length >= 5 ? value.substring(0, 5) : value;
}

class _ResumenCard extends StatelessWidget {
  final AgendaSummary resumen;
  const _ResumenCard({required this.resumen});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen del rango',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _dato('Reservas', resumen.totalReservas, AppColors.primary),
                _dato('Pendientes', resumen.pendientes, AppColors.warning),
                _dato('Confirmadas', resumen.confirmadas, AppColors.info),
                _dato('Completadas', resumen.completadas, AppColors.success),
                _dato('Canceladas', resumen.canceladas, AppColors.error),
                _dato('Días abiertos', resumen.diasAbiertos, AppColors.info),
                _dato('Bloqueados', resumen.diasBloqueados, AppColors.error),
                _dato('Cerrados', resumen.diasCerrados, AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dato(String label, int valor, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$valor',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RangoSelector extends StatelessWidget {
  final AgendaController ctrl;
  final int shopId;
  const _RangoSelector({required this.ctrl, required this.shopId});

  void _mover(int dias) {
    ctrl.cargar(
      shopId,
      desde: ctrl.desde.add(Duration(days: dias)),
      hasta: ctrl.hasta.add(Duration(days: dias)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Rango anterior',
              onPressed: () => _mover(-7),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    '${_fmtFecha(ctrl.desde)} — ${_fmtFecha(ctrl.hasta)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextButton(
                    onPressed: () => ctrl.cargar(
                      shopId,
                      desde: DateTime(hoy.year, hoy.month, hoy.day),
                      hasta: DateTime(hoy.year, hoy.month, hoy.day)
                          .add(const Duration(days: 6)),
                    ),
                    child: const Text('Ir a hoy'),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Rango siguiente',
              onPressed: () => _mover(7),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiaCard extends StatelessWidget {
  final AgendaDay dia;
  final bool accionEnCurso;
  final ValueChanged<AgendaBlock> onEliminarBloqueo;

  const _DiaCard({
    required this.dia,
    required this.accionEnCurso,
    required this.onEliminarBloqueo,
  });

  @override
  Widget build(BuildContext context) {
    final estadoColor = dia.bloqueado
        ? AppColors.error
        : dia.abierto
            ? AppColors.success
            : AppColors.textSecondary;
    final estadoTexto = dia.bloqueado
        ? 'Bloqueado'
        : dia.abierto
            ? 'Abierto'
            : 'Cerrado';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${dia.diaSemana} · ${_fmtFecha(dia.fecha)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      ...() {
                        final turnos = dia.horarios.isNotEmpty
                            ? dia.horarios
                            : [if (dia.horario != null) dia.horario!];
                        return turnos.map(
                          (turno) => Text(
                            '${_hhmm(turno.horaApertura)} - '
                            '${_hhmm(turno.horaCierre)}'
                            '${turno.horaDescanso != null ? ' · descanso ${_hhmm(turno.horaDescanso)} (${turno.descansoDuracionMin} min)' : ''}'
                            '${turno.estadoHorario == false ? ' · inactivo' : ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }(),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    estadoTexto,
                    style: TextStyle(
                      color: estadoColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  label: Text('${dia.reservas.length} reservas'),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text('${dia.slotsLibres} espacios libres'),
                  visualDensity: VisualDensity.compact,
                ),
                if (dia.bloqueos.isNotEmpty)
                  Chip(
                    label: Text('${dia.bloqueos.length} bloqueos'),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.error.withOpacity(0.1),
                  ),
              ],
            ),
            if (dia.reservas.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...dia.reservas.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.event, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${_hhmm(r.horaInicio)} · ${r.clienteNombre} · '
                          '${r.servicioNombre}',
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        r.estado.label,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (dia.bloqueos.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...dia.bloqueos.map(
                (b) => Row(
                  children: [
                    const Icon(Icons.block, size: 16, color: AppColors.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        b.diaCompleto
                            ? 'Día completo${b.motivo != null ? " · ${b.motivo}" : ""}'
                            : '${_hhmm(b.horaInicio)} - ${_hhmm(b.horaFin)}'
                                '${b.motivo != null ? " · ${b.motivo}" : ""}',
                        style: const TextStyle(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.error,
                      ),
                      onPressed:
                          accionEnCurso ? null : () => onEliminarBloqueo(b),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EstadoError extends StatelessWidget {
  final String mensaje;
  final Future<void> Function() onRetry;
  const _EstadoError({required this.mensaje, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => onRetry(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BloqueoDraft {
  final DateTime fecha;
  final String? horaInicio;
  final String? horaFin;
  final String? motivo;

  _BloqueoDraft({
    required this.fecha,
    this.horaInicio,
    this.horaFin,
    this.motivo,
  });
}

class _NuevoBloqueoDialog extends StatefulWidget {
  const _NuevoBloqueoDialog();

  @override
  State<_NuevoBloqueoDialog> createState() => _NuevoBloqueoDialogState();
}

class _NuevoBloqueoDialogState extends State<_NuevoBloqueoDialog> {
  DateTime _fecha = DateTime.now();
  bool _diaCompleto = true;
  TimeOfDay? _inicio;
  TimeOfDay? _fin;
  final _motivoCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  String _format(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _elegirFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _elegirHora({required bool inicio}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: inicio
          ? (_inicio ?? const TimeOfDay(hour: 13, minute: 0))
          : (_fin ?? const TimeOfDay(hour: 14, minute: 0)),
    );
    if (picked == null) return;
    setState(() {
      if (inicio) {
        _inicio = picked;
      } else {
        _fin = picked;
      }
    });
  }

  void _guardar() {
    if (!_diaCompleto) {
      if (_inicio == null || _fin == null) {
        setState(() => _error = 'Indica la hora de inicio y de fin.');
        return;
      }
      final inicio = _inicio!.hour * 60 + _inicio!.minute;
      final fin = _fin!.hour * 60 + _fin!.minute;
      if (inicio >= fin) {
        setState(() => _error = 'La hora de inicio debe ser menor que la de fin.');
        return;
      }
    }

    Navigator.pop(
      context,
      _BloqueoDraft(
        fecha: _fecha,
        horaInicio: _diaCompleto ? null : _format(_inicio!),
        horaFin: _diaCompleto ? null : _format(_fin!),
        motivo: _motivoCtrl.text.trim().isEmpty
            ? null
            : _motivoCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo bloqueo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Fecha'),
              subtitle: Text(_fmtFecha(_fecha)),
              onTap: _elegirFecha,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bloquear todo el día'),
              value: _diaCompleto,
              activeThumbColor: AppColors.primary,
              onChanged: (v) => setState(() => _diaCompleto = v),
            ),
            if (!_diaCompleto) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _elegirHora(inicio: true),
                      child: Text(
                        _inicio == null ? 'Inicio' : _inicio!.format(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _elegirHora(inicio: false),
                      child: Text(_fin == null ? 'Fin' : _fin!.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _motivoCtrl,
              maxLength: 255,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _guardar,
          child: const Text('Bloquear'),
        ),
      ],
    );
  }
}
