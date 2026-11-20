import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/shop.dart';
import '../services/location_service.dart';

class NearbyShopsScreen extends StatefulWidget {
 
  final Future<List<Shop>> Function() fetchShops;

  final void Function(Shop shop)? onShopTap;

  const NearbyShopsScreen({
    super.key,
    required this.fetchShops,
    this.onShopTap,
  });

  @override
  State<NearbyShopsScreen> createState() => _NearbyShopsScreenState();
}

class _NearbyShopsScreenState extends State<NearbyShopsScreen> {
  static const List<double> _radiusOptionsKm = [1, 3, 5, 10, 15];

  Position? _userPosition;
  List<Shop> _allShops = const [];
  List<Shop> _nearbyShops = const [];

  double _selectedRadiusKm = 5;
  bool _isLoading = true;
  String? _errorMessage;
  bool _openSettingsSuggested = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool refreshShops = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _openSettingsSuggested = false;
    });

    final locationResult = await LocationService.getCurrentLocation();
    if (!mounted) return;

    if (!locationResult.isSuccess || locationResult.position == null) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            locationResult.errorMessage ?? 'No se pudo obtener tu ubicación.';
        _openSettingsSuggested = locationResult.openSettingsSuggested;
      });
      return;
    }

    try {
      final shops = refreshShops || _allShops.isEmpty
          ? await widget.fetchShops()
          : _allShops;
      if (!mounted) return;

      _userPosition = locationResult.position;
      _allShops = shops;
      _recalculateNearbyShops();

      setState(() {
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'No se pudieron cargar los negocios disponibles.';
      });
    }
  }

  void _recalculateNearbyShops() {
    final pos = _userPosition;
    if (pos == null) {
      _nearbyShops = const [];
      return;
    }

    _nearbyShops = LocationService.attachDistancesAndSort(
      _allShops,
      userLat: pos.latitude,
      userLng: pos.longitude,
      maxRadiusKm: _selectedRadiusKm,
    );
  }

  void _onRadiusChanged(double radiusKm) {
    setState(() {
      _selectedRadiusKm = radiusKm;
      _recalculateNearbyShops();
    });
  }

  String _formatDistance(double? distanceKm) {
    if (distanceKm == null) return 'Distancia no disponible';
    if (distanceKm < 1.0) {
      final meters = (distanceKm * 1000).round();
      return 'Aprox. $meters m';
    }
    return 'Aprox. ${distanceKm.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Negocios cercanos'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : () => _loadData(refreshShops: true),
            tooltip: 'Actualizar ubicación y negocios',
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRadiusSelector(),
          const Divider(height: 1),
          Expanded(child: _buildBodyContent()),
        ],
      ),
    );
  }

  Widget _buildRadiusSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Radio de búsqueda: ${_selectedRadiusKm.toStringAsFixed(0)} km',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _radiusOptionsKm.map((radius) {
                final isSelected = _selectedRadiusKm == radius;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${radius.toStringAsFixed(0)} km'),
                    selected: isSelected,
                    onSelected: (_) => _onRadiusChanged(radius),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Obteniendo ubicación y negocios cercanos...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () => _loadData(refreshShops: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                  if (_openSettingsSuggested)
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Geolocator.openAppSettings();
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('Abrir ajustes'),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_nearbyShops.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No se encontraron negocios dentro de ${_selectedRadiusKm.toStringAsFixed(0)} km.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _nearbyShops.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final shop = _nearbyShops[index];
        final minutes = shop.distanciaKm != null
            ? LocationService.estimateMinutes(shop.distanciaKm!, walking: true)
            : null;

        return Card(
          child: ListTile(
            title: Text(shop.nombre),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shop.categoriaNegocio),
                if (shop.direccion != null && shop.direccion!.isNotEmpty)
                  Text(
                    shop.direccion!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDistance(shop.distanciaKm),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                if (minutes != null)
                  Text(
                    '~$minutes min a pie',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            onTap: widget.onShopTap != null ? () => widget.onShopTap!(shop) : null,
          ),
        );
      },
    );
  }
}