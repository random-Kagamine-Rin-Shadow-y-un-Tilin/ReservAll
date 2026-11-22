import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../controllers/reserva_controller.dart';
import '../../models/reserva_model.dart';
import '../widgets/estado_reserva_chip.dart';
import '../widgets/rechazar_reserva_dialogo.dart';

class ReservaDetailScreen extends StatefulWidget {
  final int negocioId;
  final int idReserva;
  const ReservaDetailScreen({
    super.key,
    required this.negocioId,
    required this.idReserva,
  });

  @override
  State<ReservaDetailScreen> createState() => _ReservaDetailScreenState();
}

class _ReservaDetailScreenState extends State<ReservaDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<ReservaController>();
      ctrl.cargarDetalle(widget.negocioId, widget.idReserva);
      ctrl.cargarProfesionales(widget.negocioId);
    });
  }

  Future<void> _recargarDetalle() =>
      context.read<ReservaController>().cargarDetalle(
            widget.negocioId,
            widget.idReserva,
          );

  void _avisar(String mensaje, {required bool ok}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _confirmar(ReservaDetalle r) async {
    final ctrl = context.read<ReservaController>();
    final ok = await ctrl.confirmar(widget.negocioId, r.idReserva);
    await _recargarDetalle();
    _avisar(
      ok ? '✅ Reserva confirmada' : (ctrl.errorMessage ?? 'Error'),
      ok: ok,
    );
  }

  Future<void> _rechazar(ReservaDetalle r) async {
    final motivo = await showRechazarReservaDialog(context);
    if (motivo == null || !mounted) return;
    final ctrl = context.read<ReservaController>();
    final ok = await ctrl.rechazar(widget.negocioId, r.idReserva, motivo);
    await _recargarDetalle();
    _avisar(
      ok ? 'Reserva rechazada' : (ctrl.errorMessage ?? 'Error'),
      ok: ok,
    );
  }

  Future<void> _completar(ReservaDetalle r) async {
    final ctrl = context.read<ReservaController>();
    final ok = await ctrl.completar(widget.negocioId, r.idReserva);
    await _recargarDetalle();
    _avisar(
      ok ? '✅ Reserva completada' : (ctrl.errorMessage ?? 'Error'),
      ok: ok,
    );
  }

  Future<void> _cancelar(ReservaDetalle r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: const Text('La reserva quedará marcada como cancelada.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar reserva'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final ctrl = context.read<ReservaController>();
    final hecho = await ctrl.actualizarEstado(
      widget.negocioId,
      r.idReserva,
      EstadoReserva.cancelada,
    );
    await _recargarDetalle();
    _avisar(
      hecho ? 'Reserva cancelada' : (ctrl.errorMessage ?? 'Error'),
      ok: hecho,
    );
  }

  Future<void> _asignarProfesional(ReservaDetalle r) async {
    final ctrl = context.read<ReservaController>();
    if (ctrl.profesionales.isEmpty) {
      await ctrl.cargarProfesionales(widget.negocioId);
    }
    if (!mounted) return;

    final seleccion = await showModalBottomSheet<_ProfesionalSeleccion>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'Asignar personal',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_off_outlined),
              title: const Text('Sin asignar (mesa)'),
              trailing: r.profesionalId == null
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () =>
                  Navigator.pop(ctx, const _ProfesionalSeleccion(null)),
            ),
            ...ctrl.profesionales.map(
              (p) => ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(p.nombre),
                subtitle: p.especialidad != null
                    ? Text(p.especialidad!)
                    : null,
                trailing: r.profesionalId == p.id
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () =>
                    Navigator.pop(ctx, _ProfesionalSeleccion(p.id)),
              ),
            ),
          ],
        ),
      ),
    );
    if (seleccion == null || !mounted) return;

    final ok = await ctrl.actualizarProfesional(
      widget.negocioId,
      r.idReserva,
      seleccion.profesionalId,
    );
    await _recargarDetalle();
    _avisar(
      ok ? 'Personal actualizado' : (ctrl.errorMessage ?? 'Error'),
      ok: ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Detalle de reserva'),
      ),
      body: Consumer<ReservaController>(
        builder: (context, ctrl, _) {
          if (ctrl.isLoading && ctrl.detalle == null) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (ctrl.errorMessage != null && ctrl.detalle == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(ctrl.errorMessage!,
                      style: const TextStyle(color: AppColors.error)),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => ctrl.cargarDetalle(
                          widget.negocioId,
                          widget.idReserva,
                        ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          final r = ctrl.detalle;
          if (r == null) return const SizedBox.shrink();
          return _buildContent(r);
        },
      ),
      bottomNavigationBar: Consumer<ReservaController>(
        builder: (context, ctrl, _) {
          final r = ctrl.detalle;
          if (r == null) return const SizedBox.shrink();
          return _buildAcciones(ctrl, r);
        },
      ),
    );
  }

  Widget _buildAcciones(ReservaController ctrl, ReservaDetalle r) {
    final enCurso = ctrl.accionEnCursoId == r.idReserva;
    final Widget? rechazar;
    final Widget? principal;

    switch (r.estado) {
      case EstadoReserva.pendiente:
        rechazar = OutlinedButton.icon(
          onPressed: enCurso ? null : () => _rechazar(r),
          icon: const Icon(Icons.close, size: 18),
          label: const Text('Rechazar'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
          ),
        );
        principal = FilledButton.icon(
          onPressed: enCurso ? null : () => _confirmar(r),
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Confirmar'),
          style:
              FilledButton.styleFrom(backgroundColor: AppColors.primary),
        );
        break;
      case EstadoReserva.confirmada:
        rechazar = OutlinedButton.icon(
          onPressed: enCurso ? null : () => _cancelar(r),
          icon: const Icon(Icons.cancel_outlined, size: 18),
          label: const Text('Cancelar'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
          ),
        );
        principal = FilledButton.icon(
          onPressed: enCurso ? null : () => _completar(r),
          icon: const Icon(Icons.task_alt, size: 18),
          label: const Text('Completar'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.success),
        );
        break;
      case EstadoReserva.cancelada:
      case EstadoReserva.completada:
        return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: enCurso
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.primary,
                  ),
                ),
              )
            : Row(
                children: [
                  Expanded(child: rechazar),
                  const SizedBox(width: 10),
                  Expanded(child: principal),
                ],
              ),
      ),
    );
  }

  Widget _buildContent(ReservaDetalle r) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('#${r.idReserva}',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            EstadoReservaChip(r.estado),
          ],
        ),
        const Divider(height: 24),
        _row('Fecha', _fmtFecha(r.fecha)),
        _row(
          'Hora',
          r.horaFin == null
              ? _hhmm(r.horaInicio)
              : '${_hhmm(r.horaInicio)} - ${_hhmm(r.horaFin!)}',
        ),
        const Divider(height: 24),
        const Text('Cliente',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        _row('Nombre', r.clienteNombre),
        _row('Correo', r.clienteCorreo),
        const Divider(height: 24),
        const Text('Servicio',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        _row('Nombre', r.servicioNombre),
        _row('Duración', '${r.servicioDuracion} min'),
        _row('Precio', '\$${r.servicioPrecio.toStringAsFixed(2)}'),
        if (r.servicioCategoria != null)
          _row('Categoría', r.servicioCategoria!),
        const Divider(height: 24),
        Row(
          children: [
            const Expanded(
              child: Text('Personal asignado',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            if (r.estado == EstadoReserva.pendiente ||
                r.estado == EstadoReserva.confirmada)
              TextButton.icon(
                onPressed: () => _asignarProfesional(r),
                icon: const Icon(Icons.person_add_alt, size: 18),
                label: Text(r.profesionalId == null ? 'Asignar' : 'Cambiar'),
              ),
          ],
        ),
        _row(
          'Profesional',
          r.profesionalNombre ?? 'Sin asignar (mesa)',
        ),
        if (r.profesionalEspecialidad != null)
          _row('Especialidad', r.profesionalEspecialidad!),
        const Divider(height: 24),
        const Text('Negocio',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        _row('Nombre', r.negocioNombre),
        if (r.comentario != null && r.comentario!.isNotEmpty) ...[
          const Divider(height: 24),
          const Text('Comentario del cliente',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(r.comentario!),
        ],
        if (r.motivo != null && r.motivo!.isNotEmpty) ...[
          const Divider(height: 24),
          const Text('Motivo del rechazo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(r.motivo!, style: const TextStyle(color: AppColors.error)),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 120,
                child: Text(label,
                    style: TextStyle(color: AppColors.textSecondary))),
            Expanded(child: Text(value)),
          ],
        ),
      );

  String _fmtFecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _hhmm(String h) => h.length >= 5 ? h.substring(0, 5) : h;
}

class _ProfesionalSeleccion {
  final int? profesionalId;
  const _ProfesionalSeleccion(this.profesionalId);
}