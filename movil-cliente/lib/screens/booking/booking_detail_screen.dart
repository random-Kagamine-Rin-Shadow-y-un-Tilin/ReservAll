import 'package:flutter/material.dart';

class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final booking = {
      'service': 'Corte de cabello',
      'date': '01/08/2026',
      'time': '10:00',
      'status': 'Confirmada',
      'business': 'Peluquería Estilo',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de reserva'),
        backgroundColor: const Color(0xFF2A9D8F), 
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Negocio: ${booking['business']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Servicio: ${booking['service']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Fecha: ${booking['date']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Hora: ${booking['time']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Estado: ${booking['status']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE2725B), 
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar reserva'),
            ),
          ],
        ),
      ),
    );
  }
}
