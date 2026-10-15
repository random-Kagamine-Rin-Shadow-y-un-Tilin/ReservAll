import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../controllers/shop_controller.dart';
import '../../models/shop_model.dart';
import 'register_shop_screen.dart';
import 'shop_detail_screen.dart';

class MyShopsScreen extends StatefulWidget {
  const MyShopsScreen({super.key});

  @override
  State<MyShopsScreen> createState() => _MyShopsScreenState();
}

class _MyShopsScreenState extends State<MyShopsScreen> {
  String _filter = 'all'; // all | active | inactive

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopController>().getMyShops();
    });
  }

  List<Shop> _applyFilter(List<Shop> shops) {
    switch (_filter) {
      case 'active':
        return shops.where((s) => s.estadoNegocio == true).toList();
      case 'inactive':
        return shops.where((s) => s.estadoNegocio != true).toList();
      default:
        return shops;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Negocios'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ShopController>().getMyShops();
            },
          ),
        ],
      ),
      body: Consumer<ShopController>(
        builder: (context, shopController, child) {
          if (shopController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (shopController.errorMessage != null) {
            return _buildErrorState(shopController);
          }

          if (shopController.myShops.isEmpty) {
            return _buildEmptyState();
          }

          final filtered = _applyFilter(shopController.myShops);

          return Column(
            children: [
              _buildFilterChips(shopController.myShops),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => shopController.getMyShops(),
                  child: filtered.isEmpty
                      ? _buildFilterEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return _buildShopCard(
                              context,
                              filtered[index],
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RegisterShopScreen(),
            ),
          ).then((_) {
            context.read<ShopController>().getMyShops();
          });
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Negocio'),
      ),
    );
  }

  // ============ ESTADOS ============

  Widget _buildErrorState(ShopController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage!,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.getMyShops(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No tienes negocios registrados',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Registra tu primer negocio',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterShopScreen(),
                  ),
                ).then((_) {
                  context.read<ShopController>().getMyShops();
                });
              },
              icon: const Icon(Icons.add_business),
              label: const Text('Registrar Negocio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.filter_alt_off,
                size: 64,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _filter == 'active'
                    ? 'No tienes negocios activos'
                    : 'No tienes negocios inactivos',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============ FILTROS ============

  Widget _buildFilterChips(List<Shop> shops) {
    final total = shops.length;
    final active = shops.where((s) => s.estadoNegocio == true).length;
    final inactive = total - active;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _filterChip('Todos ($total)', 'all'),
          const SizedBox(width: 8),
          _filterChip('Activos ($active)', 'active'),
          const SizedBox(width: 8),
          _filterChip('Inactivos ($inactive)', 'inactive'),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: selected ? AppColors.surface : AppColors.textPrimary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceLight,
      onSelected: (_) => setState(() => _filter = value),
    );
  }

  // ============ TARJETA DE NEGOCIO ============

  Widget _buildShopCard(BuildContext context, Shop shop) {
    final isActive = shop.estadoNegocio ?? false;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShopDetailScreen(shopId: shop.id!),
            ),
          ).then((_) {
            context.read<ShopController>().getMyShops();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // ---------- Imagen + indicador ----------
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    _buildShopImage(shop, 80),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.success
                              : AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          isActive ? Icons.check : Icons.close,
                          size: 12,
                          color: AppColors.surface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // ---------- Info ----------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shop.descripcion,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // ---------- Categoría + Estado ----------
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getCategoryName(shop.categoriaNegocio),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.success.withOpacity(0.15)
                                : AppColors.error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isActive ? 'Activo' : 'Inactivo',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ---------- Flecha ----------
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopImage(Shop shop, double size) {
    final img = shop.imagenNegocio;
    if (img != null && img.isNotEmpty && img != 'null') {
      return Image.network(
        img,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: size,
            height: size,
            color: AppColors.surfaceLight,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildImagePlaceholder(size),
      );
    }
    return _buildImagePlaceholder(size);
  }

  Widget _buildImagePlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      color: AppColors.surfaceLight,
      child: Icon(
        Icons.store,
        size: size * 0.5,
        color: AppColors.textSecondary,
      ),
    );
  }

  // ============ HELPER UNIVERSAL ============

  String _getCategoryName(dynamic categoria) {
    if (categoria == null) return 'Sin categoría';

    // Si ya viene como String (nombre)
    if (categoria is String) {
      return categoria.isEmpty ? 'Sin categoría' : categoria;
    }

    // Si viene como int (ID)
    if (categoria is int) {
      const categories = {
        1: 'Barbería',
        2: 'Spa',
        3: 'Restaurante',
        4: 'Belleza',
        5: 'Otros',
        6: 'Gastronomía',
        7: 'Tecnología',
        8: 'Moda',
        9: 'Salud y Bienestar',
        10: 'Educación',
        11: 'Jardinería',
        12: 'Arte y Diseño',
        13: 'Automotriz',
      };
      return categories[categoria] ?? 'Sin categoría';
    }

    return categoria.toString();
  }
}