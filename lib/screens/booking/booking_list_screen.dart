import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  List<dynamic> bookings = [];

  static const apiKey = 
      "25c78a3206e58231c87783cdbc8359584767c6718f1fcaedb9a406c5a6971e4c";

  Future<void> fetchBookings() async {
    final response = await http.get(
      Uri.parse("http://10.0.0.6:8000/api/v1/booking/list"),
      headers: {"accept": "application/json", "x-api-key": apiKey},
    );
    if (response.statusCode == 200) {
      setState(() {
        bookings = jsonDecode(response.body);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mis Reservas")),
      body: bookings.isEmpty
          ? const Center(child: Text("No tienes reservas"))
          : ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final b = bookings[index];
                return Card(
                  child: ListTile(
                    title: Text(b['business']),
                    subtitle: Text("${b['date']} • ${b['time']}"),
                  ),
                );
              },
            ),
    );
  }
}
