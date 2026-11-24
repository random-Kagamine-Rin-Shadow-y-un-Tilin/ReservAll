import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:movil_cliente/services/location_service.dart';
import 'package:movil_cliente/services/route_service.dart';

class BusinessRouteMapScreen extends StatefulWidget {
  final String businessName;
  final double businessLat;
  final double businessLng;

  const BusinessRouteMapScreen({
    super.key,
    required this.businessName,
    required this.businessLat,
    required this.businessLng,
  });

  @override
  State<BusinessRouteMapScreen> createState() => _BusinessRouteMapScreenState();
}

class _BusinessRouteMapScreenState extends State<BusinessRouteMapScreen> {
  final MapController _mapController = MapController();
  final RouteService _routeService = RouteService();

  LatLng? _userLocation;
  RouteInfo? _routeInfo;
  String _travelProfile = 'driving'; 
  bool _isLoading = false;
  String? _errorMessage;
  bool _openSettingsSuggested = false;

  LatLng get _destination => LatLng(widget.businessLat, widget.businessLng);

  @override
  void initState() {
    super.initState();
    _calculateRoute();
  }

  Future<void> _calculateRoute() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _openSettingsSuggested = false;
    });

    try {
      final locationResult = await LocationService.getCurrentLocation();
      final position = locationResult.position;

      if (!locationResult.isSuccess || position == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = locationResult.errorMessage ??
              'No se pudo obtener tu ubicación actual. Revisa los permisos y el GPS.';
          _openSettingsSuggested = locationResult.openSettingsSuggested;
          _isLoading = false;
        });
        return;
      }

      final origin = LatLng(position.latitude, position.longitude);

      final info = await _routeService.getRoute(
        originLat: origin.latitude,
        originLng: origin.longitude,
        destLat: _destination.latitude,
        destLng: _destination.longitude,
        profile: _travelProfile,
      );

      if (!mounted) return;
      setState(() {
        _userLocation = origin;
        _routeInfo = info;
        _isLoading = false;
      });

      _fitRouteInView(origin, _destination);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error al calcular la ruta: $e';
        _isLoading = false;
      });
    }
  }

  void _fitRouteInView(LatLng origin, LatLng destination) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pointsToFit = <LatLng>[
        origin,
        destination,
        if (_routeInfo != null) ..._routeInfo!.points,
      ];
      final bounds = LatLngBounds.fromPoints(pointsToFit);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(48, 48, 48, 210),
        ),
      );
    });
  }

  void _changeProfile(String profile) {
    if (_travelProfile == profile) return;
    setState(() {
      _travelProfile = profile;
    });
    _calculateRoute();
  }

  Future<void> _openDeviceSettings() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _userLocation ?? _destination;

    return Scaffold(
      appBar: AppBar(
        title: Text('Ruta a ${widget.businessName}'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _calculateRoute,
            tooltip: 'Actualizar ruta',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.reservall.movil_cliente',
              ),
              if (_routeInfo != null && _routeInfo!.points.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routeInfo!.points,
                      strokeWidth: 4.5,
                      color: Colors.blueAccent,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 42,
                      height: 42,
                      child: const _LocationPin(
                        icon: Icons.my_location,
                        color: Colors.blue,
                      ),
                    ),
                  Marker(
                    point: _destination,
                    width: 46,
                    height: 46,
                    child: const _LocationPin(
                      icon: Icons.storefront,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_userLocation != null)
            Positioned(
              right: 16,
              bottom: 195,
              child: FloatingActionButton.small(
                heroTag: 'center_route_btn',
                tooltip: 'Centrar ruta',
                onPressed: () => _fitRouteInView(_userLocation!, _destination),
                child: const Icon(Icons.center_focus_strong),
              ),
            ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _buildBottomPanel(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Text('Calculando ruta hacia el negocio...')),
                ],
              )
            : _errorMessage != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: _calculateRoute,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                          if (_openSettingsSuggested)
                            OutlinedButton.icon(
                              onPressed: _openDeviceSettings,
                              icon: const Icon(Icons.settings),
                              label: const Text('Ajustes'),
                            ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.businessName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'driving',
                                icon: Icon(Icons.directions_car, size: 18),
                              ),
                              ButtonSegment(
                                value: 'walking',
                                icon: Icon(Icons.directions_walk, size: 18),
                              ),
                            ],
                            selected: {_travelProfile},
                            onSelectionChanged: (selection) {
                              _changeProfile(selection.first);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _RouteMetric(
                            icon: Icons.straighten,
                            label: 'Distancia',
                            value: _routeInfo?.distanceText ?? '--',
                          ),
                          _RouteMetric(
                            icon: Icons.schedule,
                            label: 'Tiempo estimado',
                            value: _routeInfo?.durationText ?? '--',
                          ),
                        ],
                      ),
                      if (_routeInfo?.isEstimatedFallback == true) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Estimación aproximada en línea recta por falta de respuesta del servicio de rutas.',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }
}

class _LocationPin extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _LocationPin({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class _RouteMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _RouteMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}