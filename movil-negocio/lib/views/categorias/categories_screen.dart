import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../controllers/category_controller.dart';
import '../../models/category_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_widget.dart';

/// HU_14: administración de categorías (solo accesible con rol `admin`).
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryController>().loadAdminCategories();
    });
  }

  Future<void> _openForm({Category? category}) async {
    final input = await showDialog<CategoryInput>(
      context: context,
      builder: (_) => _CategoryFormDialog(category: category),
    );
    if (input == null || !mounted) return;

    final controller = context.read<CategoryController>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = category == null
        ? (await controller.createCategory(input)) != null
        : await controller.updateCategory(category.idCategoria, input);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (category == null
                    ? 'Categoría creada'
                    : 'Categoría actualizada')
              : (controller.errorMessage ?? 'No se pudo guardar la categoría'),
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _delete(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text(
          '¿Eliminar "${category.nombreCategoria}"? '
          'Si tiene negocios asociados, el backend no permitirá borrarla.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final controller = context.read<CategoryController>();
    final ok = await controller.deleteCategory(category.idCategoria);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Categoría eliminada'
              : (controller.errorMessage ?? 'No se pudo eliminar la categoría'),
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar categorías'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<CategoryController>().loadAdminCategories(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openForm,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: Consumer<CategoryController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.adminCategories.isEmpty) {
            return const LoadingWidget();
          }
          if (controller.adminCategories.isEmpty) {
            return const Center(child: Text('No hay categorías registradas'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.adminCategories.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final category = controller.adminCategories[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: category.estado
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.error.withValues(alpha: 0.15),
                  child: Icon(
                    category.estado ? Icons.check : Icons.block,
                    color: category.estado
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
                title: Text(category.nombreCategoria),
                subtitle: Text(
                  '${category.negociosCount} negocio(s)'
                  '${category.descripcion == null || category.descripcion!.isEmpty ? '' : ' · ${category.descripcion}'}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _openForm(category: category),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(category),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryFormDialog extends StatefulWidget {
  final Category? category;

  const _CategoryFormDialog({this.category});

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late bool _estado;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.category?.nombreCategoria ?? '',
    );
    _descripcionController = TextEditingController(
      text: widget.category?.descripcion ?? '',
    );
    _estado = widget.category?.estado ?? true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // El estado se guarda en el padre para reutilizarlo tras cerrar el dialog.
    final input = CategoryInput(
      nombreCategoria: _nombreController.text,
      descripcion: _descripcionController.text,
      estado: _estado,
    );
    Navigator.pop(context, input);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.category == null ? 'Nueva categoría' : 'Editar categoría',
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 2 || text.length > 100) {
                    return 'Entre 2 y 100 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) =>
                    (value?.length ?? 0) > 500 ? 'Máximo 500 caracteres' : null,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Categoría activa'),
                value: _estado,
                onChanged: (value) => setState(() => _estado = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        CustomButton(text: 'Guardar', onPressed: _submit),
      ],
    );
  }
}
