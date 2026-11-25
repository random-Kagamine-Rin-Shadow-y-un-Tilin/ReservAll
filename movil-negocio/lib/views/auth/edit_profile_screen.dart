import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../models/auth_model.dart';
import '../../utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

/// HU_05: pantalla de edición del perfil propio.
/// El backend exige `password_actual` para cambiar correo o contraseña.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _correoController;
  final _passwordActualController = TextEditingController();
  final _passwordNuevaController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().user;
    _nombreController = TextEditingController(text: user?.nombre ?? '');
    _correoController = TextEditingController(text: user?.correo ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _passwordActualController.dispose();
    _passwordNuevaController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validarNombre(String? value) {
    if (value == null || value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  String? _validarPasswordNueva(String? value) {
    if (value == null || value.isEmpty) return null; // opcional
    if (value.length < 8) return 'Mínimo 8 caracteres';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Incluye una mayúscula';
    if (!value.contains(RegExp(r'[a-z]'))) return 'Incluye una minúscula';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Incluye un número';
    return null;
  }

  String? _validarConfirmacion(String? value) {
    if (_passwordNuevaController.text.isEmpty) return null;
    if (value == null || value.isEmpty) return 'Confirma la nueva contraseña';
    if (value != _passwordNuevaController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<AuthController>();
    final user = controller.user;
    final nombre = _nombreController.text.trim();
    final correo = _correoController.text.trim();
    final nueva = _passwordNuevaController.text;
    final sensibles = correo != (user?.correo ?? '') || nueva.isNotEmpty;

    if (nombre == (user?.nombre ?? '') && !sensibles) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cambios para guardar')),
      );
      return;
    }
    if (sensibles && _passwordActualController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ingresa tu contraseña actual para cambiar el correo o la contraseña',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final ok = await controller.updateProfile(
      ProfileUpdateRequest(
        nombre: nombre != user?.nombre ? nombre : null,
        correo: correo != user?.correo ? correo : null,
        passwordActual: sensibles ? _passwordActualController.text : null,
        passwordNueva: nueva.isNotEmpty ? nueva : null,
        confirmPassword: nueva.isNotEmpty ? _confirmController.text : null,
      ),
    );
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'No se pudo actualizar el perfil',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil actualizado correctamente')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),
      body: Consumer<AuthController>(
        builder: (context, controller, child) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomTextField(
                      controller: _nombreController,
                      label: 'Nombre',
                      hint: 'Tu nombre',
                      prefixIcon: Icons.person,
                      validator: _validarNombre,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _correoController,
                      label: 'Correo electrónico',
                      hint: 'ejemplo@correo.com',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Cambios sensibles',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Necesitas tu contraseña actual para cambiar el correo o establecer una nueva contraseña.',
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _passwordActualController,
                      label: 'Contraseña actual',
                      hint: 'Solo si cambias correo o contraseña',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscure,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _passwordNuevaController,
                      label: 'Nueva contraseña (opcional)',
                      hint: 'Mínimo 8 caracteres',
                      prefixIcon: Icons.lock,
                      obscureText: _obscure,
                      validator: _validarPasswordNueva,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _confirmController,
                      label: 'Confirmar nueva contraseña',
                      hint: 'Repite la nueva contraseña',
                      prefixIcon: Icons.lock,
                      obscureText: _obscure,
                      validator: _validarConfirmacion,
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Guardar cambios',
                      icon: Icons.save,
                      isLoading: controller.isLoading,
                      onPressed: _guardar,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
