import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../controllers/reserva_controller.dart';
import '../../models/reserva_model.dart';
import '../widgets/estado_reserva_chip.dart';

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
      context.read<ReservaController>().cargarDetalle(
            widget.negocioId,
            widget.idReserva,
          );
    });
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
        const Text('Personal asignado',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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