import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/shop_controller.dart';
import '../auth/login_screen.dart';
import '../shop/register_shop_screen.dart';
import '../shop/shop_detail_screen.dart';

// Controlador para manejar el índice seleccionado
class NavigationController extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void setIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NavigationController _navController = NavigationController();

  @override
  void dispose() {
    _navController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => _navController,
      child: const HomeScreenContent(),
    );
  }
}

class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final navController = context.watch<NavigationController>();
    final selectedIndex = navController.selectedIndex;

    final List<Widget> _pages = [
      const HomeTab(),
      const ShopsTab(),
      const ReservationsTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      body: _pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          navController.setIndex(index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Negocios'),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available),
            label: 'Reservas',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

// ============ TAB INICIO ============
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final shopController = context.watch<ShopController>();
    final navController = context.watch<NavigationController>();
    final user = authController.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Negocio'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await authController.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => shopController.getMyShops(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del dueño
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.2),
                        child: Text(
                          user?.nombre.isNotEmpty == true
                              ? user!.nombre[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.nombre ?? 'Usuario',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.correo ?? 'Sin correo',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Dueño de negocio',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Mis Negocios
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mis Negocios',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      navController.setIndex(1); // 👈 Cambiar a tab Negocios
                    },
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('Ver todos'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Lista de negocios
              Consumer<ShopController>(
                builder: (context, controller, child) {
                  if (controller.isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (controller.myShops.isEmpty) {
                    return _buildEmptyShops(context);
                  }

                  final shopsToShow = controller.myShops.take(2).toList();

                  return Column(
                    children: [
                      ...shopsToShow.map(
                        (shop) => _buildShopCard(context, shop),
                      ),
                      if (controller.myShops.length > 2)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: TextButton(
                            onPressed: () {
                              navController.setIndex(
                                1,
                              ); // 👈 Cambiar a tab Negocios
                            },
                            child: Text(
                              'Ver ${controller.myShops.length - 2} negocios más',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Acceso rápido
              const Text(
                'Acceso rápido',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildQuickAccessCard(
                    context,
                    icon: Icons.store,
                    label: 'Mis Negocios',
                    color: Colors.blue,
                    onTap: () {
                      navController.setIndex(1); // 👈 Cambiar a tab Negocios
                    },
                  ),
                  _buildQuickAccessCard(
                    context,
                    icon: Icons.add_business,
                    label: 'Registrar\nNegocio',
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterShopScreen(),
                        ),
                      ).then((_) {
                        context.read<ShopController>().getMyShops();
                      });
                    },
                  ),
                  _buildQuickAccessCard(
                    context,
                    icon: Icons.event_available,
                    label: 'Reservas',
                    color: Colors.orange,
                    onTap: () {
                      navController.setIndex(2); // 👈 Cambiar a tab Reservas
                    },
                  ),
                  _buildQuickAccessCard(
                    context,
                    icon: Icons.list_alt,
                    label: 'Servicios',
                    color: Colors.purple,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Próximamente: Módulo de Servicios'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Últimas reservas
              const Text(
                'Próximas reservas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'No hay reservas próximas',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyShops(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.store_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Aún no tienes negocios',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Registra tu primer negocio',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterShopScreen()),
                ).then((_) {
                  context.read<ShopController>().getMyShops();
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Registrar Negocio'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopCard(BuildContext context, shop) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: shop.imagenNegocio != null && shop.imagenNegocio!.isNotEmpty
              ? Image.network(
                  shop.imagenNegocio!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.store,
                        size: 30,
                        color: Colors.grey.shade400,
                      ),
                    );
                  },
                )
              : Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey.shade200,
                  child: Icon(
                    Icons.store,
                    size: 30,
                    color: Colors.grey.shade400,
                  ),
                ),
        ),
        title: Text(
          shop.nombre,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          shop.descripcion,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShopDetailScreen(shopId: shop.id!),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickAccessCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ TAB NEGOCIOS ============
class ShopsTab extends StatelessWidget {
  const ShopsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final shopController = context.watch<ShopController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Negocios'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterShopScreen()),
              ).then((_) {
                shopController.getMyShops();
              });
            },
            tooltip: 'Registrar Negocio',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              shopController.getMyShops();
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Consumer<ShopController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null) {
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
                    controller.errorMessage!,
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      controller.getMyShops();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (controller.myShops.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storefront, size: 80, color: Colors.grey.shade300),
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
                    style: TextStyle(color: Colors.grey.shade500),
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
                        controller.getMyShops();
                      });
                    },
                    icon: const Icon(Icons.add_business),
                    label: const Text('Registrar Negocio'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.getMyShops(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.myShops.length,
              itemBuilder: (context, index) {
                final shop = controller.myShops[index];
                return _buildShopCard(context, shop);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildShopCard(BuildContext context, shop) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    shop.imagenNegocio != null && shop.imagenNegocio!.isNotEmpty
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

// ============ TAB RESERVAS ============
class ReservationsTab extends StatelessWidget {
  const ReservationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Módulo de Reservas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Próximamente disponible',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ TAB PERFIL ============
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final user = authController.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Foto de perfil
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.2),
                    child: Text(
                      user?.nombre.isNotEmpty == true
                          ? user!.nombre[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.nombre ?? 'Usuario',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dueño de negocio',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Estadísticas rápidas
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Negocios',
                    value: '0',
                    icon: Icons.store,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Reservas',
                    value: '0',
                    icon: Icons.event_available,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Servicios',
                    value: '0',
                    icon: Icons.list_alt,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Información del usuario
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildProfileItem(
                      icon: Icons.person,
                      label: 'Nombre',
                      value: user?.nombre ?? 'Sin nombre',
                    ),
                    const Divider(),
                    _buildProfileItem(
                      icon: Icons.email,
                      label: 'Correo',
                      value: user?.correo ?? 'Sin correo',
                    ),
                    const Divider(),
                    _buildProfileItem(
                      icon: Icons.verified_user,
                      label: 'Rol',
                      value: 'Dueño de negocio',
                    ),
                    const Divider(),
                    _buildProfileItem(
                      icon: Icons.calendar_today,
                      label: 'Fecha de registro',
                      value: 'Sin información',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botón cerrar sesión
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await authController.logout();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                },
                icon: const Icon(Icons.exit_to_app, color: Colors.red),
                label: const Text(
                  'Cerrar sesión',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
