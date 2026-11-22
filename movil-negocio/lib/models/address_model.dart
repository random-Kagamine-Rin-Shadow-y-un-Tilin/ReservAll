class ShopAddress {
  final int idDireccion;
  final String direccionCalle;
  final String ciudad;
  final String estado;
  final String codigoPostal;
  final String pais;
  final double latitud;
  final double longitud;
  final String osmId;
  final String numeroLocal;
  final String? numeroInterior;

  ShopAddress({
    required this.idDireccion,
    required this.direccionCalle,
    required this.ciudad,
    required this.estado,
    required this.codigoPostal,
    required this.pais,
    required this.latitud,
    required this.longitud,
    required this.osmId,
    required this.numeroLocal,
    this.numeroInterior,
  });

  factory ShopAddress.fromJson(Map<String, dynamic> json) => ShopAddress(
        idDireccion: int.tryParse('${json['id_direccion']}') ?? 0,
        direccionCalle: json['direccion_calle']?.toString() ?? '',
        ciudad: json['ciudad']?.toString() ?? '',
        estado: json['estado']?.toString() ?? '',
        codigoPostal: json['codigo_postal']?.toString() ?? '',
        pais: json['pais']?.toString() ?? '',
        latitud: double.tryParse('${json['latitud']}') ?? 0.0,
        longitud: double.tryParse('${json['longitud']}') ?? 0.0,
        osmId: json['osm_id']?.toString() ?? '',
        numeroLocal: json['numero_local']?.toString() ?? '',
        numeroInterior: json['numero_interior']?.toString(),
      );

  String get resumen {
    final numero = [numeroLocal, numeroInterior]
        .where((n) => n != null && n.isNotEmpty)
        .join(' #');
    final linea = [direccionCalle, numero]
        .where((v) => v.isNotEmpty)
        .join(' ');
    return [linea, ciudad, estado, codigoPostal, pais]
        .where((v) => v.isNotEmpty)
        .join(', ');
  }
}

class ShopAddressCreateRequest {
  final String direccionCalle;
  final String ciudad;
  final String estado;
  final String codigoPostal;
  final String pais;
  final double latitud;
  final double longitud;
  final String osmId;
  final String numeroLocal;
  final String? numeroInterior;

  ShopAddressCreateRequest({
    required this.direccionCalle,
    required this.ciudad,
    required this.estado,
    required this.codigoPostal,
    required this.pais,
    required this.latitud,
    required this.longitud,
    this.osmId = '',
    required this.numeroLocal,
    this.numeroInterior,
  });

  Map<String, dynamic> toJson() => {
        'direccion_calle': direccionCalle,
        'ciudad': ciudad,
        'estado': estado,
        'codigo_postal': codigoPostal,
        'pais': pais,
        'latitud': latitud,
        'longitud': longitud,
        'osm_id': osmId,
        'numero_local': numeroLocal,
        'numero_interior': numeroInterior,
      };
}

class ShopAddressUpdateRequest {
  final String? direccionCalle;
  final String? ciudad;
  final String? estado;
  final String? codigoPostal;
  final String? pais;
  final double? latitud;
  final double? longitud;
  final String? osmId;
  final String? numeroLocal;
  final String? numeroInterior;

  ShopAddressUpdateRequest({
    this.direccionCalle,
    this.ciudad,
    this.estado,
    this.codigoPostal,
    this.pais,
    this.latitud,
    this.longitud,
    this.osmId,
    this.numeroLocal,
    this.numeroInterior,
  });

  Map<String, dynamic> toJson() => {
        if (direccionCalle != null) 'direccion_calle': direccionCalle,
        if (ciudad != null) 'ciudad': ciudad,
        if (estado != null) 'estado': estado,
        if (codigoPostal != null) 'codigo_postal': codigoPostal,
        if (pais != null) 'pais': pais,
        if (latitud != null) 'latitud': latitud,
        if (longitud != null) 'longitud': longitud,
        if (osmId != null) 'osm_id': osmId,
        if (numeroLocal != null) 'numero_local': numeroLocal,
        if (numeroInterior != null) 'numero_interior': numeroInterior,
      };
}
