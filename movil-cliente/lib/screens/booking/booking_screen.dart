import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final TextEditingController businessController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();

  static const apiKey =
      "25c78a3206e58231c87783cdbc8359584767c6718f1fcaedb9a406c5a6971e4c";

  Future<void> createBooking() async {
    final response = await http.post(
      Uri.parse("http://127.0.0.1:8000/api/v1/booking"),
      headers: {
        "accept": "application/json",
        "content-type": "application/json",
        "x-api-key": apiKey
      },
      body: jsonEncode({
        "business": businessController.text,
        "date": dateController.text,
        "time": timeController.text,
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reserva creada con éxito")),
      );
      Navigator.pop(context); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${response.statusCode}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nueva Reserva")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: businessController,
              decoration: const InputDecoration(labelText: "Negocio"),
            ),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: "Fecha (YYYY-MM-DD)"),
            ),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(labelText: "Hora (HH:MM)"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: createBooking,
              child: const Text("Reservar"),
            ),
          ],
        ),
      ),
    );
  }
}
