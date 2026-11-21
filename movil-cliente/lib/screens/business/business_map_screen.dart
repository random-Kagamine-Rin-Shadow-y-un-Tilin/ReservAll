import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '/models/shop.dart';
import '/services/route_service.dart';

class BusinessMapScreen extends StatefulWidget {
  final Shop shop;
  final String? formattedAddress;

  const BusinessMapScreen({
    super.key,
    required this.shop,
    this.formattedAddress,
  });

  @override
  State<BusinessMapScreen> createState() => _BusinessMapScreenState();
}

class _BusinessMapScreenState extends State<BusinessMapScreen> {
  final MapController _mapController = MapController();
  final RouteService _routeService = RouteService();

  final Color primaryColor = const Color(0xFFE2725B);
  final Color secondaryColor = const Color(0xFF2A9D8F);
  final Color backgroundColor = const Color(0xFFFAF6F1);
  final Color surfaceColor = const Color(0xFFFFFFFF);
  final Color textMainColor = const Color(0xFF2B2118);
  final Color textSecondaryColor = const Color(0xFF7A7267);

  LatLng? _userPoint;
  RouteInfo? _routeInfo;
  String _selectedProfile = 'driving';
  bool _loadingRoute = false;
  String? _routeError;
  bool _initializedRoute = false;

  static const List<({String profile, String label, IconData icon})>
      _travelModes = [
    (profile: 'driving', label: 'Auto', icon: Icons.directions_car),
    (profile: 'walking', label: 'A pie', icon: Icons.directions_walk),
    (profile: 'cycling', label: 'Bici', icon: Icons.directions_bike),
  ];

