import 'package:flutter/material.dart';
import '/models/shop.dart';

class BusinessDetailScreen extends StatelessWidget {
  const BusinessDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Shop negocio = ModalRoute.of(context)!.settings.arguments as Shop;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F1),
      appBar: AppBar(
        title: Text(negocio.nombre),
        backgroundColor: const Color(0xFFE2725B),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade200,
                image: negocio.imagenNegocio != "null"
                    ? DecorationImage(
                        image: NetworkImage("http://10.0.0.6:8000/static/${negocio.imagenNegocio}"),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: negocio.imagenNegocio == "null"
                  ? const Center(
                      child: Icon(Icons.store, size: 64, color: Color(0xFFE2725B)),
                    )
                  : null,
            ),
            const SizedBox(height: 20),

            Text(
              negocio.nombre,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B2118),
              ),
            ),
            const SizedBox(height: 8),

            Chip(
              label: Text(negocio.categoriaNegocio),
              backgroundColor: const Color(0xFFE2725B).withOpacity(0.2),
              labelStyle: const TextStyle(color: Color(0xFFE2725B)),
            ),
            const SizedBox(height: 16),

            Text(
              negocio.descripcion,
              style: const TextStyle(fontSize: 16, color: Color(0xFF7A7267)),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 30),

            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE2725B),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/bookingCreate', arguments: negocio);
                },
                icon: const Icon(Icons.calendar_today, color: Colors.white),
                label: const Text("Reservar", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
