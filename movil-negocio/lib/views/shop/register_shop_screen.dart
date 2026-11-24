import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/shop_controller.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_widget.dart';
import 'my_shops_screen.dart';

class RegisterShopScreen extends StatefulWidget {
  const RegisterShopScreen({super.key});

  @override
  State<RegisterShopScreen> createState() => _RegisterShopScreenState();
}

class _RegisterShopScreenState extends State<RegisterShopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descripcionController = TextEditingController();
  
  int? _selectedCategory;
  File? _imageFile;
  final ImagePicker _imagePicker = ImagePicker();

  // Categorías predefinidas (sin endpoints)
  final List<Map<String, dynamic>> _categories = [
    {'id': 1, 'nombre': 'Barberia'},
    {'id': 2, 'nombre': 'Spa'},
    {'id': 3, 'nombre': 'Restaurante'},
    {'id': 4, 'nombre': 'Bellezar'},
    {'id': 5, 'nombre': 'Otros'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una categoría'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final shopController = context.read<ShopController>();
    final success = await shopController.registerShop(
      nombre: _nameController.text,
      descripcion: _descripcionController.text,
      categoriaNegocio: _selectedCategory!,
      imageFile: _imageFile,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Negocio registrado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyShopsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Negocio'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ShopController>(
        builder: (context, shopController, child) {
          if (shopController.isLoading) {
            return const LoadingWidget();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mensaje de error
                  if (shopController.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              shopController.errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: shopController.clearError,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Imagen del negocio
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _imageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _imageFile!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Toca para seleccionar imagen',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nombre
                  CustomTextField(
                    controller: _nameController,
                    label: 'Nombre del negocio',
                    hint: 'Ej: Cafetería Delicias',
                    prefixIcon: Icons.store,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El nombre es obligatorio';
                      }
                      if (value.length < 3) {
                        return 'El nombre debe tener al menos 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Descripción
                  CustomTextField(
                    controller: _descripcionController,
                    label: 'Descripción',
                    hint: 'Describe tu negocio...',
                    prefixIcon: Icons.description,
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La descripción es obligatoria';
                      }
                      if (value.length < 10) {
                        return 'La descripción debe tener al menos 10 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Categoría
                  DropdownButtonFormField<int>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.category),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem<int>(
                        value: category['id'],
                        child: Text(category['nombre']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecciona una categoría';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: 'Registrar Negocio',
                    onPressed: _handleRegister,
                    isPrimary: true,
                    icon: Icons.add_business,
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