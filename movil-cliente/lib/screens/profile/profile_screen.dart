import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = true;
  bool isEditing = false;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  String email = '';
  String _loadedName = '';

  static const String _profileEndpoint = "$baseUrl/profile/me";

  final Color primaryColor = const Color(0xFFE2725B);
  final Color secondaryColor = const Color(0xFF2A9D8F);
  final Color backgroundColor = const Color(0xFFFAF6F1);
  final Color surfaceColor = const Color(0xFFFFFFFF);
  final Color textMainColor = const Color(0xFF2B2118);
  final Color textSecondaryColor = const Color(0xFF7A7267);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionCookie = prefs.getString('session_cookie');

    final headers = <String, String>{
      "accept": "application/json",
      "Content-Type": "application/json",
      "x-api-key": apiKey,
    };

    if (sessionCookie != null && sessionCookie.isNotEmpty) {
      headers["Cookie"] = sessionCookie;
    }
    return headers;
  }

  String _extractErrorMessage(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final detail =
            decoded['detail'] ?? decoded['message'] ?? decoded['error'];
        if (detail != null && detail.toString().isNotEmpty) {
          return "${detail.toString()} (${response.statusCode})";
        }
      }
    } catch (_) {}
    return "$fallback (${response.statusCode})";
  }

  Future<void> _saveProfileLocally(
    SharedPreferences prefs,
    String cleanName,
    String cleanPhone,
    String userEmail,
  ) async {
    final normalizedEmail = userEmail.trim().toLowerCase();
    await prefs.setString('user_name', cleanName);
    await prefs.setString('nombre', cleanName);
    await prefs.setString('last_profile_name', cleanName);

    await prefs.setString('user_phone', cleanPhone);
    await prefs.setString('telefono', cleanPhone);
    await prefs.setString('last_profile_phone', cleanPhone);

    if (normalizedEmail.isNotEmpty) {
      await prefs.setString('profile_name_$normalizedEmail', cleanName);
      await prefs.setString('profile_phone_$normalizedEmail', cleanPhone);
      await prefs.setBool('profile_local_override_$normalizedEmail', true);
    }
  }

  Future<void> _fetchUserProfile() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final savedEmail =
        prefs.getString('user_email') ??
        prefs.getString('correo') ??
        'cliente@srln.com';
    final normalizedEmail = savedEmail.trim().toLowerCase();

    final hasLocalOverride =
        prefs.getBool('profile_local_override_$normalizedEmail') ?? false;

    final savedName =
        prefs.getString('profile_name_$normalizedEmail') ??
        prefs.getString('last_profile_name') ??
        prefs.getString('user_name') ??
        prefs.getString('nombre') ??
        '';

    final savedPhone =
        prefs.getString('profile_phone_$normalizedEmail') ??
        prefs.getString('last_profile_phone') ??
        prefs.getString('user_phone') ??
        prefs.getString('telefono') ??
        '';

    setState(() {
      _nameController.text = savedName;
      _phoneController.text = savedPhone;
      email = savedEmail;
      _loadedName = savedName;
    });

    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(_profileEndpoint),
        headers: headers,
      );

      debugPrint("GET perfil (${response.statusCode}): ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        Map<String, dynamic> data = <String, dynamic>{};
        if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is Map<String, dynamic>) {
            data = decoded['data'] as Map<String, dynamic>;
          } else if (decoded['user'] is Map<String, dynamic>) {
            data = decoded['user'] as Map<String, dynamic>;
          } else if (decoded['usuario'] is Map<String, dynamic>) {
            data = decoded['usuario'] as Map<String, dynamic>;
          } else {
            data = decoded;
          }
        }

        final apiName =
            (data['nombre'] ?? data['name'] ?? data['nombre_completo'])
                ?.toString()
                .trim();
        final apiPhone = (data['telefono'] ?? data['phone'])?.toString().trim();
        final apiEmail = (data['correo'] ?? data['email'])?.toString().trim();

        setState(() {
          if (!hasLocalOverride &&
              savedName.isEmpty &&
              apiName != null &&
              apiName.isNotEmpty) {
            _nameController.text = apiName;
            _loadedName = apiName;
          }
          if (savedPhone.isEmpty && apiPhone != null && apiPhone.isNotEmpty) {
            _phoneController.text = apiPhone;
          }
          if (apiEmail != null && apiEmail.isNotEmpty) {
            email = apiEmail;
          }
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error GET perfil: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final cleanName = _nameController.text.trim();
    final cleanPhone = _phoneController.text.trim();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() => isLoading = true);
    try {
      final nameChanged = cleanName != _loadedName;

      if (nameChanged) {
        final headers = await _getAuthHeaders();
        final response = await http.patch(
          Uri.parse(_profileEndpoint),
          headers: headers,
          body: jsonEncode({"nombre": cleanName}),
        );

        if (!mounted) return;

        if (response.statusCode == 404 || response.statusCode == 405) {
          await _saveProfileLocally(prefs, cleanName, cleanPhone, email);
          if (!mounted) return;
          setState(() {
            _nameController.text = cleanName;
            _phoneController.text = cleanPhone;
            _loadedName = cleanName;
            isEditing = false;
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Cambios guardados en el dispositivo (endpoint de perfil no disponible en el servidor).",
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        if (response.statusCode != 200 && response.statusCode != 204) {
          debugPrint(
            "PATCH perfil falló (${response.statusCode}): ${response.body}",
          );
          final errorMessage = _extractErrorMessage(
            response,
            "No se pudo actualizar el perfil",
          );
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: $errorMessage"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        _loadedName = cleanName;
      }

      await _saveProfileLocally(prefs, cleanName, cleanPhone, email);
      if (!mounted) return;

      setState(() {
        _nameController.text = cleanName;
        _phoneController.text = cleanPhone;
        isEditing = false;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nameChanged
                ? "Perfil actualizado correctamente."
                : "Datos guardados en el dispositivo.",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("Excepción PATCH perfil: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error de conexión al actualizar el perfil."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cerrar Sesión"),
        content: const Text(
          "¿Estás seguro de que deseas salir de la aplicación?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final cookie = prefs.getString('session_cookie');

              if (cookie != null && cookie.isNotEmpty) {
                try {
                  await http.post(
                    Uri.parse('$baseUrl/auth/logout'),
                    headers: {
                      'accept': 'application/json',
                      'x-api-key': apiKey,
                      'Cookie': cookie,
                    },
                  );
                } catch (_) {
                  // Si el servidor no responde, igualmente se limpia la sesión local.
                }
              }

              await prefs.remove('session_cookie');
              await prefs.remove('auth_token');
              await prefs.remove('token');
              await prefs.remove('user_name');
              await prefs.remove('nombre');
              await prefs.remove('user_phone');
              await prefs.remove('telefono');
              await prefs.remove('user_email');
              await prefs.remove('correo');

              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text("Salir", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Mi Perfil", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!isLoading)
            IconButton(
              icon: Icon(isEditing ? Icons.close : Icons.edit),
              onPressed: () => setState(() => isEditing = !isEditing),
            ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: secondaryColor.withValues(alpha: 0.2),
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      email,
                      style: TextStyle(fontSize: 14, color: textSecondaryColor),
                    ),
                    const SizedBox(height: 30),

                    TextFormField(
                      controller: _nameController,
                      enabled: isEditing,
                      decoration: InputDecoration(
                        labelText: "Nombre completo",
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: primaryColor,
                        ),
                        filled: true,
                        fillColor: surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es obligatorio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneController,
                      enabled: isEditing,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Número telefónico",
                        prefixIcon: Icon(
                          Icons.phone_outlined,
                          color: primaryColor,
                        ),
                        filled: true,
                        fillColor: surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    if (isEditing) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _updateProfile,
                          child: const Text(
                            "Guardar Cambios",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text(
                          "Cerrar Sesión",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _logout,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
