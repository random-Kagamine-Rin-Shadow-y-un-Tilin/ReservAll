import 'package:flutter/material.dart';
import '/models/shop.dart';
import 'package:intl/intl.dart';

class BookingCreateScreen extends StatefulWidget {
  const BookingCreateScreen({super.key});

  @override
  State<BookingCreateScreen> createState() => _BookingCreateScreenState();
}

class _BookingCreateScreenState extends State<BookingCreateScreen> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  Widget build(BuildContext context) {
    final Shop negocio = ModalRoute.of(context)!.settings.arguments as Shop;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F1),
      appBar: AppBar(
        title: Text("Reservar en ${negocio.nombre}"),
        backgroundColor: const Color(0xFFE2725B),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Selecciona fecha y hora",
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B2118))),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE2725B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.calendar_today, color: Colors.white),
              label: Text(
                selectedDate == null
                    ? "Elegir fecha"
                    : DateFormat("dd/MM/yyyy").format(selectedDate!),
                style: const TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => selectedDate = picked);
                }
              },
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE2725B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.access_time, color: Colors.white),
              label: Text(
                selectedTime == null
                    ? "Elegir hora"
                    : selectedTime!.format(context),
                style: const TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null) {
                  setState(() => selectedTime = picked);
                }
              },
            ),
            const Spacer(),

            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE2725B),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (selectedDate != null && selectedTime != null) {
                    print("Reserva creada en ${negocio.nombre} "
                        "para ${DateFormat("dd/MM/yyyy").format(selectedDate!)} "
                        "a las ${selectedTime!.format(context)}");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Reserva confirmada"),
                        backgroundColor: Color(0xFFE2725B),
                      ),
                    );
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Selecciona fecha y hora"),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                child: const Text("Confirmar reserva",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