  LatLng? get _shopPoint {
    if (!widget.shop.hasCoordinates) return null;
    return LatLng(widget.shop.latitud!, widget.shop.longitud!);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initializedRoute) return;
      _initializedRoute = true;
      _loadRouteToShop();
    });
  }

  Future<Position?> _resolveUserPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _routeError = 'Activa el GPS para calcular la ruta hasta el negocio.';
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _routeError = 'Permiso de ubicación denegado para trazar la ruta.';
      return null;
    }

    if (permission == LocationPermission.deniedForever) {
      _routeError =
          'Permiso de ubicación denegado permanentemente. Habilítalo en Ajustes.';
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  Future<void> _loadRouteToShop({String? profile}) async {
    final shopPoint = _shopPoint;
    if (shopPoint == null || !mounted) return;

    final activeProfile = profile ?? _selectedProfile;

    setState(() {
      _selectedProfile = activeProfile;
      _loadingRoute = true;
      _routeError = null;
    });

    try {
      LatLng? origin = _userPoint;
      if (origin == null) {
        final pos = await _resolveUserPosition();
        if (!mounted) return;
        if (pos == null) {
          setState(() => _loadingRoute = false);
          return;
        }
        origin = LatLng(pos.latitude, pos.longitude);
        _userPoint = origin;
      }

      final info = await _routeService.getRoute(
        originLat: origin.latitude,
        originLng: origin.longitude,
        destLat: shopPoint.latitude,
        destLng: shopPoint.longitude,
        profile: activeProfile,
      );

      if (!mounted) return;
      setState(() {
        _routeInfo = info;
        _loadingRoute = false;
      });

      _fitRouteBounds(origin, shopPoint);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingRoute = false;
        _routeError = 'No se pudo calcular la ruta en este momento.';
      });
    }
  }

  void _fitRouteBounds(LatLng origin, LatLng destination) {
    final bounds = LatLngBounds.fromPoints([origin, destination]);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(48, 80, 48, 220),
      ),
    );
  }

  void _zoomBy(double delta) {
    final point = _shopPoint;
    if (point == null) return;
    final currentZoom = _mapController.camera.zoom;
    final nextZoom = (currentZoom + delta).clamp(4.0, 19.0);
    _mapController.move(_mapController.camera.center, nextZoom);
  }

  void _recenter() {
    final shopPoint = _shopPoint;
    if (shopPoint == null) return;
    if (_userPoint != null && _routeInfo != null) {
      _fitRouteBounds(_userPoint!, shopPoint);
    } else {
      _mapController.move(shopPoint, 15.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopPoint = _shopPoint;
    final locationLabel = (widget.formattedAddress?.trim().isNotEmpty == true)
        ? widget.formattedAddress!.trim()
        : (widget.shop.direccion?.trim().isNotEmpty == true)
            ? widget.shop.direccion!.trim()
            : shopPoint != null
                ? 'Lat: ${shopPoint.latitude.toStringAsFixed(5)}, Lng: ${shopPoint.longitude.toStringAsFixed(5)}'
                : 'Ubicación no disponible';

    final markers = <Marker>[
      if (shopPoint != null)
        Marker(
          point: shopPoint,
          width: 56,
          height: 56,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                color: primaryColor,
                size: 42,
              ),
            ],
          ),
        ),
      if (_userPoint != null)
        Marker(
          point: _userPoint!,
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: secondaryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: secondaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
              ),
            ),
          ),
        ),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.shop.nombre,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (shopPoint != null)
            IconButton(
              tooltip: 'Recalcular ruta',
              icon: const Icon(Icons.alt_route),
              onPressed: _loadingRoute ? null : () => _loadRouteToShop(),
            ),
        ],
      ),
      body: shopPoint == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No hay coordenadas disponibles para mostrar "${widget.shop.nombre}" en el mapa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textSecondaryColor, fontSize: 15),
                ),
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: shopPoint,
                    initialZoom: 15.5,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.reservall.movil_cliente',
                    ),
                    if (_routeInfo != null && _routeInfo!.points.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routeInfo!.points,
                            strokeWidth: 4.5,
                            color: _routeInfo!.isEstimatedFallback
                                ? primaryColor.withValues(alpha: 0.75)
                                : secondaryColor,
                          ),
                        ],
                      ),
                    MarkerLayer(markers: markers),
                  ],
                ),
                Positioned(
                  right: 14,
                  top: 14,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'hu56_zoom_in',
                        backgroundColor: surfaceColor,
                        foregroundColor: textMainColor,
                        onPressed: () => _zoomBy(1.0),
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'hu56_zoom_out',
                        backgroundColor: surfaceColor,
                        foregroundColor: textMainColor,
                        onPressed: () => _zoomBy(-1.0),
                        child: const Icon(Icons.remove),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'hu56_recenter',
                        backgroundColor: surfaceColor,
                        foregroundColor: primaryColor,
                        onPressed: _recenter,
                        child: const Icon(Icons.center_focus_strong),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Card(
                    color: surfaceColor,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.shop.nombre,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textMainColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.place, color: primaryColor, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  locationLabel,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textSecondaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: _travelModes.map((mode) {
                              final selected = _selectedProfile == mode.profile;
                              return ChoiceChip(
                                label: Text(mode.label),
                                avatar: Icon(
                                  mode.icon,
                                  size: 16,
                                  color: selected ? Colors.white : primaryColor,
                                ),
                                selected: selected,
                                selectedColor: primaryColor,
                                backgroundColor: backgroundColor,
                                labelStyle: TextStyle(
                                  color: selected ? Colors.white : textMainColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                onSelected: _loadingRoute
                                    ? null
                                    : (_) => _loadRouteToShop(profile: mode.profile),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                          if (_loadingRoute)
                            Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Calculando ruta...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textSecondaryColor,
                                  ),
                                ),
                              ],
                            )
                          else if (_routeInfo != null) ...[
                            Row(
                              children: [
                                Icon(Icons.route, color: secondaryColor, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  '${_routeInfo!.distanceText} · ${_routeInfo!.durationText}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: textMainColor,
                                  ),
                                ),
                                if (_routeInfo!.isEstimatedFallback) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '(línea recta)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ] else if (_routeError != null) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: primaryColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _routeError!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSecondaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}