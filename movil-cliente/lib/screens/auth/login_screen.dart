import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '/services/api_service.dart';
import 'register_screen.dart';

/// Extrae las cookies de sesión del encabezado `set-cookie` para enviarlas
/// como `Cookie` en las siguientes peticiones (sin atributos como Path/HttpOnly).
String _cookieHeaderFromSetCookie(String? rawSetCookie) {
  if (rawSetCookie == null || rawSetCookie.trim().isEmpty) return '';

  final values = <String>[];
  for (final name in const ['SNRL_access_token', 'SNRL_refresh_token']) {
    final match = RegExp('$name=([^;,\\s]+)').firstMatch(rawSetCookie);
    if (match != null) {
      values.add('$name=${match.group(1)}');
    }
  }

  if (values.isEmpty) {
    final firstPair = rawSetCookie.split(',').first.split(';').first.trim();
    if (firstPair.contains('=')) {
      values.add(firstPair);
    }
  }

  return values.join('; ');
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;

  final Color primaryColor = const Color(0xFFE2725B);
  final Color secondaryColor = const Color(0xFF2A9D8F);
  final Color backgroundColor = const Color(0xFFFAF6F1);
  final Color surfaceColor = const Color(0xFFFFFFFF);
  final Color textMainColor = const Color(0xFF2B2118);
  final Color textSecondaryColor = const Color(0xFF7A7267);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final String cleanEmail = emailController.text.trim();
    final Map<String, dynamic> bodyData = {
      "correo": cleanEmail,
      "password": passwordController.text.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: {
          "accept": "application/json",
          "Content-Type": "application/json",
          "x-api-key": apiKey,
        },
        body: jsonEncode(bodyData),
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', cleanEmail);
        await prefs.setString('correo', cleanEmail);

        final cookieHeader = _cookieHeaderFromSetCookie(
          response.headers['set-cookie'],
        );
        if (cookieHeader.isNotEmpty) {
          await prefs.setString('session_cookie', cookieHeader);
        }

        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            final userMap = (decoded['user'] is Map<String, dynamic>)
                ? decoded['user'] as Map<String, dynamic>
                : (decoded['usuario'] is Map<String, dynamic>)
                ? decoded['usuario'] as Map<String, dynamic>
                : decoded;

            final apiName = (userMap['nombre'] ?? userMap['name'])
                ?.toString()
                .trim();
            if (apiName != null && apiName.isNotEmpty) {
              await prefs.setString('user_name', apiName);
              await prefs.setString('nombre', apiName);
              await prefs.setString(
                'profile_name_${cleanEmail.toLowerCase()}',
                apiName,
              );
            }
          }
        } catch (_) {}

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Bienvenido! Has iniciado sesión correctamente."),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacementNamed(context, '/home');
      } else {
        String errorMsg = "";
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map<String, dynamic>) {
            errorMsg = (errorBody['detail'] ?? '').toString();
          }
        } catch (_) {}

        String displayMessage = "Correo no registrado o contraseña incorrecta.";
        if (response.statusCode == 401 ||
            response.statusCode == 404 ||
            errorMsg.toLowerCase().contains("not found") ||
            errorMsg.toLowerCase().contains("credential")) {
          displayMessage =
              "Este correo no está registrado. Por favor, regístrate primero.";
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      debugPrint("Error de conexión en login: $e");
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Iniciar Sesión",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textMainColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Ingresa tus datos para gestionar tus citas en ReservAll.",
                  style: TextStyle(fontSize: 14, color: textSecondaryColor),
                ),
                const SizedBox(height: 30),

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
                      return 'Ingresa tu correo';
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
                  validator: (value) => value == null || value.isEmpty
                      ? 'Ingresa tu contraseña'
                      : null,
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
                    onPressed: isLoading ? null : _login,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Entrar",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "¿No estás registrado?",
                      style: TextStyle(color: textSecondaryColor),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Regístrate aquí",
                        style: TextStyle(
                          color: secondaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
