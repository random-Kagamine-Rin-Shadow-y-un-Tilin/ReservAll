import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/shop_controller.dart';
import '../../models/shop_model.dart';
import 'register_shop_screen.dart';
import 'shop_detail_screen.dart';
import '../widgets/loading_widget.dart';

class MyShopsScreen extends StatefulWidget {
  const MyShopsScreen({super.key});

  @override
  State<MyShopsScreen> createState() => _MyShopsScreenState();
}

class _MyShopsScreenState extends State<MyShopsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopController>().getMyShops();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Negocios'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
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
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      shopController.getMyShops();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (shopController.myShops.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.storefront,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes negocios registrados',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Registra tu primer negocio',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterShopScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_business),
                    label: const Text('Registrar Negocio'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => shopController.getMyShops(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: shopController.myShops.length,
              itemBuilder: (context, index) {
                final shop = shopController.myShops[index];
                return _buildShopCard(context, shop);
              },
            ),
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
            // Recargar al volver
            context.read<ShopController>().getMyShops();
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Negocio'),
      ),
    );
  }

  Widget _buildShopCard(BuildContext context, Shop shop) {
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
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Imagen
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: shop.imagenNegocio != null && shop.imagenNegocio!.isNotEmpty
                    ? Image.network(
                        shop.imagenNegocio!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.store,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.store,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shop.descripcion,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Categoría: ${_getCategoryName(shop.categoriaNegocio)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryName(String? categoria) {
  if (categoria == null || categoria.isEmpty) return 'Sin categoría';
  return categoria;
}
}