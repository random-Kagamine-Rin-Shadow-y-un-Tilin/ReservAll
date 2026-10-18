import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../controllers/shop_controller.dart';
import '../../models/shop_model.dart';
import '../widgets/loading_widget.dart';
import 'edit_contact_screen.dart';
import 'edit_schedule_screen.dart';
import 'edit_shop_screen.dart';
import 'add_contact_screen.dart';

class ShopDetailScreen extends StatefulWidget {
  final int shopId;

  const ShopDetailScreen({super.key, required this.shopId});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopController>().getShopById(widget.shopId);
    });
  }

  Future<void> _reload() async {
    await context.read<ShopController>().getShopById(widget.shopId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Negocio'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        actions: [
          //  Botón editar negocio
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar negocio',
            onPressed: () => _openEditShop(),
          ),
        ],
      ),
      body: Consumer<ShopController>(
        builder: (context, controller, child) {
          if (controller.isLoading) return const LoadingWidget();

          if (controller.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      controller.errorMessage!,
                      style: const TextStyle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _reload,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final shop = controller.currentShop;
          final profile = controller.fullProfile;

          if (shop == null) {
            return const Center(child: Text('No se encontró el negocio'));
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- Imagen ----------
                  _buildImage(shop),

                  const SizedBox(height: 24),

                  // ---------- Nombre ----------
                  Text(
                    shop.nombre,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ---------- Categoría ----------
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Categoría: ${shop.categoriaNegocio ?? 'Sin categoría'}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ---------- Descripción ----------
                  const Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      shop.descripcion,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ---------- Redes sociales ----------
                  _buildSectionHeader(
                    title: 'Redes de contacto',
                    icon: Icons.share,
                    onAdd: () => _openAddContact(),
                  ),
                  const SizedBox(height: 8),
                  _buildContactsList(profile?.contacts ?? []),

                  const SizedBox(height: 24),

                  // ---------- Horarios ----------
                  _buildSectionHeader(
                    title: 'Horarios de atención',
                    icon: Icons.schedule,
                    onAdd: () => _openAddSchedule(),
                  ),
                  const SizedBox(height: 8),
                  _buildSchedulesList(profile?.schedules ?? []),

                  const SizedBox(height: 24),

                  // ---------- Eliminar negocio ----------
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDelete(shop.id!),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                      ),
                      label: const Text(
                        'Eliminar negocio',
                        style: TextStyle(color: AppColors.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============ WIDGETS ============

  Widget _buildImage(Shop shop) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.surfaceLight,
      ),
      child: shop.imagenNegocio != null && shop.imagenNegocio!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                shop.imagenNegocio!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          : Center(
              child: Icon(
                Icons.store,
                size: 64,
                color: AppColors.textSecondary,
              ),
            ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required VoidCallback onAdd,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.add_circle, color: AppColors.primary),
          onPressed: onAdd,
          tooltip: 'Agregar',
        ),
      ],
    );
  }

  Widget _buildContactsList(List<ShopContact> contacts) {
    if (contacts.isEmpty) {
      return _buildEmptyState('Sin redes de contacto registradas');
    }
    return Column(
      children: contacts
          .map(
            (c) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  _getSocialIcon(c.nombreRed),
                  color: AppColors.primary,
                ),
                title: Text(
                  c.nombreRed,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  c.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                      onPressed: () => _openEditContact(c),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 20,
                        color: AppColors.error,
                      ),
                      onPressed: () => _confirmDeleteContact(c),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSchedulesList(List<ShopSchedule> schedules) {
    if (schedules.isEmpty) {
      return _buildEmptyState('Sin horarios registrados');
    }
    return Column(
      children: schedules
          .map(
            (s) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(
                  Icons.calendar_today,
                  color: AppColors.primary,
                ),
                title: Text(
                  s.dia[0].toUpperCase() + s.dia.substring(1),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${s.horaApertura.substring(0, 5)} - ${s.horaCierre.substring(0, 5)}'
                  '${s.horaDescanso != null ? " (Descanso: ${s.horaDescanso!.substring(0, 5)})" : ""}',
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
                      onPressed: () => _openEditSchedule(s),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 20,
                        color: AppColors.error,
                      ),
                      onPressed: () => _confirmDeleteSchedule(s),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildStatusCard(Shop shop) {
    final isActive = shop.estadoNegocio ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppColors.success.withOpacity(0.3)
              : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? AppColors.success : AppColors.error,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? Icons.check : Icons.close,
              color: AppColors.surface,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'Negocio activo' : 'Negocio inactivo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isActive ? AppColors.success : AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isActive
                      ? 'Los clientes pueden ver y reservar'
                      : 'Los clientes no pueden ver el negocio',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            activeColor: AppColors.success,
            onChanged: _toggleStatus,
          ),
        ],
      ),
    );
  }

  // ============ ACCIONES ============

  Future<void> _openEditShop() async {
    final shop = context.read<ShopController>().currentShop;
    if (shop == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditShopScreen(shop: shop)),
    );

    if (result == true) {
      await _reload();
    }
  }

  Future<void> _openAddContact() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddContactScreen(shopId: widget.shopId),
      ),
    );
    if (result == true) {
      await _reload();
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
    if (result == true) await _reload();
  }

  Future<void> _confirmDeleteContact(ShopContact contact) async {
    final ok = await _showConfirm(
      '¿Eliminar contacto?',
      'Se eliminará "${contact.nombreRed}".',
    );
    if (ok != true) return;

    final controller = context.read<ShopController>();
    final success = await controller.deleteContact(
      widget.shopId,
      contact.idSocial,
    );

    if (!mounted) return;
    if (success) {
      await _reload();
      _showSnack('✅ Contacto eliminado', AppColors.success);
    } else {
      _showSnack(controller.errorMessage ?? 'Error', AppColors.error);
    }
  }

  Future<void> _openAddSchedule() async {
    // TODO: pantalla de agregar horario
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Agregar horario próximamente')),
    );
  }

  Future<void> _openEditSchedule(ShopSchedule schedule) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditScheduleScreen(shopId: widget.shopId, schedule: schedule),
      ),
    );
    if (result == true) await _reload();
  }

  Future<void> _confirmDeleteSchedule(ShopSchedule schedule) async {
    final ok = await _showConfirm(
      '¿Eliminar horario?',
      'Se eliminará el horario del ${schedule.dia}.',
    );
    if (ok != true) return;

    final controller = context.read<ShopController>();
    final success = await controller.deleteSchedule(
      widget.shopId,
      schedule.idHorario,
    );

    if (!mounted) return;
    if (success) {
      await _reload();
      _showSnack('✅ Horario eliminado', AppColors.success);
    } else {
      _showSnack(controller.errorMessage ?? 'Error', AppColors.error);
    }
  }

  Future<void> _toggleStatus(bool value) async {
    final controller = context.read<ShopController>();
    final success = await controller.toggleShopStatus(widget.shopId, value);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? '✅ Negocio activado' : '⚠️ Negocio desactivado',
          ),
          backgroundColor: value ? AppColors.success : AppColors.warning,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Error al cambiar estado'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _confirmDelete(int shopId) async {
    final ok = await _showConfirm(
      '¿Eliminar negocio?',
      'El negocio será desactivado y los clientes no podrán verlo.',
    );
    if (ok != true) return;

    final controller = context.read<ShopController>();
    final success = await controller.deleteShop(shopId);

    if (!mounted) return;
    if (success) {
      _showSnack('✅ Negocio eliminado', AppColors.success);
      Navigator.pop(context);
    } else {
      _showSnack(controller.errorMessage ?? 'Error', AppColors.error);
    }
  }

  // ============ HELPERS ============

  Future<bool?> _showConfirm(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Confirmar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
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
}
