import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '/models/shop.dart';
import '/services/api_service.dart';
import '/services/service_description_helper.dart';

class BookingCreateScreen extends StatefulWidget {
  const BookingCreateScreen({super.key});

  @override
  State<BookingCreateScreen> createState() => _BookingCreateScreenState();
}

class _BookingCreateScreenState extends State<BookingCreateScreen> {
  bool isLoading = false;
  bool isLoadingTimes = false;
  Shop? shop;
  ShopDetail? detail;

  List<int> selectedServiceIds = [];

  DateTime selectedDate = DateTime.now();
  String? selectedTime;
  List<String> availableTimes = [];

  final TextEditingController commentController = TextEditingController();

  final Color primaryColor = const Color(0xFFE2725B);
  final Color secondaryColor = const Color(0xFF2A9D8F);
  final Color backgroundColor = const Color(0xFFFAF6F1);
  final Color surfaceColor = const Color(0xFFFFFFFF);
  final Color textMainColor = const Color(0xFF2B2118);
  final Color textSecondaryColor = const Color(0xFF7A7267);

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (shop == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Shop) {
        shop = args;
        _loadShopDetail(shop!.id);
      } else if (args is Map) {
        shop = Shop.fromJson(Map<String, dynamic>.from(args));
        _loadShopDetail(shop!.id);
      }
    }
  }

  Future<void> _loadShopDetail(dynamic shopId) async {
    try {
      final result = await fetchShopDetail(shopId);
      if (!mounted) return;
      setState(() {
        detail = result;
      });
    } catch (e) {
      debugPrint("Error al cargar servicios del negocio: $e");
    }
  }

  int get _totalSelectedDurationMinutes {
    final servicios = detail?.servicios ?? [];
    int total = 0;
    for (final raw in servicios) {
      final sId =
          int.tryParse((raw['id_servicio'] ?? raw['id'] ?? '0').toString()) ??
          0;
      if (selectedServiceIds.contains(sId)) {
        final dur =
            int.tryParse(
              (raw['duracion_minutos'] ?? raw['duracion'] ?? '30').toString(),
            ) ??
            30;
        total += dur;
      }
    }
    return total > 0 ? total : 30;
  }

  int? _timeToMinutes(String hhmm) {
    final clean = hhmm.trim();
    if (clean.isEmpty) return null;
    final parts = clean.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  String _dayNameSpanish(DateTime date) {
    const days = [
      'lunes',
      'martes',
      'miercoles',
      'jueves',
      'viernes',
      'sabado',
      'domingo',
    ];
    return days[date.weekday - 1];
  }

  String _normalizeDay(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
  }

  List<String> _filterValidSlotsForSelectedServices(List<String> rawSlots) {
    final totalDuration = _totalSelectedDurationMinutes;
    final targetDay = _dayNameSpanish(selectedDate);
    final horarios = detail?.horarios ?? [];

    Map<String, dynamic>? daySchedule;
    for (final h in horarios) {
      if (_normalizeDay(h['dia']?.toString() ?? '') == targetDay) {
        daySchedule = Map<String, dynamic>.from(h);
        break;
      }
    }

    int? closeMinutes;
    if (daySchedule != null && daySchedule['hora_cierre'] != null) {
      closeMinutes = _timeToMinutes(daySchedule['hora_cierre'].toString());
    }

    int? breakStartMinutes;
    if (daySchedule != null && daySchedule['hora_descanso'] != null) {
      breakStartMinutes =
          _timeToMinutes(daySchedule['hora_descanso'].toString());
    }

    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
    final currentMinutes = now.hour * 60 + now.minute;

    return rawSlots.where((slot) {
      final startMin = _timeToMinutes(slot);
      if (startMin == null) return false;
      final endMin = startMin + totalDuration;

      if (isToday && startMin <= currentMinutes) return false;
      if (closeMinutes != null && closeMinutes > 0 && endMin > closeMinutes) {
        return false;
      }
      if (breakStartMinutes != null &&
          breakStartMinutes > 0 &&
          startMin < (breakStartMinutes + 30) &&
          endMin > breakStartMinutes) {
        return false;
      }
      return true;
    }).toList();
  }

  void _toggleService(int sId, bool shouldSelect) {
    if (sId <= 0) return;
    setState(() {
      if (shouldSelect) {
        if (!selectedServiceIds.contains(sId)) {
          selectedServiceIds.add(sId);
        }
      } else {
        selectedServiceIds.remove(sId);
      }
    });
    _fetchAvailableTimes();
  }

  String? _extractSlotString(dynamic slot) {
    if (slot == null) return null;
    String raw = '';
    if (slot is Map) {
      raw = (slot['hora_inicio'] ??
              slot['hora'] ??
              slot['inicio'] ??
              slot['horario'] ??
              slot['time'] ??
              '')
          .toString();
    } else {
      raw = slot.toString();
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.contains('T')) {
      final timePart = trimmed.split('T').last;
      return timePart.length >= 5 ? timePart.substring(0, 5) : timePart;
    }
    return trimmed.length >= 5 ? trimmed.substring(0, 5) : trimmed;
  }

  Future<void> _fetchAvailableTimes() async {
    if (shop == null || selectedServiceIds.isEmpty) {
      setState(() {
        availableTimes = [];
        selectedTime = null;
      });
      return;
    }

    setState(() {
      isLoadingTimes = true;
      selectedTime = null;
      availableTimes = [];
    });

    final dateStr =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    final primaryServiceId = selectedServiceIds.first;

    final url =
        "$baseUrl/client/${shop!.id}/available-times?fecha=$dateStr&servicio_id=$primaryServiceId";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"accept": "application/json", "x-api-key": apiKey},
      );

      debugPrint(
        "Available times [$url] -> ${response.statusCode}: ${response.body}",
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        dynamic rawList = const [];

        if (data is Map) {
          rawList = data['horarios_disponibles'] ??
              data['horarios'] ??
              data['slots'] ??
              data['disponibles'] ??
              data['items'] ??
              (data['data'] is Map
                  ? (data['data']['horarios_disponibles'] ??
                      data['data']['horarios'] ??
                      data['data']['slots'] ??
                      data['data']['items'] ??
                      [])
                  : (data['data'] ?? []));
        } else if (data is List) {
          rawList = data;
        }

        final List<String> parsedSlots = (rawList is List ? rawList : const [])
            .map(_extractSlotString)
            .whereType<String>()
            .toSet()
            .toList();

        final filteredSlots = _filterValidSlotsForSelectedServices(parsedSlots);

        setState(() {
          availableTimes = filteredSlots;
          isLoadingTimes = false;
        });
      } else {
        if (!mounted) return;
        setState(() => isLoadingTimes = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al cargar horarios (${response.statusCode})"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingTimes = false);
      debugPrint("Error de conexión al buscar horarios: $e");
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != selectedDate) {
      if (!mounted) return;
      setState(() {
        selectedDate = picked;
      });
      _fetchAvailableTimes();
    }
  }

  Future<void> _submitBooking() async {
    if (selectedServiceIds.isEmpty || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Por favor selecciona al menos un servicio y un horario disponible.",
          ),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    String? sessionCookie = prefs.getString('session_cookie');

    final currentShop = shop;
    if (currentShop == null) {
      setState(() => isLoading = false);
      return;
    }

    final dateStr =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    final Map<String, dynamic> bodyData = {
      "negocio_id": currentShop.id,
      "servicios_ids": selectedServiceIds,
      "servicio_id": selectedServiceIds.first,
      "fecha": dateStr,
      "hora_inicio": selectedTime,
      "comentario": commentController.text.trim().isEmpty
          ? null
          : commentController.text.trim(),
    };

    Map<String, String> headers = {
      "accept": "application/json",
      "Content-Type": "application/json",
      "x-api-key": apiKey,
    };

    if (sessionCookie != null) {
      headers["Cookie"] = sessionCookie;
    }

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/client/reservations"),
        headers: headers,
        body: jsonEncode(bodyData),
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text("¡Reserva Exitosa!"),
            content: Text(
              "Tu cita quedó registrada para el $dateStr a las $selectedTime.\n\nEl espacio ha sido bloqueado en la agenda.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: const Text("Aceptar"),
              ),
            ],
          ),
        );
      } else {
        String errorMsg = "No se pudo procesar la reserva.";
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map) {
            final detail = decoded['detail'] ?? decoded['message'];
            if (detail is List) {
              errorMsg = detail
                  .map((item) => item is Map ? item['msg'] ?? item : item)
                  .join('\n');
            } else if (detail != null) {
              errorMsg = detail.toString();
            }
          }
        } catch (_) {}

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $errorMsg"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      debugPrint("Error al enviar la reserva: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error de conexión al enviar la reserva."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (shop == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Reservar Cita"),
          backgroundColor: primaryColor,
        ),
        body: const Center(
          child: Text("Error: No se encontró información del negocio."),
        ),
      );
    }

    final servicios = detail?.servicios ?? [];
    final dateStr =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "Reservar en ${shop!.nombre}",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "1. Selecciona los servicios",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textMainColor,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Puedes elegir uno o varios servicios para tu cita.",
              style: TextStyle(fontSize: 12, color: textSecondaryColor),
            ),
            const SizedBox(height: 10),
            servicios.isEmpty
                ? const Text("Cargando servicios del negocio...")
                : Column(
                    children: servicios.map((servicio) {
                      final servicioMap = Map<String, dynamic>.from(
                        servicio as Map,
                      );
                      final int sId =
                          int.tryParse(
                            (servicioMap['id_servicio'] ??
                                    servicioMap['id'] ??
                                    '0')
                                .toString(),
                          ) ??
                          0;
                      final String sName =
                          servicioMap['nombre']?.toString() ?? 'Servicio';
                      final String sDesc = ServiceDescriptionHelper.resolve(
                        raw: servicioMap,
                        serviceId: sId > 0 ? sId : null,
                        serviceName: sName,
                      );
                      final sPrice = servicioMap['precio'];
                      final duracion = servicioMap['duracion_minutos'];
                      final isSelected = selectedServiceIds.contains(sId);

                      return GestureDetector(
                        onTap: () => _toggleService(sId, !isSelected),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? primaryColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                activeColor: primaryColor,
                                onChanged: (bool? value) {
                                  _toggleService(sId, value == true);
                                },
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: textMainColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      sDesc,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: textSecondaryColor,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        if (sPrice != null)
                                          Text(
                                            "Precio: \$$sPrice",
                                            style: TextStyle(
                                              color: primaryColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        if (duracion != null) ...[
                                          const SizedBox(width: 12),
                                          Text(
                                            "$duracion min",
                                            style: TextStyle(
                                              color: textSecondaryColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
            if (selectedServiceIds.length > 1) ...[
              const SizedBox(height: 4),
              Text(
                "${selectedServiceIds.length} servicios seleccionados · Duración total: $_totalSelectedDurationMinutes min",
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: secondaryColor,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              "2. Selecciona la fecha",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textMainColor,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, color: Colors.white),
              label: Text(
                "Fecha: $dateStr",
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "3. Horarios disponibles",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textMainColor,
              ),
            ),
            const SizedBox(height: 10),
            if (selectedServiceIds.isEmpty)
              Text(
                "Primero selecciona al menos un servicio.",
                style: TextStyle(color: textSecondaryColor),
              )
            else if (isLoadingTimes)
              CircularProgressIndicator(color: primaryColor)
            else if (availableTimes.isEmpty)
              Text(
                "No hay horarios disponibles para esta fecha.",
                style: TextStyle(color: textSecondaryColor),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableTimes.map((timeStr) {
                  final isSelectedTime = selectedTime == timeStr;
                  return ChoiceChip(
                    label: Text(timeStr),
                    selected: isSelectedTime,
                    selectedColor: primaryColor,
                    labelStyle: TextStyle(
                      color: isSelectedTime ? Colors.white : textMainColor,
                      fontWeight:
                          isSelectedTime ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      setState(() => selectedTime = timeStr);
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: 20),
            Text(
              "4. Comentario adicional (Opcional)",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textMainColor,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: commentController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: "Ej. Notas para el negocio...",
                filled: true,
                fillColor: surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isLoading ? null : _submitBooking,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Confirmar y Guardar Reserva",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}