import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/reserva_model.dart';

class EstadoReservaChip extends StatelessWidget {
  final EstadoReserva estado;
  const EstadoReservaChip(this.estado, {super.key});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (estado) {
      EstadoReserva.pendiente => (
          AppColors.accent.withOpacity(.18),
          AppColors.textPrimary
        ),
      EstadoReserva.confirmada => (
          AppColors.success.withOpacity(.18),
          AppColors.success
        ),
      EstadoReserva.cancelada => (
          AppColors.error.withOpacity(.15),
          AppColors.error
        ),
      EstadoReserva.completada => (
          AppColors.secondary.withOpacity(.18),
          AppColors.secondary
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado.label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}