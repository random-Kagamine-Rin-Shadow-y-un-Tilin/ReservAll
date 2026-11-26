import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/reserva_model.dart';
import 'estado_reserva_chip.dart';

class ReservaCard extends StatelessWidget {
  final ReservaListItem reserva;
  final VoidCallback onTap;
  final VoidCallback? onConfirmar;
  final VoidCallback? onRechazar;
  final bool accionEnCurso;

  const ReservaCard({
    super.key,
    required this.reserva,
    required this.onTap,
    this.onConfirmar,
    this.onRechazar,
    this.accionEnCurso = false,
  });

  @override
  Widget build(BuildContext context) {
    final esPendiente = reserva.estado == EstadoReserva.pendiente &&
        (onConfirmar != null || onRechazar != null);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_dmy(reserva.fecha)} · ${_hhmm(reserva.horaInicio)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  EstadoReservaChip(reserva.estado),
                ],
              ),
              const SizedBox(height: 6),
              Text(reserva.servicioNombre,
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 2),
              Text('Cliente: ${reserva.clienteNombre}',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              // ---- Personal asignado ----
              Text(
                reserva.profesionalNombre != null
                    ? 'Profesional: ${reserva.profesionalNombre}'
                    : 'Profesional: Sin asignar',
                style: TextStyle(
                  fontSize: 13,
                  color: reserva.profesionalNombre != null
                      ? AppColors.textSecondary
                      : AppColors.accent,
                  fontStyle: reserva.profesionalNombre != null
                      ? FontStyle.normal
                      : FontStyle.italic,
                ),
              ),
              if (esPendiente) ...[
                const SizedBox(height: 10),
                if (accionEnCurso)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onRechazar,
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Rechazar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onConfirmar,
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Confirmar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _dmy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _hhmm(String h) => h.length >= 5 ? h.substring(0, 5) : h;
}