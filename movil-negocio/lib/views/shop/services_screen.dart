import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../controllers/service_controller.dart';
import 'add_service_screen.dart';
import 'edit_service_screen.dart';

class ServicesScreen extends StatefulWidget {
  final int shopId;
  const ServicesScreen({super.key, required this.shopId});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceController>().loadServices(widget.shopId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Servicios'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),
      body: Consumer<ServiceController>(
        builder: (context, controller, child) {
          if (controller.isLoading) return const Center(child: CircularProgressIndicator());
          
          if (controller.services.isEmpty) {
            return const Center(child: Text('No hay servicios registrados'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.services.length,
            itemBuilder: (context, index) {
              final s = controller.services[index];
              final isActive = s.estadoServicio;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                // Si está inactivo, la tarjeta se ve un poco más gris
                color: isActive ? Colors.white : Colors.grey.shade50,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.nombre, 
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            // Texto tachado si está inactivo
                            decoration: isActive ? null : TextDecoration.lineThrough,
                            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '\$${s.precio} - ${s.duracionMinutos} min',
                        style: TextStyle(color: isActive ? AppColors.textPrimary : AppColors.textSecondary),
                      ),
                      if (s.profesionales.isNotEmpty)
                        Text(
                          'Con: ${s.profesionales.map((e) => e.nombre).join(", ")}', 
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      const SizedBox(height: 4),
                      // Etiqueta visual de estado
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isActive ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isActive ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      //  SWITCH PARA ACTIVAR/DESACTIVAR (HU_19)
                      Switch(
                        value: isActive,
                        activeColor: AppColors.success,
                        onChanged: (val) async {
                          final success = await controller.toggleServiceStatus(widget.shopId, s.idServicio, val);
                          if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(controller.errorMessage ?? 'Error al cambiar estado'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                      ),
                      // Botón Editar
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.primary),
                        onPressed: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditServiceScreen(
                                shopId: widget.shopId,
                                service: s,
                              ),
                            ),
                          );
                          if (result == true) {
                            context.read<ServiceController>().loadServices(widget.shopId);
                          }
                        },
                      ),
                      // Botón Eliminar
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.error),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('¿Eliminar?'),
                              content: Text('Se eliminará ${s.nombre}'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: AppColors.error))),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await controller.deleteService(widget.shopId, s.idServicio);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => AddServiceScreen(shopId: widget.shopId)),
          );
          if (result == true) {
            context.read<ServiceController>().loadServices(widget.shopId);
          }
        },
        child: const Icon(Icons.add, color: AppColors.surface),
      ),
    );
  }
}