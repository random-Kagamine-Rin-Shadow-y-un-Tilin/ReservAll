import 'package:http/http.dart' as http;
import 'dart:convert';
import '/models/shop.dart';


const String baseUrl = "http://10.0.0.6:8000/api/v1";
const String apiKey = "25c78a3206e58231c87783cdbc8359584767c6718f1fcaedb9a406c5a6971e4c";

Future<List<Shop>> fetchShops() async {
  final response = await http.get(
    Uri.parse("$baseUrl/client/list-shops"),
    headers: {"x-api-key": apiKey},
  );
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => Shop.fromJson(json)).toList();
  } else {
    throw Exception("Error al cargar negocios: ${response.statusCode}");
  }
}

Future<List<dynamic>> fetchBookings() async {
  final response = await http.get(
    Uri.parse("$baseUrl/booking/list"),
    headers: {"x-api-key": apiKey},
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
    headers: {
      "Content-Type": "application/json",
      "x-api-key": apiKey,
    },
    body: jsonEncode({
      "business_id": negocio.id,
      "date": date,
      "time": time,
    }),
  );
  return response.statusCode == 200;
}
