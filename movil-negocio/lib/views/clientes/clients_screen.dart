import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../controllers/client_controller.dart';
import '../../models/client_model.dart';
import 'client_detail_screen.dart';

class ClientsScreen extends StatefulWidget {
  final int shopId;
  const ClientsScreen({super.key, required this.shopId});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientController>().cargar(widget.shopId);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    await context.read<ClientController>().cargar(
          widget.shopId,
          search: _searchCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Clientes'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _buscar,
          ),
        ],
      ),
      body: Consumer<ClientController>(
        builder: (context, ctrl, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchCtrl,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _buscar(),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o correo',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        _buscar();
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '${ctrl.total} cliente${ctrl.total == 1 ? "" : "s"}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _buscar,
                  child: _buildBody(ctrl),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(ClientController ctrl) {
    if (ctrl.isLoading && ctrl.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (ctrl.errorMessage != null && ctrl.items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.error_outline, size: 56, color: AppColors.error),
          const SizedBox(height: 12),
          Center(
            child: Text(
              ctrl.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton(
              onPressed: _buscar,
              child: const Text('Reintentar'),
            ),
          ),
        ],
      );
    }
    if (ctrl.items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary),
          SizedBox(height: 12),
          Center(child: Text('Aún no hay clientes con reservas')),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: ctrl.items.length,
      itemBuilder: (context, i) {
        final c = ctrl.items[i];
        return _ClienteCard(
          cliente: c,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClientDetailScreen(
                shopId: widget.shopId,
                clienteId: c.clienteId,
                clienteNombre: c.nombre,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ClienteCard extends StatelessWidget {
  final ClienteResumen cliente;
  final VoidCallback onTap;
  const _ClienteCard({required this.cliente, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final inicial = cliente.nombre.isNotEmpty
        ? cliente.nombre[0].toUpperCase()
        : '?';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    foregroundColor: AppColors.primary,
                    child: Text(
                      inicial,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          cliente.correo,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _chip('${cliente.totalReservas} reservas'),
                  _chip('${cliente.completadas} completadas'),
                  if (cliente.activas > 0)
                    _chip('${cliente.activas} activas', AppColors.info),
                  if (cliente.canceladas > 0)
                    _chip('${cliente.canceladas} canceladas', AppColors.error),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.payments_outlined,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Gastado: \$${cliente.totalGastado.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (cliente.servicioFavorito != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Favorito: ${cliente.servicioFavorito}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, [Color? color]) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600),
      ),
    );
  }
}
