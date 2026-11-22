class GeocodedAddress {
  final String direccionCalle;
  final String ciudad;
  final String estado;
  final String codigoPostal;
  final String pais;
  final String osmId;
  final String numeroLocal;
  final String numeroInterior;

  GeocodedAddress({
    this.direccionCalle = '',
    this.ciudad = '',
    this.estado = '',
    this.codigoPostal = '',
    this.pais = '',
    this.osmId = '',
    this.numeroLocal = '',
    this.numeroInterior = '',
  });

  factory GeocodedAddress.fromJson(Map<String, dynamic> json) =>
      GeocodedAddress(
        direccionCalle: json['direccion_calle']?.toString() ?? '',
        ciudad: json['ciudad']?.toString() ?? '',
        estado: json['estado']?.toString() ?? '',
        codigoPostal: json['codigo_postal']?.toString() ?? '',
        pais: json['pais']?.toString() ?? '',
        osmId: json['osm_id']?.toString() ?? '',
        numeroLocal: json['numero_local']?.toString() ?? '',
        numeroInterior: json['numero_interior']?.toString() ?? '',
      );
}

class ReverseGeocodeResult extends GeocodedAddress {
  final String displayName;
  final double latitud;
  final double longitud;
  final String? osmType;

  ReverseGeocodeResult({
    super.direccionCalle,
    super.ciudad,
    super.estado,
    super.codigoPostal,
    super.pais,
    super.osmId,
    super.numeroLocal,
    super.numeroInterior,
    required this.displayName,
    required this.latitud,
    required this.longitud,
    this.osmType,
  });

  factory ReverseGeocodeResult.fromJson(Map<String, dynamic> json) {
    final base = GeocodedAddress.fromJson(json);
    return ReverseGeocodeResult(
      direccionCalle: base.direccionCalle,
      ciudad: base.ciudad,
      estado: base.estado,
      codigoPostal: base.codigoPostal,
      pais: base.pais,
      osmId: base.osmId,
      numeroLocal: base.numeroLocal,
      numeroInterior: base.numeroInterior,
      displayName: json['display_name']?.toString() ?? '',
      latitud: double.tryParse('${json['latitud']}') ?? 0.0,
      longitud: double.tryParse('${json['longitud']}') ?? 0.0,
      osmType: json['osm_type']?.toString(),
    );
  }
}

class GeocodeResult extends GeocodedAddress {
  final String displayName;
  final double latitud;
  final double longitud;
  final String? osmType;
  final String? tipo;
  final String? clase;

  GeocodeResult({
    super.direccionCalle,
    super.ciudad,
    super.estado,
    super.codigoPostal,
    super.pais,
    super.osmId,
    super.numeroLocal,
    super.numeroInterior,
    required this.displayName,
    required this.latitud,
    required this.longitud,
    this.osmType,
    this.tipo,
    this.clase,
  });

  factory GeocodeResult.fromJson(Map<String, dynamic> json) {
    final base = GeocodedAddress.fromJson(json);
    return GeocodeResult(
      direccionCalle: base.direccionCalle,
      ciudad: base.ciudad,
      estado: base.estado,
      codigoPostal: base.codigoPostal,
      pais: base.pais,
      osmId: base.osmId,
      numeroLocal: base.numeroLocal,
      numeroInterior: base.numeroInterior,
      displayName: json['display_name']?.toString() ?? '',
      latitud: double.tryParse('${json['latitud']}') ?? 0.0,
      longitud: double.tryParse('${json['longitud']}') ?? 0.0,
      osmType: json['osm_type']?.toString(),
      tipo: json['tipo']?.toString(),
      clase: json['clase']?.toString(),
    );
  }
}
