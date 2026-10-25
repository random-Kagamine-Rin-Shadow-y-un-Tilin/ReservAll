import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../controllers/profesional_controller.dart';
import '../../controllers/service_controller.dart';
import '../../models/profesional_model.dart';
import '../../models/service_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class EditServiceScreen extends StatefulWidget {
  final int shopId;
  final Service service;

  const EditServiceScreen({
    super.key,
    required this.shopId,
    required this.service,
  });

  @override
  State<EditServiceScreen> createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends State<EditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _precioController;
  late final TextEditingController _duracionController;
  late final TextEditingController _cantidadController;

  late String _categoria;
  late bool _estado;
  final List<int> _selectedProfIds = [];
  List<Professional> _availableProfessionals = [];

  @override
  void initState() {
    super.initState();
    // Precargar datos
    _nombreController = TextEditingController(text: widget.service.nombre);
    _descripcionController = TextEditingController(text: widget.service.descripcion ?? '');
    _precioController = TextEditingController(text: widget.service.precio.toString());
    _duracionController = TextEditingController(text: widget.service.duracionMinutos.toString());
    _cantidadController = TextEditingController(text: widget.service.cantidadServicio.toString());
    _categoria = widget.service.categoriaServicio;
    _estado = widget.service.estadoServicio;
    
    // Precargar profesionales asignados
    _selectedProfIds.addAll(widget.service.profesionales.map((p) => p.idProfesional));

    // Cargar lista de profesionales disponibles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfessionals();
    });
  }

  Future<void> _loadProfessionals() async {
    final controller = context.read<ProfesionalController>();
    await controller.loadProfessionals(widget.shopId);
    if (mounted) {
      setState(() {
        _availableProfessionals = controller.professionals;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<ServiceController>();
    final request = ServiceEditRequest(
      nombre: _nombreController.text.trim(),
      descripcion: _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
      precio: double.tryParse(_precioController.text) ?? 0,
      duracionMinutos: int.tryParse(_duracionController.text) ?? 60,
      categoriaServicio: _categoria,
      cantidadServicio: int.tryParse(_cantidadController.text) ?? 1,
      estadoServicio: _estado,
      profesionalIds: _selectedProfIds,
    );

    final success = await controller.editService(widget.shopId, widget.service.idServicio, request);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Servicio actualizado'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.errorMessage ?? 'Error'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Servicio'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _nombreController,
                label: 'Nombre del servicio',
                hint: 'Ej: Consulta inicial',
                prefixIcon: Icons.design_services,
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descripcionController,
                label: 'Descripción (opcional)',
                hint: 'Detalles del servicio',
                prefixIcon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _precioController,
                      label: 'Precio',
                      hint: '0',
                      prefixIcon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _duracionController,
                      label: 'Duración (min)',
                      hint: '60',
                      prefixIcon: Icons.timer,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _categoria,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'servicio', child: Text('Servicio')),
                        DropdownMenuItem(value: 'mesa', child: Text('Mesa')),
                        DropdownMenuItem(value: 'producto', child: Text('Producto')),
                      ],
                      onChanged: (v) => setState(() => _categoria = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _cantidadController,
                      label: 'Cantidad',
                      hint: '1',
                      prefixIcon: Icons.numbers,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Estado activo/inactivo
              SwitchListTile(
                title: const Text('Servicio Activo'),
                subtitle: const Text('Si está inactivo, no se mostrará a los clientes'),
                value: _estado,
                activeColor: AppColors.success,
                onChanged: (v) => setState(() => _estado = v),
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
                      if (val == true) {
                        _selectedProfIds.add(p.idProfesional);
                      } else {
                        _selectedProfIds.remove(p.idProfesional);
                      }
                    });
                  },
                )),
              const SizedBox(height: 32),
              
              CustomButton(
                text: 'Guardar Cambios',
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