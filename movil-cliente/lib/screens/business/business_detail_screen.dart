import 'package:flutter/material.dart';
import '/models/shop.dart';

class BusinessDetailScreen extends StatelessWidget {
  const BusinessDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Object? args = ModalRoute.of(context)!.settings.arguments;

    String nombre = '';
    String descripcion = '';
    String categoria = 'General';
    String imagen = '';
    String direccion = 'Ubicación no especificada';
    String horarios = 'Lunes a Sábado: 9:00 AM - 8:00 PM';
    List<dynamic> servicios = [];
    double valoracion = 4.8;

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
      imagen = args.imagenNegocio;

      if (args.categoriaNegocio.isNotEmpty && args.categoriaNegocio != "null" && args.categoriaNegocio != "General") {
        categoria = args.categoriaNegocio;
      }
    } else if (args is Map<String, dynamic>) {
      nombre = args['nombre'] ?? '';
      descripcion = args['descripcion'] ?? '';
      imagen = args['imagen_negocio'] ?? 'null';
      direccion = args['direccion'] ?? args['ubicacion'] ?? 'Ubicación no especificada';
      horarios = args['horarios'] ?? args['horario'] ?? 'Lunes a Sábado: 9:00 AM - 8:00 PM';
      servicios = args['servicios'] ?? [];
      valoracion = (args['valoracion'] != null) ? double.tryParse(args['valoracion'].toString()) ?? 4.8 : 4.8;

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

    if (args is Shop && categoria == 'General') {
    }

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
                image: (imagen != "null" && imagen.isNotEmpty)
                    ? DecorationImage(
                        image: imagen.startsWith("http")
                            ? NetworkImage(imagen)
                            : NetworkImage("http://10.0.0.6:8000/static/$imagen") as ImageProvider,
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (imagen == "null" || imagen.isEmpty)
                  ? Center(child: Icon(Icons.store, size: 64, color: primaryColor))
                  : null,
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