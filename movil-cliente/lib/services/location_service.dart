import 'package:geolocator/geolocator.dart';
import '/models/shop.dart';

class LocationResult {
  final Position? position;
  final String? errorMessage;
  final bool openSettingsSuggested;

  const LocationResult({
    this.position,
    this.errorMessage,
    this.openSettingsSuggested = false,
  });

  bool get isSuccess => position != null && errorMessage == null;
}

class LocationService {
  static Future<LocationResult> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationResult(
        errorMessage:
            'Activa la ubicación (GPS) en tu dispositivo para ver negocios cercanos.',
        openSettingsSuggested: true,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const LocationResult(
        errorMessage:
            'Permiso de ubicación denegado. Concédelo para calcular distancias.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationResult(
        errorMessage:
            'El permiso de ubicación está bloqueado permanentemente. Ábrelo en ajustes.',
        openSettingsSuggested: true,
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return LocationResult(position: position);
    } catch (_) {
      return const LocationResult(
        errorMessage: 'No se pudo obtener tu ubicación actual.',
      );
    }
  }

  static double distanceInKm({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    final meters = Geolocator.distanceBetween(
      startLat,
      startLng,
      endLat,
      endLng,
    );
    return meters / 1000.0;
  }

  static List<Shop> attachDistancesAndSort(
    List<Shop> shops, {
    required double userLat,
    required double userLng,
    double? maxRadiusKm,
  }) {
    final computed = <Shop>[];

    for (final shop in shops) {
      if (!shop.hasCoordinates) continue;

      final dist = distanceInKm(
        startLat: userLat,
        startLng: userLng,
        endLat: shop.latitud!,
        endLng: shop.longitud!,
      );

      if (maxRadiusKm != null && dist > maxRadiusKm) continue;

      computed.add(shop.copyWith(distanciaKm: dist));
    }

    computed.sort((a, b) {
      final da = a.distanciaKm ?? double.infinity;
      final db = b.distanciaKm ?? double.infinity;
      return da.compareTo(db);
    });

    return computed;
  }

  static int estimateMinutes(double distanceKm, {bool walking = false}) {
    final speedKmPerHour = walking ? 4.8 : 28.0;
    final hours = distanceKm / speedKmPerHour;
    final minutes = (hours * 60).round();
    return minutes < 1 ? 1 : minutes;
  }
}