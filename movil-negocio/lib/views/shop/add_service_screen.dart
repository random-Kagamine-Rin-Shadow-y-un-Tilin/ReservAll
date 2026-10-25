import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../controllers/profesional_controller.dart';
import '../../controllers/service_controller.dart';
import '../../models/profesional_model.dart';
import '../../models/service_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class AddServiceScreen extends StatefulWidget {
  final int shopId;
  const AddServiceScreen({super.key, required this.shopId});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController(text: '0');
  final _duracionController = TextEditingController(text: '60');
  final _cantidadController = TextEditingController(text: '1');
  
  String _categoria = 'servicio';
  final List<int> _selectedProfIds = [];
  List<Professional> _availableProfessionals = [];

  @override
  void initState() {
    super.initState();
    _loadProfessionals();
  }

  Future<void> _loadProfessionals() async {
    final controller = context.read<ProfesionalController>();
    await controller.loadProfessionals(widget.shopId);
    setState(() {
      _availableProfessionals = controller.professionals;
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    final controller = context.read<ServiceController>();
    final request = ServiceCreateRequest(
      nombre: _nombreController.text.trim(),
      descripcion: _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
      precio: double.tryParse(_precioController.text) ?? 0,
      duracionMinutos: int.tryParse(_duracionController.text) ?? 60,
      categoriaServicio: _categoria,
      cantidadServicio: int.tryParse(_cantidadController.text) ?? 1,
      profesionalIds: _selectedProfIds,
    );

    final success = await controller.createService(widget.shopId, request);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Servicio agregado'), backgroundColor: AppColors.success));
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(controller.errorMessage ?? 'Error'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Servicio'), backgroundColor: AppColors.primary, foregroundColor: AppColors.surface),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(controller: _nombreController, label: 'Nombre del servicio', hint: 'Ej: Consulta inicial', prefixIcon: Icons.design_services, validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 16),
              CustomTextField(controller: _descripcionController, label: 'Descripción (opcional)', hint: 'Detalles del servicio', prefixIcon: Icons.description, maxLines: 3),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: CustomTextField(controller: _precioController, label: 'Precio', hint: '0', prefixIcon: Icons.attach_money, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: CustomTextField(controller: _duracionController, label: 'Duración (min)', hint: '60', prefixIcon: Icons.timer, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _categoria,
                      decoration: const InputDecoration(labelText: 'Categoría', prefixIcon: Icon(Icons.category), border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'servicio', child: Text('Servicio')),
                        DropdownMenuItem(value: 'mesa', child: Text('Mesa')),
                        DropdownMenuItem(value: 'producto', child: Text('Producto')),
                      ],
                      onChanged: (v) => setState(() => _categoria = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: CustomTextField(controller: _cantidadController, label: 'Cantidad', hint: '1', prefixIcon: Icons.numbers, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Profesionales asignados', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              if (_availableProfessionals.isEmpty)
                const Text('No hay profesionales. Registra uno primero.', style: TextStyle(color: AppColors.error))
              else
                ..._availableProfessionals.map((p) => CheckboxListTile(
                  title: Text(p.nombre),
                  subtitle: Text(p.especialidad ?? ''),
                  value: _selectedProfIds.contains(p.idProfesional),
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) _selectedProfIds.add(p.idProfesional);
                      else _selectedProfIds.remove(p.idProfesional);
                    });
                  },
                )),
              const SizedBox(height: 32),
              CustomButton(text: 'Guardar Servicio', onPressed: _handleSave, isPrimary: true, icon: Icons.save),
            ],
          ),
        ),
      ),
    );
  }
}