import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/models/shop.dart';
import '/services/api_service.dart';

class BusinessDetailScreen extends StatefulWidget {
  const BusinessDetailScreen({super.key});

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  bool isFavorite = false;

  String _getImageUrl(dynamic rawImage) {
    if (rawImage == null) return '';
    String img = rawImage.toString().trim();
    if (img.isEmpty || img == 'null') return '';
    if (img.startsWith("http://") || img.startsWith("https://")) {
      return img;
    }
    if (img.startsWith("/")) {
      return "http://10.0.0.6:8000$img";
    }
    return "http://10.0.0.6:8000/static/$img";
  }

  Future<void> toggleFavorite(dynamic shopId) async {
    setState(() {
      isFavorite = !isFavorite;
    });

    final String message = isFavorite ? "Negocio agregado a favoritos" : "Negocio eliminado de favoritos";
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2A9D8F),
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      final endpoint = isFavorite ? "add-favorite" : "remove-favorite";
      
      final response = await http.post(
        Uri.parse("$baseUrl/client/$endpoint"),
        headers: {
          "accept": "application/json",
          "content-type": "application/json",
          "x-api-key": apiKey,
        },
        body: jsonEncode({
          "id_negocio": shopId,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200 && response.statusCode != 201) {
        print("Error Backend Detail Favorites: ${response.statusCode} - ${response.body}");
        _revertFavoriteState("No se pudo sincronizar con el servidor");
      }
    } catch (e) {
      print("Excepción Detail Favorites: $e");
      _revertFavoriteState("Error de conexión. Cambio no guardado.");
    }
  }

  void _revertFavoriteState(String errorMessage) {
    if (!mounted) return;
    setState(() {
      isFavorite = !isFavorite;
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Object? args = ModalRoute.of(context)!.settings.arguments;

    String nombre = '';
    String descripcion = '';
    String categoria = 'General';
    String rawImagen = '';
    String direccion = 'Ubicación no especificada';
    String horarios = 'Lunes a Sábado: 9:00 AM - 8:00 PM';
    List<dynamic> servicios = [];
    double valoracion = 4.8;
    dynamic shopId = '';

    const Map<int, String> categoryNames = {
      1: "Barberia",
      2: "Spa",
      3: "Restaurante",
      4: "Belleza",
      5: "Otro",
    };

    if (args is Shop) {
      nombre = args.nombre;
      descripcion = args.descripcion;
      rawImagen = args.imagenNegocio;
      shopId = args.id;

      if (args.categoriaNegocio.isNotEmpty && args.categoriaNegocio != "null" && args.categoriaNegocio != "General") {
        categoria = args.categoriaNegocio;
      }
    } else if (args is Map<String, dynamic>) {
      nombre = args['nombre'] ?? '';
      descripcion = args['descripcion'] ?? '';
      rawImagen = args['imagen_negocio'] ?? '';
      direccion = args['direccion'] ?? args['ubicacion'] ?? 'Ubicación no especificada';
      horarios = args['horarios'] ?? args['horario'] ?? 'Lunes a Sábado: 9:00 AM - 8:00 PM';
      servicios = args['servicios'] ?? [];
      valoracion = (args['valoracion'] != null) ? double.tryParse(args['valoracion'].toString()) ?? 4.8 : 4.8;
      shopId = args['id'] ?? args['id_negocio'] ?? args['idShop'];
      isFavorite = args['is_favorite'] ?? false;

      var rawCatId = args['fk_categoria'] ?? args['id_categoria'] ?? args['categoria_id'];
      if (rawCatId != null) {
        int? catId = int.tryParse(rawCatId.toString());
        if (catId != null && categoryNames.containsKey(catId)) {
          categoria = categoryNames[catId]!;
        }
      } 
      
      if (categoria == 'General') {
        var rawCatName = args['categoria'] ?? args['nombre_categoria'] ?? args['category'] ?? args['categoria_negocio'];
        if (rawCatName is Map) {
          categoria = rawCatName['nombre_categoria'] ?? rawCatName['nombre'] ?? 'General';
        } else if (rawCatName != null && rawCatName.toString() != "null") {
          categoria = rawCatName.toString();
        }
      }
    }

    final String finalImageUrl = _getImageUrl(rawImagen);

    final Color primaryColor = const Color(0xFFE2725B);      
    final Color secondaryColor = const Color(0xFF2A9D8F);    
    final Color backgroundColor = const Color(0xFFFAF6F1);   
    final Color surfaceColor = const Color(0xFFFFFFFF);      
    final Color textMainColor = const Color(0xFF2B2118);     
    final Color textSecondaryColor = const Color(0xFF7A7267);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.redAccent.shade100 : Colors.white,
            ),
            onPressed: () => toggleFavorite(shopId),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey.shade200,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: finalImageUrl.isNotEmpty
                    ? Image.network(
                        finalImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(Icons.store, size: 64, color: primaryColor),
                        ),
                      )
                    : Center(child: Icon(Icons.store, size: 64, color: primaryColor)),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textMainColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Chip(
                        label: Text(categoria),
                        backgroundColor: secondaryColor.withValues(alpha: 0.15),
                        labelStyle: TextStyle(color: secondaryColor, fontWeight: FontWeight.bold),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade400, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        valoracion.toString(),
                        style: TextStyle(fontWeight: FontWeight.bold, color: textMainColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              "Acerca del negocio",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textMainColor),
            ),
            const SizedBox(height: 8),
            Text(
              descripcion.isNotEmpty ? descripcion : "Sin descripción disponible.",
              style: TextStyle(fontSize: 15, color: textSecondaryColor, height: 1.4),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),

            Card(
              color: surfaceColor,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            direccion,
                            style: TextStyle(color: textMainColor, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: secondaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            horarios,
                            style: TextStyle(color: textMainColor, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (servicios.isNotEmpty) ...[
              Text(
                "Servicios disponibles",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textMainColor),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: servicios.length,
                itemBuilder: (context, index) {
                  final servicio = servicios[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.check_circle_outline, color: secondaryColor),
                    title: Text(servicio['nombre'] ?? 'Servicio', style: TextStyle(color: textMainColor, fontWeight: FontWeight.bold)),
                    subtitle: Text(servicio['precio'] != null ? '\$${servicio['precio']}' : '', style: TextStyle(color: textSecondaryColor)),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],

            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/bookingCreate', arguments: args);
                  },
                  icon: const Icon(Icons.calendar_today, color: Colors.white),
                  label: const Text(
                    "Reservar Cita",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}