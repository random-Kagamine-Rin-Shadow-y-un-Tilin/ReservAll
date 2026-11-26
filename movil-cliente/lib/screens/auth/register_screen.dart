import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final Color primaryColor = const Color(0xFFE2725B);
  final Color secondaryColor = const Color(0xFF2A9D8F);
  final Color backgroundColor = const Color(0xFFFAF6F1);
  final Color surfaceColor = const Color(0xFFFFFFFF);
  final Color textMainColor = const Color(0xFF2B2118);
  final Color textSecondaryColor = const Color(0xFF7A7267);

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final String cleanName = nameController.text.trim();
    final String cleanEmail = emailController.text.trim();
    final String normalizedEmail = cleanEmail.toLowerCase();

    final Map<String, dynamic> bodyData = {
      "nombre": cleanName,
      "correo": cleanEmail,
      "password": passwordController.text.trim(),
      "confirm_password": confirmPasswordController.text.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/register"),
        headers: {
          "accept": "application/json",
          "Content-Type": "application/json",
          "x-api-key": apiKey,
        },
        body: jsonEncode(bodyData),
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', cleanName);
        await prefs.setString('nombre', cleanName);
        await prefs.setString('last_profile_name', cleanName);
        await prefs.setString('user_email', cleanEmail);
        await prefs.setString('correo', cleanEmail);
        await prefs.setString('profile_name_$normalizedEmail', cleanName);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Registro exitoso! Ya puedes iniciar sesión."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        String errorMsg = "No se pudo completar el registro.";
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map<String, dynamic> &&
              errorBody['detail'] != null) {
            errorMsg = errorBody['detail'].toString();
          }
        } catch (_) {}

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $errorMsg"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      debugPrint("Error de conexión en registro: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error de conexión con el servidor."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Registro de Cliente",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Crea tu cuenta",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textMainColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Regístrate como cliente para empezar a agendar tus citas.",
                  style: TextStyle(fontSize: 14, color: textSecondaryColor),
                ),
                const SizedBox(height: 30),

                Text(
                  "Nombre completo",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textMainColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: "Ej. María López",
                    filled: true,
                    fillColor: surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.person, color: textSecondaryColor),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Por favor ingresa tu nombre'
                      : null,
                ),
                const SizedBox(height: 20),

                Text(
                  "Correo electrónico",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textMainColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "correo@ejemplo.com",
                    filled: true,
                    fillColor: surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.email, color: textSecondaryColor),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa tu correo';
                    }
                    if (!value.contains('@')) return 'Ingresa un correo válido';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                Text(
                  "Contraseña",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textMainColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "* Debe tener al menos 8 caracteres, una mayúscula, una minúscula y un número.",
                  style: TextStyle(
                    fontSize: 11,
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: "********",
                    filled: true,
                    fillColor: surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.lock, color: textSecondaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: textSecondaryColor,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa una contraseña';
                    }
                    if (value.length < 8) {
                      return 'Debe tener al menos 8 caracteres';
                    }
                    if (!value.contains(RegExp(r'[A-Z]'))) {
                      return 'Debe incluir al menos una letra mayúscula';
                    }
                    if (!value.contains(RegExp(r'[a-z]'))) {
                      return 'Debe incluir al menos una letra minúscula';
                    }
                    if (!value.contains(RegExp(r'[0-9]'))) {
                      return 'Debe incluir al menos un número';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                Text(
                  "Confirmar contraseña",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textMainColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: "********",
                    filled: true,
                    fillColor: surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: textSecondaryColor,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: textSecondaryColor,
                      ),
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirma tu contraseña';
                    }
                    if (value != passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 35),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isLoading ? null : _registerClient,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Registrarse",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
