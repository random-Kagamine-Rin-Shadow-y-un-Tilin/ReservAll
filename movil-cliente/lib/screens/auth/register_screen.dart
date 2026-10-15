import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool cargando = false;
  bool mostrarPassword = false;
  bool mostrarConfirm = false;

  void _mostrarAlerta(String mensaje, {bool exito = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: exito ? const Color(0xFF52B788) : const Color(0xFFE63946),
      ),
    );
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => cargando = true);

    try {
      final response = await http.post(
        Uri.parse("http://localhost:8000/api/v1/auth/register"),
        headers: {
          "accept": "application/json",
          "Content-Type": "application/json",
          "x-api-key": "25c78a3206e58231c87783cdbc8359584767c6718f1fcaedb9a406c5a6971e4c",
        },
        body: jsonEncode({
          "nombre": _nombreController.text,
          "correo": _correoController.text,
          "telefono": _telefonoController.text.isEmpty ? null : _telefonoController.text,
          "password": _passwordController.text,
          "rol": "cliente", 
        }),
      );

      setState(() => cargando = false);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final userId = data['id'].toString();
        final nombre = data['nombre'] ?? '';

        _mostrarAlerta("Usuario $nombre (ID: $userId) registrado con éxito", exito: true);
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        final error = jsonDecode(response.body);
        String mensajeError = "Error al registrar el usuario";

        if (error is Map) {
          if (error.containsKey('detail')) {
            final detail = error['detail'];
            mensajeError = detail is String ? detail : (detail[0]['msg'] ?? 'Error desconocido');
          }
        }

        if (response.statusCode == 400 || response.statusCode == 422) {
          mensajeError = "Este correo electrónico ya se encuentra registrado. Utilice otro.";
        }

        _mostrarAlerta(mensajeError, exito: false);
      }
    } catch (e) {
      setState(() => cargando = false);
      _mostrarAlerta("Error inesperado: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F1),
      appBar: AppBar(
        title: const Text("Crear cuenta", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFFE2725B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreController,
                style: const TextStyle(color: Color(0xFF2B2118)),
                decoration: const InputDecoration(
                  labelText: "Nombre completo",
                  labelStyle: TextStyle(color: Color(0xFF7A7267)),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF7A7267), width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE2725B), width: 2),
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Ingrese su nombre" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _correoController,
                style: const TextStyle(color: Color(0xFF2B2118)),
                decoration: const InputDecoration(
                  labelText: "Correo electrónico",
                  labelStyle: TextStyle(color: Color(0xFF7A7267)),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF7A7267), width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE2725B), width: 2),
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Ingrese su correo" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Color(0xFF2B2118)),
                decoration: const InputDecoration(
                  labelText: "Número de teléfono (Opcional)",
                  labelStyle: TextStyle(color: Color(0xFF7A7267)),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF7A7267), width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE2725B), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                style: const TextStyle(color: Color(0xFF2B2118)),
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  labelStyle: const TextStyle(color: Color(0xFF7A7267)),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF7A7267), width: 0.5),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE2725B), width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      mostrarPassword ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFFE2725B),
                    ),
                    onPressed: () {
                      setState(() {
                        mostrarPassword = !mostrarPassword;
                      });
                    },
                  ),
                ),
                obscureText: !mostrarPassword,
                validator: (value) => value!.length < 8
                    ? "La contraseña debe tener al menos 8 caracteres"
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmController,
                style: const TextStyle(color: Color(0xFF2B2118)),
                decoration: InputDecoration(
                  labelText: "Confirmar contraseña",
                  labelStyle: const TextStyle(color: Color(0xFF7A7267)),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF7A7267), width: 0.5),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE2725B), width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      mostrarConfirm ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFFE2725B),
                    ),
                    onPressed: () {
                      setState(() {
                        mostrarConfirm = !mostrarConfirm;
                      });
                    },
                  ),
                ),
                obscureText: !mostrarConfirm,
                validator: (value) => value != _passwordController.text
                    ? "Las contraseñas no coinciden"
                    : null,
              ),
              const SizedBox(height: 24),
              cargando
                  ? const CircularProgressIndicator(
                      color: Color(0xFFE2725B),
                    )
                  : ElevatedButton(
                      onPressed: _registrar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE2725B),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Registrarse",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}