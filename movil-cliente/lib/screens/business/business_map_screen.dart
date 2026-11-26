import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '/models/shop.dart';
import '/services/route_service.dart';

enum _TravelMode {
  driving('driving', 'Auto', Icons.directions_car, 35.0, 1.0),
  walking('walking', 'A pie', Icons.directions_walk, 4.8, 0.92),
  cycling('cycling', 'Bici', Icons.directions_bike, 15.0, 0.96);

  final String osrmProfile;
  final String label;
  final IconData icon;
  final double speedKmh;
  final double fallbackDistanceFactor;

  const _TravelMode(
    this.osrmProfile,
    this.label,
    this.icon,
    this.speedKmh,
    this.fallbackDistanceFactor,
  );
}

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
  final Distance _distanceCalc = const Distance();

  final Color primaryColor = const Color(0xFFE2725B);
  final Color secondaryColor = const Color(0xFF2A9D8F);
  final Color backgroundColor = const Color(0xFFFAF6F1);
  final Color surfaceColor = const Color(0xFFFFFFFF);
  final Color textMainColor = const Color(0xFF2B2118);
  final Color textSecondaryColor = const Color(0xFF7A7267);

  _TravelMode _selectedMode = _TravelMode.driving;
  LatLng? _currentLocation;
  List<LatLng> _routePoints = const [];
  RouteInfo? _routeInfo;
  bool _isLoadingRoute = false;
  String? _routeError;
  String? _routeSummary;

  LatLng? get _shopPoint {
    if (!widget.shop.hasCoordinates) return null;
    return LatLng(widget.shop.latitud!, widget.shop.longitud!);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadRouteToShop();
    });
  }

  double _polylineLengthMeters(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      total += _distanceCalc.as(LengthUnit.Meter, points[i], points[i + 1]);
    }
    return total;
  }

  List<LatLng> _buildAdjustedPoints(
    LatLng origin,
    LatLng dest,
    _TravelMode mode,
  ) {
    if (mode == _TravelMode.driving) {
      return [origin, dest];
    }

    final midLat = (origin.latitude + dest.latitude) / 2;
    final midLng = (origin.longitude + dest.longitude) / 2;
    final dLat = dest.latitude - origin.latitude;
    final dLng = dest.longitude - origin.longitude;
    final len = math.sqrt(dLat * dLat + dLng * dLng);

    if (len == 0) return [origin, dest];

    final perpLat = -dLng / len;
    final perpLng = dLat / len;
    final offsetFactor = mode == _TravelMode.walking ? 0.08 : -0.05;
    final ctrlLat = midLat + perpLat * len * offsetFactor;
    final ctrlLng = midLng + perpLng * len * offsetFactor;

    final control = LatLng(ctrlLat, ctrlLng);
    final sampled = <LatLng>[];
    const steps = 12;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final oneMinusT = 1 - t;
      final lat = oneMinusT * oneMinusT * origin.latitude +
          2 * oneMinusT * t * control.latitude +
          t * t * dest.latitude;
      final lng = oneMinusT * oneMinusT * origin.longitude +
          2 * oneMinusT * t * control.longitude +
          t * t * dest.longitude;
      sampled.add(LatLng(lat, lng));
    }
    return sampled;
  }

  String _formatDuration(int totalMinutes) {
    final safeMinutes = totalMinutes.clamp(1, 999999);
    if (safeMinutes < 60) {
      return '~$safeMinutes min';
    }
    final hours = safeMinutes ~/ 60;
    final remainingMinutes = safeMinutes % 60;
    if (remainingMinutes == 0) {
      return '~$hours h';
    }
    return '~$hours h $remainingMinutes min';
  }

  String _formatSummary(_TravelMode mode, double meters, double? seconds) {
    final km = (meters / 1000).clamp(0.1, 9999.0);
    final calculatedMinutes =
        ((km / mode.speedKmh) * 60).round().clamp(1, 999999);
    final totalMinutes = seconds != null && seconds > 0
        ? (seconds / 60).round().clamp(1, 999999)
        : calculatedMinutes;

    return '${mode.label}: ${km.toStringAsFixed(1)} km • ${_formatDuration(totalMinutes)}';
  }

  Future<void> _selectMode(_TravelMode mode) async {
    if (_selectedMode == mode) return;
    setState(() {
      _selectedMode = mode;
    });

    final dest = _shopPoint;
    if (dest == null) return;

    if (_currentLocation != null) {
      setState(() {
        _isLoadingRoute = true;
        _routeError = null;
        _routeSummary = null;
      });
      await _fetchStreetRoute(_currentLocation!, dest, mode);
    } else {
      await _loadRouteToShop();
    }
  }

  Future<void> _loadRouteToShop() async {
    final dest = _shopPoint;
    if (dest == null || !mounted) return;

    setState(() {
      _isLoadingRoute = true;
      _routeError = null;
      _routeSummary = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _isLoadingRoute = false;
          _routeError = 'Activa el GPS para calcular la ruta hasta el negocio.';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() {
          _isLoadingRoute = false;
          _routeError = 'Permiso de ubicación denegado para trazar la ruta.';
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _isLoadingRoute = false;
          _routeError =
              'Permiso de ubicación denegado permanentemente. Habilítalo en Ajustes.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;

      final origin = LatLng(position.latitude, position.longitude);
      final initialPoints = _buildAdjustedPoints(origin, dest, _selectedMode);
      final initialMeters = _polylineLengthMeters(initialPoints);

      setState(() {
        _currentLocation = origin;
        _routePoints = initialPoints;
        _routeSummary = _formatSummary(_selectedMode, initialMeters, null);
      });

      _fitRouteBounds(origin, dest);
      await _fetchStreetRoute(origin, dest, _selectedMode);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingRoute = false;
        _routeError = 'No se pudo calcular la ruta en este momento.';
      });
    }
  }

  Future<void> _fetchStreetRoute(
    LatLng origin,
    LatLng dest,
    _TravelMode mode,
  ) async {
    try {
      final routeInfo = await _routeService.getRoute(
        originLat: origin.latitude,
        originLng: origin.longitude,
        destLat: dest.latitude,
        destLng: dest.longitude,
        profile: mode.osrmProfile,
      );

      if (!mounted) return;
      if (routeInfo.points.length >= 2) {
        final effectiveMeters = mode == _TravelMode.driving
            ? routeInfo.distanceMeters
            : routeInfo.distanceMeters * mode.fallbackDistanceFactor;
        final effectiveSeconds = mode == _TravelMode.driving
            ? routeInfo.durationSeconds
            : ((effectiveMeters / 1000.0) / mode.speedKmh) * 3600.0;

        setState(() {
          _routeInfo = routeInfo;
          _routePoints = routeInfo.points;
          _routeSummary =
              _formatSummary(mode, effectiveMeters, effectiveSeconds);
          _isLoadingRoute = false;
        });
        return;
      }
    } catch (_) {}

    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/${mode.osrmProfile}/'
        '${origin.longitude},${origin.latitude};${dest.longitude},${dest.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'com.reservall.movil_cliente'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final routes = decoded is Map ? decoded['routes'] : null;
        if (routes is List && routes.isNotEmpty) {
          final firstRoute = Map<String, dynamic>.from(routes.first as Map);
          final geometry = firstRoute['geometry'] is Map
              ? Map<String, dynamic>.from(firstRoute['geometry'] as Map)
              : null;
          final coords = geometry?['coordinates'];

          if (coords is List && coords.isNotEmpty) {
            final parsedPoints = <LatLng>[];
            for (final c in coords) {
              if (c is List && c.length >= 2) {
                final lng = (c[0] as num?)?.toDouble();
                final lat = (c[1] as num?)?.toDouble();
                if (lat != null && lng != null) {
                  parsedPoints.add(LatLng(lat, lng));
                }
              }
            }

            if (parsedPoints.length >= 2) {
              final osrmMeters =
                  (firstRoute['distance'] as num?)?.toDouble() ??
                      _polylineLengthMeters(parsedPoints);
              final osrmSeconds = (firstRoute['duration'] as num?)?.toDouble();

              final effectiveMeters = mode == _TravelMode.driving
                  ? osrmMeters
                  : osrmMeters * mode.fallbackDistanceFactor;
              final effectiveSeconds = mode == _TravelMode.driving
                  ? osrmSeconds
                  : ((effectiveMeters / 1000.0) / mode.speedKmh) * 3600.0;

              setState(() {
                _routePoints = parsedPoints;
                _routeSummary =
                    _formatSummary(mode, effectiveMeters, effectiveSeconds);
                _isLoadingRoute = false;
              });
              return;
            }
          }
        }
      }
    } catch (_) {}

    if (!mounted) return;
    final fallbackPoints = _buildAdjustedPoints(origin, dest, mode);
    final meters = _polylineLengthMeters(fallbackPoints);
    setState(() {
      _routePoints = fallbackPoints;
      _routeSummary = _formatSummary(mode, meters, null);
      _isLoadingRoute = false;
    });
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
    final point = _shopPoint;
    if (point == null) return;
    if (_currentLocation != null) {
      _fitRouteBounds(_currentLocation!, point);
      return;
    }
    _mapController.move(point, 15.5);
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
          child: Icon(
            Icons.location_on,
            color: primaryColor,
            size: 42,
          ),
        ),
      if (_currentLocation != null)
        Marker(
          point: _currentLocation!,
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: secondaryColor.withValues(alpha: 0.22),
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
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (shopPoint != null)
            IconButton(
              tooltip: 'Actualizar ruta',
              onPressed: _isLoadingRoute ? null : _loadRouteToShop,
              icon: const Icon(Icons.route),
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
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.reservall.movil_cliente',
                    ),
                    if (_routePoints.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 5.0,
                            color: _routeInfo?.isEstimatedFallback == true
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
                          Row(
                            children: _TravelMode.values.map((mode) {
                              final selected = _selectedMode == mode;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: mode != _TravelMode.cycling ? 6 : 0,
                                  ),
                                  child: ChoiceChip(
                                    label: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          mode.icon,
                                          size: 16,
                                          color: selected
                                              ? Colors.white
                                              : textMainColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            mode.label,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    selected: selected,
                                    selectedColor: secondaryColor,
                                    backgroundColor: backgroundColor,
                                    labelStyle: TextStyle(
                                      fontSize: 12,
                                      fontWeight: selected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: selected
                                          ? Colors.white
                                          : textMainColor,
                                    ),
                                    onSelected: (_) => _selectMode(mode),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (_isLoadingRoute ||
                              _routeSummary != null ||
                              _routeError != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                if (_isLoadingRoute) ...[
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: secondaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Calculando ruta (${_selectedMode.label})...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSecondaryColor,
                                    ),
                                  ),
                                ] else if (_routeSummary != null) ...[
                                  Icon(
                                    _selectedMode.icon,
                                    color: secondaryColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _routeSummary!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: secondaryColor,
                                      ),
                                    ),
                                  ),
                                ] else if (_routeError != null) ...[
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