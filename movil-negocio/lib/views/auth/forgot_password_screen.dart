import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../models/auth_model.dart';
import '../../utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'login_screen.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  PasswordResetRequestOut? _result;

  @override
  void dispose() {
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _solicitar() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<AuthController>();
    final result = await controller.requestPasswordReset(
      _correoController.text,
    );
    if (!mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'No se pudo solicitar el código',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _result = result);
  }

  void _irAReset() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ResetPasswordScreen(correoInicial: _correoController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
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
                    const Icon(
                      Icons.lock_reset,
                      size: 72,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _result == null
                          ? '¿Olvidaste tu contraseña?'
                          : 'Revisa tu correo',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _result == null
                          ? 'Ingresa tu correo y te enviaremos un código de 6 dígitos.'
                          : _result!.mensaje,
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    if (_result == null) ...[
                      CustomTextField(
                        controller: _correoController,
                        label: 'Correo electrónico',
                        hint: 'ejemplo@correo.com',
                        prefixIcon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Enviar código',
                        icon: Icons.send,
                        isLoading: controller.isLoading,
                        onPressed: _solicitar,
                      ),
                    ] else ...[
                      Card(
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(
                                Icons.mark_email_read,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'El código es válido durante ${_result!.expiraEnMinutos} minutos.',
                                textAlign: TextAlign.center,
                              ),
                              if (_result!.codigo != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Modo desarrollo: tu código es ${_result!.codigo}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Ya tengo el código',
                        icon: Icons.arrow_forward,
                        onPressed: _irAReset,
                      ),
                    ],

                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      child: const Text('Volver al inicio de sesión'),
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
