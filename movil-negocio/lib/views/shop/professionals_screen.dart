import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:srln_negocio_app/views/shop/add_professional_scren.dart';
import '../../config/app_colors.dart';
import '../../controllers/profesional_controller.dart';

class ProfessionalsScreen extends StatefulWidget {
  final int shopId;
  const ProfessionalsScreen({super.key, required this.shopId});

  @override
  State<ProfessionalsScreen> createState() => _ProfessionalsScreenState();
}

class _ProfessionalsScreenState extends State<ProfessionalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfesionalController>().loadProfessionals(widget.shopId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profesionales'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),
      body: Consumer<ProfesionalController>(
        builder: (context, controller, child) {
          if (controller.isLoading) return const Center(child: CircularProgressIndicator());
          
          if (controller.professionals.isEmpty) {
            return const Center(child: Text('No hay profesionales registrados'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.professionals.length,
            itemBuilder: (context, index) {
              final p = controller.professionals[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(p.nombre[0].toUpperCase()),
                  ),
                  title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(p.especialidad ?? 'Sin especialidad'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('¿Eliminar?'),
                          content: Text('Se eliminará a ${p.nombre}'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: AppColors.error))),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await controller.deleteProfessional(widget.shopId, p.idProfesional);
                      }
                    },
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
            MaterialPageRoute(builder: (_) => AddProfessionalScreen(shopId: widget.shopId)),
          );
          if (result == true) {
            context.read<ProfesionalController>().loadProfessionals(widget.shopId);
          }
        },
        child: const Icon(Icons.add, color: AppColors.surface),
      ),
    );
  }
}