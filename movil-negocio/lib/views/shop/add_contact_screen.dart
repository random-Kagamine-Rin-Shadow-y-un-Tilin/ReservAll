import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../controllers/shop_controller.dart';
import '../../models/shop_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_widget.dart';

class AddContactScreen extends StatefulWidget {
  final int shopId;

  const AddContactScreen({super.key, required this.shopId});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  String _selectedRed = 'facebook';

  // Debe coincidir con el enum SocialMedia del backend
  final List<Map<String, dynamic>> _socialNetworks = [
    {'id': 'facebook', 'nombre': 'Facebook', 'icon': Icons.facebook},
    {'id': 'instagram', 'nombre': 'Instagram', 'icon': Icons.camera_alt},
    {'id': 'whatsapp', 'nombre': 'WhatsApp', 'icon': Icons.chat},
    {'id': 'telefono', 'nombre': 'Teléfono', 'icon': Icons.phone},
    {'id': 'tiktok', 'nombre': 'TikTok', 'icon': Icons.music_note},
    {'id': 'x', 'nombre': 'X (Twitter)', 'icon': Icons.alternate_email},
    {'id': 'sitio_web', 'nombre': 'Sitio Web', 'icon': Icons.language},
  ];

  // Hints por red para guiar al usuario
  final Map<String, String> _hints = {
    'facebook': 'https://facebook.com/tu-negocio',
    'instagram': 'https://instagram.com/tu-negocio',
    'whatsapp': 'https://wa.me/521234567890',
    'telefono': 'tel:+521234567890',
    'tiktok': 'https://tiktok.com/@tu-negocio',
    'x': 'https://x.com/tu-negocio',
    'sitio_web': 'https://tu-sitio.com',
  };

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<ShopController>();
    final request = ShopContactCreateRequest(
      nombreRed: _selectedRed,
      url: _urlController.text.trim(),
    );

    final success = await controller.addContact(widget.shopId, request);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Contacto agregado'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Error al agregar'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  IconData _iconFor(String id) {
    final found = _socialNetworks.firstWhere(
      (s) => s['id'] == id,
      orElse: () => {'icon': Icons.link},
    );
    return found['icon'] as IconData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Contacto'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),
      body: Consumer<ShopController>(
        builder: (context, controller, child) {
          if (controller.isLoading) return const LoadingWidget();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---------- Icono de la red seleccionada ----------
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _iconFor(_selectedRed),
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Nueva red de contacto',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ---------- Tipo de red ----------
                  DropdownButtonFormField<String>(
                    value: _selectedRed,
                    decoration: InputDecoration(
                      labelText: 'Tipo de red',
                      prefixIcon: const Icon(Icons.share),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                    ),
                    items: _socialNetworks.map((s) {
                      return DropdownMenuItem<String>(
                        value: s['id'] as String,
                        child: Row(
                          children: [
                            Icon(s['icon'] as IconData, size: 20),
                            const SizedBox(width: 8),
                            Text(s['nombre'] as String),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _selectedRed = v;
                          _urlController.clear();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // ---------- URL / valor ----------
                  CustomTextField(
                    controller: _urlController,
                    label: _selectedRed == 'telefono'
                        ? 'Número de teléfono'
                        : 'URL o enlace',
                    hint: _hints[_selectedRed] ?? '',
                    prefixIcon: Icons.link,
                    keyboardType: _selectedRed == 'telefono'
                        ? TextInputType.phone
                        : TextInputType.url,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Este campo es obligatorio';
                      }

                      // Validación específica por red
                      if (_selectedRed == 'telefono') {
                        // Teléfono: al menos 10 dígitos (con o sin +)
                        final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                        if (digits.length < 10) {
                          return 'Ingresa al menos 10 dígitos';
                        }
                        return null;
                      }

                      // URL: debe empezar con http:// o https://
                      if (!value.startsWith('http://') &&
                          !value.startsWith('https://')) {
                        return 'Debe comenzar con http:// o https://';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // ---------- Info ----------
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.accent.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Solo puedes tener una red de cada tipo. '
                            'Si ya tienes Facebook, elige otra red.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: 'Agregar contacto',
                    onPressed: _handleSave,
                    isPrimary: true,
                    icon: Icons.add,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
