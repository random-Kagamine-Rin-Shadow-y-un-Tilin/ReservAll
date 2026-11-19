import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../controllers/reserva_controller.dart';
import '../../models/reserva_model.dart';
import '../widgets/rechazar_reserva_dialog.dart';
import '../widgets/reserva_card.dart';
import 'reserva_detail_screen.dart';

class ReservasListScreen extends StatefulWidget {
  final int negocioId;
  const ReservasListScreen({super.key, required this.negocioId});

  @override
  State<ReservasListScreen> createState() => _ReservasListScreenState();
}

class _ReservasListScreenState extends State<ReservasListScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservaController>().cargar(negocioId: widget.negocioId);
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
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Reservas'),
      ),
      body: Consumer<ReservaController>(
        builder: (context, ctrl, _) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ctrl.cargar(negocioId: widget.negocioId),
            child: _buildBody(context, ctrl),
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
          Center(child: Text('No hay reservas')),
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
              builder: (_) => ReservaDetailScreen(idReserva: r.idReserva),
            ),
          ),
          onConfirmar: r.estado == EstadoReserva.pendiente && !enCurso
              ? () => _confirmar(context, ctrl, r.idReserva)
              : null,
          onRechazar: r.estado == EstadoReserva.pendiente && !enCurso
              ? () => _rechazar(context, ctrl, r.idReserva)
              : null,
        );
      },
    );
  }

  Future<void> _confirmar(
      BuildContext ctx, ReservaController ctrl, int id) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar reserva'),
        content: const Text('¿Confirmas esta reserva?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final success = await ctrl.confirmar(widget.negocioId, id);
    if (!mounted) return;
    _toast(ctx,
        success ? 'Reserva confirmada' : (ctrl.errorMessage ?? 'Error'),
        error: !success);
  }

  Future<void> _rechazar(
      BuildContext ctx, ReservaController ctrl, int id) async {
    final motivo = await showRechazarReservaDialog(ctx);
    if (motivo == null) return;

    final success = await ctrl.rechazar(widget.negocioId, id, motivo);
    if (!mounted) return;
    _toast(ctx,
        success ? 'Reserva rechazada' : (ctrl.errorMessage ?? 'Error'),
        error: !success);
  }

  void _toast(BuildContext ctx, String msg, {bool error = false}) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }
}