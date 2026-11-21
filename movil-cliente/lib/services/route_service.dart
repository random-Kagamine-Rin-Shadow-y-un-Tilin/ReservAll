import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteInfo {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final bool isEstimatedFallback;

  RouteInfo({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.isEstimatedFallback = false,
  });

  String get distanceText {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    final km = distanceMeters / 1000;
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
  }

  String get durationText {
    final totalMinutes = (durationSeconds / 60).round();
    if (totalMinutes < 1) {
      return '< 1 min';
    }
    if (totalMinutes < 60) {
      return '$totalMinutes min';
    }
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    return mins == 0 ? '${hours} h' : '${hours} h ${mins} min';
  }
}

class RouteService {
  static const String _osrmBaseUrl = 'https://router.project-osrm.org';

  Future<RouteInfo> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String profile = 'driving',
  }) async {
    final origin = LatLng(originLat, originLng);
    final destination = LatLng(destLat, destLng);

    final url = Uri.parse(
      '$_osrmBaseUrl/route/v1/$profile/$originLng,$originLat;$destLng,$destLat'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;

        if (routes != null && routes.isNotEmpty) {
          final route = routes.first as Map<String, dynamic>;
          final distance = (route['distance'] as num?)?.toDouble() ?? 0.0;
          final rawDuration = (route['duration'] as num?)?.toDouble() ?? 0.0;

          
          final double duration = switch (profile) {
            'walking' => distance / 1.35, // ~4.8 km
            'cycling' => distance / 4.16, // ~15 km
            _ => rawDuration,
          };

          final geometry = route['geometry'] as Map<String, dynamic>?;
          final coords = geometry?['coordinates'] as List<dynamic>? ?? [];

          final points = coords
              .map((c) {
                final pair = c as List<dynamic>;
                final lng = (pair[0] as num).toDouble();
                final lat = (pair[1] as num).toDouble();
                return LatLng(lat, lng);
              })
              .toList();

          if (points.isNotEmpty) {
            return RouteInfo(
              points: points,
              distanceMeters: distance,
              durationSeconds: duration,
              isEstimatedFallback: false,
            );
          }
        }
      }
    } catch (_) {}

    return _fallbackStraightLineRoute(
      origin: origin,
      destination: destination,
      profile: profile,
    );
  }

  RouteInfo _fallbackStraightLineRoute({
    required LatLng origin,
    required LatLng destination,
    required String profile,
  }) {
    final distanceMeters = Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );

    final double speedMps = switch (profile) {
      'walking' => 1.35, // ~4.8 km/h
      'cycling' => 4.16, // ~15 km/h
      _ => 8.33, // ~30 km/h
    };

    final estimatedDuration = distanceMeters / speedMps;

    return RouteInfo(
      points: [origin, destination],
      distanceMeters: distanceMeters,
      durationSeconds: estimatedDuration,
      isEstimatedFallback: true,
    );
  }
}