import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../controllers/profesional_controller.dart';
import '../../models/profesional_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class AddProfessionalScreen extends StatefulWidget {
  final int shopId;
  final Professional? professional;
  const AddProfessionalScreen({
    super.key,
    required this.shopId,
    this.professional,
  });

  bool get isEdit => professional != null;

  @override
  State<AddProfessionalScreen> createState() => _AddProfessionalScreenState();
}

class _AddProfessionalScreenState extends State<AddProfessionalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _especialidadController = TextEditingController();
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    final p = widget.professional;
    if (p != null) {
      _nombreController.text = p.nombre;
      _especialidadController.text = p.especialidad ?? '';
      _activo = p.activo;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _especialidadController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<ProfesionalController>();
    final nombre = _nombreController.text.trim();
    final especialidad = _especialidadController.text.trim().isEmpty
        ? null
        : _especialidadController.text.trim();

    final bool success;
    if (widget.isEdit) {
      success = await controller.updateProfessional(
        widget.shopId,
        widget.professional!.idProfesional,
        ProfessionalUpdateRequest(
          nombre: nombre,
          especialidad: especialidad,
          activo: _activo,
        ),
      );
    } else {
      success = await controller.createProfessional(
        widget.shopId,
        ProfessionalCreateRequest(
          nombre: nombre,
          especialidad: especialidad,
        ),
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEdit
                ? '✅ Profesional actualizado'
                : '✅ Profesional agregado',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Editar Profesional' : 'Nuevo Profesional'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _nombreController,
                label: 'Nombre',
                hint: 'Ej: Dra. Ana',
                prefixIcon: Icons.person,
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _especialidadController,
                label: 'Especialidad (opcional)',
                hint: 'Ej: Psicóloga Clínica',
                prefixIcon: Icons.work,
              ),
              if (widget.isEdit) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activo'),
                  subtitle: const Text(
                    'Los profesionales inactivos no reciben nuevas reservas.',
                  ),
                  value: _activo,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => _activo = v),
                ),
              ],
              const SizedBox(height: 32),
              CustomButton(
                text: widget.isEdit ? 'Guardar cambios' : 'Guardar',
                onPressed: _handleSave,
                isPrimary: true,
                icon: Icons.save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
