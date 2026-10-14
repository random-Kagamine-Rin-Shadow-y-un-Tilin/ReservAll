import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/shop_controller.dart';
import '../../models/shop_contact_model.dart';
import '../widgets/loading_widget.dart';
import 'edit_contact_screen.dart';

class ShopDetailScreen extends StatefulWidget {
  final int shopId;

  const ShopDetailScreen({super.key, required this.shopId});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  List<ShopContact> _contacts = [];
  bool _loadingContacts = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopController>().getShopById(widget.shopId);
      _loadContacts();
    });
  }

  Future<void> _loadContacts() async {
    setState(() => _loadingContacts = true);
    try {
      final controller = context.read<ShopController>();
      final contacts = await controller.shopService.getContacts(widget.shopId);
      setState(() => _contacts = contacts);
    } catch (e) {
      // Silencioso
    } finally {
      setState(() => _loadingContacts = false);
    }
  }

  Future<void> _openEditContact(ShopContact contact) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditContactScreen(shopId: widget.shopId, contact: contact),
      ),
    );
    if (result == true) {
      await _loadContacts();
    }
  }

  Future<void> _confirmDeleteContact(ShopContact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar contacto?'),
        content: Text(
          'Se eliminará la red "${contact.nombreRed}" de tu negocio.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final controller = context.read<ShopController>();
      final success = await controller.deleteContact(
        widget.shopId,
        contact.idSocial,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Contacto eliminado'),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadContacts();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage ?? 'Error al eliminar'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  IconData _getSocialIcon(String name) {
    switch (name.toLowerCase()) {
      case 'facebook':
        return Icons.facebook;
      case 'instagram':
        return Icons.camera_alt;
      case 'whatsapp':
        return Icons.chat;
      case 'telefono':
        return Icons.phone;
      case 'tiktok':
        return Icons.music_note;
      case 'x':
        return Icons.alternate_email;
      case 'sitio_web':
        return Icons.language;
      default:
        return Icons.link;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Negocio'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ShopController>(
        builder: (context, shopController, child) {
          if (shopController.isLoading) {
            return const LoadingWidget();
          }

          if (shopController.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    shopController.errorMessage!,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      shopController.getShopById(widget.shopId);
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final shop = shopController.currentShop;
          if (shop == null) {
            return const Center(child: Text('No se encontró el negocio'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade200,
                  ),
                  child:
                      shop.imagenNegocio != null &&
                          shop.imagenNegocio!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            shop.imagenNegocio!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Error al cargar la imagen',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.store,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sin imagen',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                // Nombre
                Text(
                  shop.nombre,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Categoría
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Categoría: ${_getCategoryName(shop.categoriaNegocio)}',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Descripción
                const Text(
                  'Descripción',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    shop.descripcion,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),

                // ============ HU_12: REDES DE CONTACTO ============
                const Text(
                  'Redes de contacto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                if (_loadingContacts)
                  const Center(child: CircularProgressIndicator())
                else if (_contacts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Text(
                        'Sin contactos registrados',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ..._contacts.map(
                    (contact) => Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: Icon(
                          _getSocialIcon(contact.nombreRed),
                          color: AppColors.primary,
                        ),
                        title: Text(
                          contact.nombreRed,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          contact.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              onPressed: () => _openEditContact(contact),
                              tooltip: 'Editar',
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 20,
                                color: AppColors.error,
                              ),
                              onPressed: () => _confirmDeleteContact(contact),
                              tooltip: 'Eliminar',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Información adicional
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        'ID del Negocio',
                        shop.id?.toString() ?? 'N/A',
                      ),
                      const Divider(),
                      _buildInfoRow(
                        'Estado',
                        shop.estadoNegocio == true ? 'Activo' : 'Inactivo',
                      ),
                      const Divider(),
                      _buildInfoRow(
                        'Fecha de creación',
                        shop.fechaCreacion?.split('T').first ?? 'N/A',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(int categoryId) {
    const categories = {
      1: 'Barberia',
      2: 'Spa',
      3: 'Restaurante',
      4: 'Bellezar',
      5: 'Otros',
    };
    return categories[categoryId] ?? 'Sin categoría';
  }
}
