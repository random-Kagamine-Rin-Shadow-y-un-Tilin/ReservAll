import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String correoInicial;

  const ResetPasswordScreen({super.key, this.correoInicial = ''});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _correoController;
  final _codigoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _correoController = TextEditingController(text: widget.correoInicial);
  }

  @override
  void dispose() {
    _correoController.dispose();
    _codigoController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validarCodigo(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El código es obligatorio';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'El código debe tener 6 dígitos';
    }
    return null;
  }

  String? _validarConfirmacion(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<AuthController>();
    final ok = await controller.resetPassword(
      correo: _correoController.text,
      codigo: _codigoController.text,
      nuevaPassword: _passwordController.text,
      confirmPassword: _confirmController.text,
    );
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'No se pudo actualizar la contraseña',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Contraseña actualizada'),
        content: const Text('Inicia sesión de nuevo con tu nueva contraseña.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva contraseña'),
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
                    const Icon(Icons.key, size: 64, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Elige una contraseña segura',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mínimo 8 caracteres, con mayúscula, minúscula y número.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    CustomTextField(
                      controller: _correoController,
                      label: 'Correo electrónico',
                      hint: 'ejemplo@correo.com',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _codigoController,
                      label: 'Código de verificación',
                      hint: '000000',
                      prefixIcon: Icons.numbers,
                      keyboardType: TextInputType.number,
                      validator: _validarCodigo,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Nueva contraseña',
                      hint: 'Ingresa tu nueva contraseña',
                      prefixIcon: Icons.lock,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      validator: Validators.strongPassword,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _confirmController,
                      label: 'Confirmar contraseña',
                      hint: 'Repite la nueva contraseña',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      validator: _validarConfirmacion,
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Actualizar contraseña',
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
