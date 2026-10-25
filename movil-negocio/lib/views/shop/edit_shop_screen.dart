import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_colors.dart';
import '../../controllers/shop_controller.dart';
import '../../models/shop_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_widget.dart';

class EditShopScreen extends StatefulWidget {
  final Shop shop;

  const EditShopScreen({super.key, required this.shop});

  @override
  State<EditShopScreen> createState() => _EditShopScreenState();
}

class _EditShopScreenState extends State<EditShopScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late int _selectedCategory;
  File? _newImageFile;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _categories = [
    {'id': 1, 'nombre': 'Barbería'},
    {'id': 2, 'nombre': 'Spa'},
    {'id': 3, 'nombre': 'Restaurante'},
    {'id': 4, 'nombre': 'Belleza'},
    {'id': 5, 'nombre': 'Otros'},
    {'id': 6, 'nombre': 'Gastronomía'},
    {'id': 7, 'nombre': 'Tecnología'},
    {'id': 8, 'nombre': 'Moda'},
    {'id': 9, 'nombre': 'Salud y Bienestar'},
    {'id': 10, 'nombre': 'Educación'},
    {'id': 11, 'nombre': 'Jardinería'},
    {'id': 12, 'nombre': 'Arte y Diseño'},
    {'id': 13, 'nombre': 'Automotriz'},
  ];

 @override
void initState() {
  super.initState();
  _nombreController = TextEditingController(text: widget.shop.nombre);
  _descripcionController = TextEditingController(text: widget.shop.descripcion);

  final catId = widget.shop.idCategoria;
  final exists = catId != null && _categories.any((c) => c['id'] == catId);
  
  _selectedCategory = exists ? catId : 5;
}

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() => _newImageFile = File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<ShopController>();
    String? imageUrl = widget.shop.imagenNegocio;

    // 1. Si hay imagen nueva, subirla primero
    if (_newImageFile != null) {
      try {
        // ⚠️ uploadShopImage DEBE devolver String? (la URL)
        final uploaded = await controller.uploadShopImage(
          _newImageFile!,
          widget.shop.id!,
        );

        if (uploaded == null || uploaded.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo subir la imagen'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        imageUrl = uploaded;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al subir imagen: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    }

    // 2. Editar el negocio
    final request = ShopEditRequest(
      nombre: _nombreController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      imagenNegocio: imageUrl,
      fkCategoria: _selectedCategory,
    );

    final success = await controller.editShop(widget.shop.id!, request);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Negocio actualizado'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Error al actualizar'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Negocio'),
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
                  // ---------- Imagen ----------
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: _buildImageContent(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Toca para cambiar la imagen',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // ---------- Nombre ----------
                  CustomTextField(
                    controller: _nombreController,
                    label: 'Nombre del negocio',
                    hint: 'Ej: Cafetería Delicias',
                    prefixIcon: Icons.store,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El nombre es obligatorio';
                      }
                      if (value.length < 3) {
                        return 'Mínimo 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ---------- Descripción ----------
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
                        return 'Mínimo 10 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ---------- Categoría ----------
                  DropdownButtonFormField<int>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Categoría',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                    ),
                    items: _categories.map((c) {
                      return DropdownMenuItem<int>(
                        value: c['id'] as int,
                        child: Text(c['nombre'] as String),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedCategory = v);
                    },
                    validator: (v) =>
                        v == null ? 'Selecciona una categoría' : null,
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: 'Guardar cambios',
                    onPressed: _handleSave,
                    isPrimary: true,
                    icon: Icons.save,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageContent() {
    // Si hay imagen nueva seleccionada
    if (_newImageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _newImageFile!,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      );
    }

    // Si el shop tiene imagen válida
    final img = widget.shop.imagenNegocio;
    if (img != null && img.isNotEmpty && img != 'null') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          img,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.add_photo_alternate,
          size: 48,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 8),
        const Text(
          'Agregar imagen',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}