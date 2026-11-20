import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

Future<String?> showRechazarReservaDialog(BuildContext context) {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Rechazar reserva'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          maxLength: 500,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Motivo del rechazo',
            hintText: 'Explica brevemente al cliente...',
            border: const OutlineInputBorder(),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
          validator: (v) {
            if (v == null || v.trim().length < 3) {
              return 'Mínimo 3 caracteres';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(ctx, controller.text.trim());
            }
          },
          child: const Text('Rechazar'),
        ),
      ],
    ),
  );
}