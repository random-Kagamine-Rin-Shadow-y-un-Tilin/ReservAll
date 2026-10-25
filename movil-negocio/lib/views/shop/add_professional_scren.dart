import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../controllers/profesional_controller.dart';
import '../../models/profesional_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class AddProfessionalScreen extends StatefulWidget {
  final int shopId;
  const AddProfessionalScreen({super.key, required this.shopId});

  @override
  State<AddProfessionalScreen> createState() => _AddProfessionalScreenState();
}

class _AddProfessionalScreenState extends State<AddProfessionalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _especialidadController = TextEditingController();

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    final controller = context.read<ProfesionalController>();
    final request = ProfessionalCreateRequest(
      nombre: _nombreController.text.trim(),
      especialidad: _especialidadController.text.trim().isEmpty ? null : _especialidadController.text.trim(),
    );

    final success = await controller.createProfessional(widget.shopId, request);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Profesional agregado'), backgroundColor: AppColors.success));
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(controller.errorMessage ?? 'Error'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Profesional'), backgroundColor: AppColors.primary, foregroundColor: AppColors.surface),
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
              const SizedBox(height: 32),
              CustomButton(
                text: 'Guardar',
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