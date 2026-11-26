import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../controllers/client_controller.dart';
import '../../models/client_model.dart';
import '../reservas/reserva_detail_screen.dart';
import '../widgets/reserva_card.dart';

class ClientDetailScreen extends StatefulWidget {
  final int shopId;
  final int clienteId;
  final String clienteNombre;

  const ClientDetailScreen({
    super.key,
    required this.shopId,
    required this.clienteId,
    this.clienteNombre = 'Cliente',
  });

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientController>().cargarDetalle(
            widget.shopId,
            widget.clienteId,
          );
    });
  }

  Future<void> _recargar() => context.read<ClientController>().cargarDetalle(
        widget.shopId,
        widget.clienteId,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.clienteNombre),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _recargar,
          ),
        ],
      ),
      body: Consumer<ClientController>(
        builder: (context, ctrl, _) {
          if (ctrl.isLoadingDetalle && ctrl.detalle == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (ctrl.errorMessage != null && ctrl.detalle == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 56,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ctrl.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _recargar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          final detalle = ctrl.detalle;
          if (detalle == null) {
            return const Center(child: Text('No se encontró el cliente'));
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _recargar,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _ResumenCliente(detalle: detalle),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Historial de reservas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                if (detalle.reservas.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Este cliente no tiene reservas registradas',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ...detalle.reservas.map(
                    (r) => ReservaCard(
                      reserva: r,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReservaDetailScreen(
                            negocioId: widget.shopId,
                            idReserva: r.idReserva,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ResumenCliente extends StatelessWidget {
  final ClienteDetalle detalle;
  const _ResumenCliente({required this.detalle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  foregroundColor: AppColors.primary,
                  child: Text(
                    detalle.nombre.isNotEmpty
                        ? detalle.nombre[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detalle.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        detalle.correo,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _stat('Reservas', '${detalle.totalReservas}', AppColors.primary),
                _stat('Completadas', '${detalle.completadas}', AppColors.success),
                _stat('Activas', '${detalle.activas}', AppColors.info),
                _stat('Canceladas', '${detalle.canceladas}', AppColors.error),
                _stat(
                  'Total gastado',
                  '\$${detalle.totalGastado.toStringAsFixed(2)}',
                  AppColors.success,
                ),
              ],
            ),
            if (detalle.servicioFavorito != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.star_outline,
                    size: 18,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Servicio favorito: ${detalle.servicioFavorito}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
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
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
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
