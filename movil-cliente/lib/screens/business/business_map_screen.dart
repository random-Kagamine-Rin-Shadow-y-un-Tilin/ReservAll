import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '/models/shop.dart';

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

  final Color primaryColor = const Color(0xFFE2725B);
  final Color backgroundColor = const Color(0xFFFAF6F1);
  final Color surfaceColor = const Color(0xFFFFFFFF);
  final Color textMainColor = const Color(0xFF2B2118);
  final Color textSecondaryColor = const Color(0xFF7A7267);

  LatLng? get _shopPoint {
    if (!widget.shop.hasCoordinates) return null;
    return LatLng(widget.shop.latitud!, widget.shop.longitud!);
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.shop.nombre,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
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
                    MarkerLayer(
                      markers: [
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
                      ],
                    ),
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