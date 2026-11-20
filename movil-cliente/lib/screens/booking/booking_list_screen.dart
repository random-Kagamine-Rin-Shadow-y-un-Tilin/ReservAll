import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  bool isLoading = true;
  List<dynamic> reservations = [];
  String selectedFilter = 'Todas';

  final Color primaryColor = const Color(0xFFE2725B);
  final Color secondaryColor = const Color(0xFF2A9D8F);
  final Color backgroundColor = const Color(0xFFFAF6F1);
  final Color surfaceColor = const Color(0xFFFFFFFF);
  final Color textMainColor = const Color(0xFF2B2118);
  final Color textSecondaryColor = const Color(0xFF7A7267);

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionCookie = prefs.getString('session_cookie');

    final headers = <String, String>{
      "accept": "application/json",
      "Content-Type": "application/json",
      "x-api-key": apiKey,
    };

    if (sessionCookie != null) {
      headers["Cookie"] = sessionCookie;
    }
    return headers;
  }

  Future<void> _fetchReservations() async {
    setState(() => isLoading = true);

    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse("$baseUrl/client/reservations"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data is List) {
            reservations = data;
          } else if (data is Map) {
            reservations =
                data['reservas'] ?? data['reservations'] ?? data['items'] ?? [];
          }
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        final errorBody = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error: ${errorBody['detail'] ?? 'No se pudieron cargar las reservas'}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error de conexión con el servidor."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelReservation(dynamic reservationId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse("$baseUrl/client/reservations/$reservationId/cancel"),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Reserva cancelada correctamente."),
            backgroundColor: Colors.green,
          ),
        );
        _fetchReservations();
      } else {
        final errorBody = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error: ${errorBody['detail'] ?? 'No se pudo cancelar'}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error de conexión al cancelar."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showReservationDetail(Map<String, dynamic> res) {
    final id = res['id_reserva'] ?? res['id'];

    final negocioObj = res['negocio'] is Map ? res['negocio'] : {};

    final dynamic negocioId =
        res['negocio_id'] ??
        res['id_negocio'] ??
        negocioObj['id'] ??
        negocioObj['id_negocio'] ??
        res['id_shop'] ??
        res['shop_id'];

    final String initialNegocioName =
        res['negocio_nombre'] ??
        negocioObj['nombre'] ??
        negocioObj['name'] ??
        'Negocio';
    final servicio =
        res['servicio_nombre'] ??
        res['servicio']?['nombre'] ??
        'Servicio agendado';

    final fecha = res['fecha']?.toString() ?? '';
    final horaRaw =
        res['hora_inicio']?.toString() ?? res['hora']?.toString() ?? '';
    final hora = horaRaw.length >= 5 ? horaRaw.substring(0, 5) : horaRaw;

    final estado = (res['estado'] ?? 'Pendiente').toString();
    final comentario =
        res['comentario']?.toString() ?? 'Sin comentarios adicionales';

    final bool canCancel =
        estado.toLowerCase() == 'pendiente' ||
        estado.toLowerCase() == 'confirmada';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          String nombreNegocio = initialNegocioName;
          String? imagenNegocio;
          String direccionNegocio = "Cargando ubicación...";
          String descripcionNegocio = "";
          bool isLoadingShopData = true;

          void fetchShopInfo() async {
            if (negocioId == null) {
              setModalState(() {
                direccionNegocio =
                    res['direccion'] ??
                    negocioObj['direccion'] ??
                    "Ubicación no especificada";
                imagenNegocio = res['imagen'] ?? negocioObj['imagenNegocio'];
                isLoadingShopData = false;
              });
              return;
            }

            try {
              final headers = await _getAuthHeaders();
              final response = await http.get(
                Uri.parse("$baseUrl/client/business/$negocioId"),
                headers: headers,
              );

              if (response.statusCode == 200) {
                final shopData = jsonDecode(response.body);
                setModalState(() {
                  nombreNegocio =
                      shopData['nombre'] ??
                      shopData['name'] ??
                      initialNegocioName;
                  imagenNegocio =
                      shopData['imagenNegocio'] ??
                      shopData['imagen'] ??
                      shopData['foto'] ??
                      shopData['image'];
                  direccionNegocio =
                      shopData['direccion'] ??
                      shopData['ubicacion'] ??
                      "Ubicación no especificada";
                  descripcionNegocio =
                      shopData['descripcion'] ?? shopData['description'] ?? "";
                  isLoadingShopData = false;
                });
              } else {
                setModalState(() {
                  direccionNegocio =
                      res['direccion'] ??
                      negocioObj['direccion'] ??
                      "Ubicación no especificada";
                  isLoadingShopData = false;
                });
              }
            } catch (e) {
              setModalState(() {
                direccionNegocio =
                    res['direccion'] ??
                    negocioObj['direccion'] ??
                    "Ubicación no especificada";
                isLoadingShopData = false;
              });
            }
          }

          if (isLoadingShopData) {
            Future.microtask(() => fetchShopInfo());
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Detalle de Reserva",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textMainColor,
                        ),
                      ),
                      _buildStatusBadge(estado),
                    ],
                  ),
                  const Divider(height: 24),

                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child:
                            (imagenNegocio != null && imagenNegocio!.isNotEmpty)
                            ? Image.network(
                                imagenNegocio!,
                                width: 65,
                                height: 65,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _placeholderImage(),
                              )
                            : _placeholderImage(),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombreNegocio,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textMainColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            isLoadingShopData
                                ? Row(
                                    children: [
                                      SizedBox(
                                        height: 12,
                                        width: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Cargando detalles...",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 14,
                                        color: primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          direccionNegocio,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textSecondaryColor,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (descripcionNegocio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      descripcionNegocio,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondaryColor,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 20),

                  _detailRow(Icons.cut, "Servicio reservado", servicio),
                  _detailRow(Icons.calendar_today, "Fecha de cita", fecha),
                  _detailRow(Icons.access_time, "Hora de cita", hora),
                  _detailRow(Icons.comment, "Comentarios", comentario),
                  const SizedBox(height: 20),

                  if (canCancel)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text(
                          "Cancelar Reserva",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmCancelDialog(id);
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmCancelDialog(dynamic reservationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Cancelar reserva?"),
        content: const Text(
          "Esta acción liberará el horario seleccionado y no se puede deshacer.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Volver"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _cancelReservation(reservationId);
            },
            child: const Text(
              "Sí, cancelar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        color: secondaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.store, color: secondaryColor, size: 30),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: secondaryColor),
          const SizedBox(width: 12),
          Text(
            "$label: ",
            style: TextStyle(fontWeight: FontWeight.bold, color: textMainColor),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: textSecondaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String estado) {
    Color bgColor = Colors.orange.shade100;
    Color txtColor = Colors.orange.shade900;

    final lower = estado.toLowerCase();
    if (lower == 'confirmada' || lower == 'completada') {
      bgColor = Colors.green.shade100;
      txtColor = Colors.green.shade900;
    } else if (lower == 'cancelada') {
      bgColor = Colors.red.shade100;
      txtColor = Colors.red.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: txtColor,
        ),
      ),
    );
  }

  List<dynamic> get _filteredReservations {
    if (selectedFilter == 'Todas') return reservations;
    return reservations.where((r) {
      final estado = (r['estado'] ?? '').toString().toLowerCase();
      if (selectedFilter == 'Próximas') {
        return estado == 'pendiente' || estado == 'confirmada';
      }
      return estado == 'cancelada' || estado == 'completada';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredReservations;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Mis Reservas",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: ['Todas', 'Próximas', 'Canceladas'].map((filter) {
                final isSelected = selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: secondaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : textMainColor,
                    ),
                    onSelected: (_) => setState(() => selectedFilter = filter),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : list.isEmpty
                ? Center(
                    child: Text(
                      "No tienes reservas en esta categoría.",
                      style: TextStyle(color: textSecondaryColor),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchReservations,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final item = Map<String, dynamic>.from(list[index]);

                        final negocioObj = item['negocio'] is Map
                            ? item['negocio']
                            : {};
                        final servicioObj = item['servicio'] is Map
                            ? item['servicio']
                            : {};

                        final negocio =
                            item['negocio_nombre'] ??
                            negocioObj['nombre'] ??
                            negocioObj['name'] ??
                            'Negocio';
                        final servicio =
                            item['servicio_nombre'] ??
                            servicioObj['nombre'] ??
                            servicioObj['name'] ??
                            'Servicio';

                        final fecha = item['fecha']?.toString() ?? '';
                        final horaRaw =
                            item['hora_inicio']?.toString() ??
                            item['hora']?.toString() ??
                            '';
                        final hora = horaRaw.length >= 5
                            ? horaRaw.substring(0, 5)
                            : horaRaw;
                        final estado = (item['estado'] ?? 'Pendiente')
                            .toString();

                        return Card(
                          color: surfaceColor,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            onTap: () => _showReservationDetail(item),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    negocio,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: textMainColor,
                                    ),
                                  ),
                                ),
                                _buildStatusBadge(estado),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    servicio,
                                    style: TextStyle(
                                      color: textMainColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "📅 $fecha   •   🕒 $hora",
                                    style: TextStyle(
                                      color: textSecondaryColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: textSecondaryColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
