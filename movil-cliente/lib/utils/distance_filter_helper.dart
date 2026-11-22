import 'package:geolocator/geolocator.dart';
import '/models/shop.dart';

class DistanceFilterHelper {
  static const List<double> maxDistanceOptionsKm = [1.0, 5.0, 10.0];

  static List<Shop> attachDistances({
    required List<Shop> shops,
    double? userLat,
    double? userLng,
  }) {
    return shops.map((shop) {
      if (shop.distanciaKm != null) {
        return shop;
      }
      if (userLat != null &&
          userLng != null &&
          shop.hasCoordinates &&
          shop.latitud != null &&
          shop.longitud != null) {
        final meters = Geolocator.distanceBetween(
          userLat,
          userLng,
          shop.latitud!,
          shop.longitud!,
        );
        return shop.copyWith(distanciaKm: meters / 1000.0);
      }
      return shop;
    }).toList(); 
  }

  static List<Shop> filterAndSortByProximity({
    required List<Shop> shops,
    double? maxDistanceKm,
  }) {
    final filtered = maxDistanceKm == null
        ? List<Shop>.from(shops)
        : shops.where((s) => s.distanciaKm != null && s.distanciaKm! <= maxDistanceKm).toList();

    filtered.sort((a, b) {
      if (a.distanciaKm == null && b.distanciaKm == null) return 0;
      if (a.distanciaKm == null) return 1;
      if (b.distanciaKm == null) return -1;
      return a.distanciaKm!.compareTo(b.distanciaKm!);
    });

    return filtered;
  }
}