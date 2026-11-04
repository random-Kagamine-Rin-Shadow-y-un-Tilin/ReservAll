import 'package:http/http.dart' as http;
import 'dart:convert';
import '/models/shop.dart';

const String baseUrl = "http://10.0.0.6:8000/api/v1";
const String apiKey =
    "25c78a3206e58231c87783cdbc8359584767c6718f1fcaedb9a406c5a6971e4c";

Map<String, String> get _jsonHeaders => {
  "accept": "application/json",
  "x-api-key": apiKey,
};

Future<List<Shop>> fetchShops() async {
  final response = await http.get(
    Uri.parse("$baseUrl/client/shops"),
    headers: _jsonHeaders,
  );
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => Shop.fromJson(json)).toList();
  } else {
    throw Exception("Error al cargar negocios: ${response.statusCode}");
  }
}

Future<List<ShopCategory>> fetchCategories() async {
  final response = await http.get(
    Uri.parse("$baseUrl/client/categories"),
    headers: _jsonHeaders,
  );
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => ShopCategory.fromJson(json)).toList();
  }
  throw Exception("Error al cargar categorías: ${response.statusCode}");
}

/// Búsqueda unificada del catálogo (HU_34 a HU_41).
///
/// Los filtros nulos se omiten para no enviar parámetros vacíos.
Future<List<Shop>> searchCatalog({
  String? q,
  int? categoriaId,
  String? categoria,
  String? ciudad,
  double? lat,
  double? lng,
  double? radioKm,
  double? precioMin,
  double? precioMax,
  String? fecha,
  String? hora,
  int? servicioId,
  String orden = "relevancia",
  int limit = 50,
  int offset = 0,
}) async {
  final params = <String, String>{};

  if (q != null && q.trim().length >= 2) params["q"] = q.trim();
  if (categoriaId != null) params["categoria_id"] = categoriaId.toString();
  if (categoria != null && categoria.trim().length >= 2) {
    params["categoria"] = categoria.trim();
  }
  if (ciudad != null && ciudad.trim().length >= 2) {
    params["ciudad"] = ciudad.trim();
  }
  if (lat != null) params["lat"] = lat.toString();
  if (lng != null) params["lng"] = lng.toString();
  if (radioKm != null) params["radio_km"] = radioKm.toString();
  if (precioMin != null) params["precio_min"] = precioMin.toString();
  if (precioMax != null) params["precio_max"] = precioMax.toString();
  if (fecha != null) params["fecha"] = fecha;
  if (hora != null) params["hora"] = hora;
  if (servicioId != null) params["servicio_id"] = servicioId.toString();
  params["orden"] = orden;
  params["limit"] = limit.toString();
  params["offset"] = offset.toString();

  final uri = Uri.parse(
    "$baseUrl/client/shops",
  ).replace(queryParameters: params);
  final response = await http.get(uri, headers: _jsonHeaders);
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => Shop.fromJson(json)).toList();
  }
  throw Exception("Error en la búsqueda: ${response.statusCode}");
}

Future<ShopDetail> fetchShopDetail(int shopId) async {
  final response = await http.get(
    Uri.parse("$baseUrl/client/shops/$shopId"),
    headers: _jsonHeaders,
  );
  if (response.statusCode == 200) {
    return ShopDetail.fromJson(json.decode(response.body));
  }
  throw Exception("Error al cargar el negocio: ${response.statusCode}");
}

Future<List<dynamic>> fetchBookings() async {
  final response = await http.get(
    Uri.parse("$baseUrl/booking/list"),
    headers: _jsonHeaders,
  );
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception("Error al cargar reservas: ${response.statusCode}");
  }
}

Future<bool> createBooking(Shop negocio, String date, String time) async {
  final response = await http.post(
    Uri.parse("$baseUrl/booking/create"),
    headers: {"Content-Type": "application/json", "x-api-key": apiKey},
    body: jsonEncode({"business_id": negocio.id, "date": date, "time": time}),
  );
  return response.statusCode == 200;
}
