import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '/models/shop.dart';
import '/services/api_service.dart';
import '/screens/business/business_map_screen.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  bool isLoading = true;
  List<dynamic> reservations = [];
  String selectedFilter = 'Todas';
  String currentUserName = 'Cliente (cuenta actual)';

  final Color primaryColor = const Color(0xFFE2725B);
  final Color secondaryColor = const Color(0xFF2A9D8F);
  final Color backgroundColor = const Color(0xFFFAF6F1);
  final Color surfaceColor = const Color(0xFFFFFFFF);
  final Color textMainColor = const Color(0xFF2B2118);
  final Color textSecondaryColor = const Color(0xFF7A7267);

  @override
  void initState() {
    super.initState();
    _loadCurrentUserName();
    _fetchReservations();
  }

  String? _extractNameFromJson(dynamic rawJson) {
    if (rawJson == null) return null;
    if (rawJson is String) {
      final trimmed = rawJson.trim();
      if (trimmed.isEmpty) return null;
      if (trimmed.startsWith('{')) {
        try {
          return _extractNameFromJson(jsonDecode(trimmed));
        } catch (_) {}
      }
      if (!trimmed.contains('@')) {
        return trimmed;
      }
      return null;
    }
    if (rawJson is Map) {
      final map = Map<String, dynamic>.from(rawJson);
      final candidate = map['nombre'] ??
          map['name'] ??
          map['full_name'] ??
          map['nombre_completo'] ??
          map['user_name'] ??
          map['cliente_nombre'] ??
          map['usuario_nombre'] ??
          map['user'] ??
          map['usuario'] ??
          map['cliente'];
      return _extractNameFromJson(candidate);
    }
    return null;
  }

  Future<void> _loadCurrentUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final directKeys = [
        'user_name',
        'nombre_usuario',
        'cliente_nombre',
        'usuario_nombre',
        'full_name',
        'nombre_completo',
        'name',
        'nombre',
      ];

      for (final key in directKeys) {
        final found = _extractNameFromJson(prefs.get(key));
        if (found != null && found.isNotEmpty) {
          if (!mounted) return;
          setState(() => currentUserName = found);
          return;
        }
      }

      final objectKeys = ['user', 'user_data', 'usuario', 'cliente', 'profile'];
      for (final key in objectKeys) {
        final found = _extractNameFromJson(prefs.get(key));
        if (found != null && found.isNotEmpty) {
          if (!mounted) return;
          setState(() => currentUserName = found);
          return;
        }
      }
    } catch (_) {}
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionCookie = prefs.getString('session_cookie');

    final headers = <String, String>{
      "accept": "application/json",
      "Content-Type": "application/json",
      "x-api-key": apiKey,
    };

    if (sessionCookie != null && sessionCookie.isNotEmpty) {
      headers["Cookie"] = sessionCookie;
    }
    return headers;
  }

  String _extractErrorDetail(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['detail'] != null) {
        return decoded['detail'].toString();
      }
    } catch (_) {}
    return fallback;
  }

  dynamic _extractReservationId(Map<dynamic, dynamic> res) {
    return res['id_reserva'] ??
        res['id'] ??
        res['reserva_id'] ??
        res['booking_id'];
  }

  dynamic _extractBusinessId(Map<dynamic, dynamic> res) {
    final negocioObj = res['negocio'] is Map
        ? Map<String, dynamic>.from(res['negocio'] as Map)
        : const <String, dynamic>{};
    return res['negocio_id'] ??
        res['id_negocio'] ??
        negocioObj['id_negocio'] ??
        negocioObj['id'] ??
        negocioObj['business_id'];
  }

  Future<List<dynamic>> _requestReservationsList() async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse("$baseUrl/client/reservations"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      debugPrint("RESERVAS_JSON: ${response.body}");
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map) {
        final list =
            data['reservas'] ?? data['reservations'] ?? data['items'] ?? [];
        if (list is List) return list;
      }
      return const [];
    }

    final detail = _extractErrorDetail(
      response.body,
      (response.statusCode == 401 || response.statusCode == 403)
          ? 'No tienes permiso para consultar estas reservas.'
          : 'No se pudieron cargar las reservas',
    );
    throw Exception(detail);
  }

  Future<void> _fetchReservations() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final parsedList = await _requestReservationsList();
      if (!mounted) return;
      setState(() {
        reservations = parsedList;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg.isNotEmpty ? "Error: $msg" : "Error de conexión con el servidor.",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _fetchSingleReservationFromSupabase(
    dynamic reservationId,
  ) async {
    if (reservationId == null) return null;
    final list = await _requestReservationsList();
    final targetId = reservationId.toString().trim();
    for (final raw in list) {
      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        final id = _extractReservationId(map)?.toString().trim();
        if (id == targetId) {
          return map;
        }
      }
    }
    return null;
  }

  Future<bool> _cancelReservationById(dynamic reservationId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/client/reservations/$reservationId/cancel'),
        headers: headers,
      );

      if (!mounted) return false;

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reserva cancelada correctamente.'),
            backgroundColor: Colors.green,
          ),
        );
        return true;
      } else {
        final detail = _extractErrorDetail(
          response.body,
          'No se pudo cancelar la reserva.',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $detail'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (_) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error de conexión al cancelar.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  String _getImageUrl(dynamic rawImage) => resolveImageUrl(rawImage);

  String? _buildAddressFromShopDetail(ShopDetail? shopDetail, Shop? resolvedShop) {
    final address = shopDetail?.direccion;
    if (address == null) {
      final raw = resolvedShop?.direccion?.trim() ?? '';
      return raw.isEmpty ? null : raw;
    }

    final street = [
      address['direccion_calle'],
      address['numero_local'],
      address['numero_interior'],
    ]
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .join(' ');
    final city = address['ciudad'];
    final state = address['estado'];

    final parts = <String>[];
    if (street.isNotEmpty) parts.add(street);
    if (city != null && city.toString().trim().isNotEmpty) {
      parts.add(city.toString());
    }
    if (state != null && state.toString().trim().isNotEmpty) {
      parts.add(state.toString());
    }

    if (parts.isNotEmpty) return parts.join(', ');
    final fallbackRaw = resolvedShop?.direccion?.trim() ?? '';
    return fallbackRaw.isEmpty ? null : fallbackRaw;
  }

  Shop? _buildFallbackShop(
    Map<String, dynamic> detailData,
    dynamic bizId,
    String businessName,
    String? addressText,
    String imageUrl,
  ) {
    final negocioObj = detailData['negocio'] is Map
        ? Map<String, dynamic>.from(detailData['negocio'] as Map)
        : const <String, dynamic>{};

    if (bizId == null && businessName.trim().isEmpty && negocioObj.isEmpty) {
      return null;
    }

    final map = <String, dynamic>{
      ...negocioObj,
      if (bizId != null) 'id': negocioObj['id'] ?? bizId,
      if (bizId != null) 'id_negocio': negocioObj['id_negocio'] ?? bizId,
      if (businessName.trim().isNotEmpty) 'nombre': businessName.trim(),
      if (addressText != null && addressText.isNotEmpty) 'direccion': addressText,
      if (imageUrl.isNotEmpty) 'imagenNegocio': imageUrl,
    };

    return Shop.fromJson(map);
  }

  Widget _modalFallbackIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: secondaryColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.storefront_outlined,
        color: secondaryColor,
        size: 28,
      ),
    );
  }

  Widget _modalInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: secondaryColor),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: textMainColor,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                color: textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openReservationDetail(Map<String, dynamic> initialItem) async {
    final resId = _extractReservationId(initialItem);

    final wasUpdated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        Map<String, dynamic> detailData = Map<String, dynamic>.from(initialItem);
        ShopDetail? shopDetail;
        Shop? resolvedShop;
        bool loadingFresh = true;
        bool cancelling = false;
        bool fetchedOnce = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            if (!fetchedOnce) {
              fetchedOnce = true;
              Future<void> loadAllData() async {
                Map<String, dynamic>? freshRes;
                if (resId != null) {
                  try {
                    freshRes = await _fetchSingleReservationFromSupabase(resId);
                  } catch (_) {}
                }

                final mergedRes = <String, dynamic>{
                  ...detailData,
                  ...?freshRes,
                };

                final bizId = _extractBusinessId(mergedRes);
                ShopDetail? fetchedDetail;
                Shop? fetchedShop;

                if (bizId != null) {
                  try {
                    fetchedDetail = await fetchShopDetail(bizId);
                    fetchedShop = fetchedDetail.resolvedShop;
                  } catch (_) {}
                }

                if (!context.mounted) return;
                setModalState(() {
                  detailData = mergedRes;
                  if (fetchedDetail != null) {
                    shopDetail = fetchedDetail;
                    resolvedShop = fetchedShop;
                  }
                  loadingFresh = false;
                });
              }

              loadAllData();
            }

            final negocioObj = detailData['negocio'] is Map
                ? Map<String, dynamic>.from(detailData['negocio'] as Map)
                : const <String, dynamic>{};
            final servicioObj = detailData['servicio'] is Map
                ? Map<String, dynamic>.from(detailData['servicio'] as Map)
                : const <String, dynamic>{};

            final bizId = _extractBusinessId(detailData);
            final business = (resolvedShop?.nombre.trim().isNotEmpty == true
                    ? resolvedShop!.nombre
                    : (detailData['negocio_nombre'] ??
                            negocioObj['nombre'] ??
                            negocioObj['name'] ??
                            'Negocio'))
                .toString();
            final service = (detailData['servicio_nombre'] ??
                    servicioObj['nombre'] ??
                    servicioObj['name'] ??
                    'Servicio')
                .toString();
            final clientName = (detailData['cliente_nombre'] ??
                    detailData['usuario_nombre'] ??
                    currentUserName)
                .toString();

            final addressText =
                _buildAddressFromShopDetail(shopDetail, resolvedShop);
            final address = addressText ?? 'Ubicación no especificada';

            final imageUrl = _getImageUrl(
              resolvedShop?.imagenNegocio ??
                  detailData['imagen'] ??
                  negocioObj['imagenNegocio'] ??
                  negocioObj['imagen'],
            );

            final shopForNavigation = resolvedShop ??
                _buildFallbackShop(
                  detailData,
                  bizId,
                  business,
                  addressText,
                  imageUrl,
                );

            final date = (detailData['fecha'] ??
                    detailData['fecha_reserva'] ??
                    detailData['fecha_cita'] ??
                    '')
                .toString();
            final timeRaw = (detailData['hora_inicio'] ??
                    detailData['hora'] ??
                    '')
                .toString();
            final time =
                timeRaw.length >= 5 ? timeRaw.substring(0, 5) : timeRaw;
            final status = (detailData['estado'] ?? 'pendiente').toString();
            final commentRaw = detailData['comentario']?.toString().trim() ?? '';
            final comment =
                commentRaw.isEmpty ? 'Sin comentarios adicionales' : commentRaw;

            final canCancel = status.toLowerCase() == 'pendiente' ||
                status.toLowerCase() == 'confirmada';
            final canShowRoute =
                shopForNavigation != null && shopForNavigation.hasCoordinates;

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Detalle de Reserva',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textMainColor,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (loadingFresh) ...[
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: secondaryColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            _buildStatusBadge(status),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _modalFallbackIcon(),
                                )
                              : _modalFallbackIcon(),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                business,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textMainColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: primaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      address,
                                      style: TextStyle(
                                        fontSize: 12.5,
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
                    const SizedBox(height: 18),
                    _modalInfoRow(
                      Icons.person_outline,
                      'Cliente',
                      clientName,
                    ),
                    _modalInfoRow(
                      Icons.storefront_outlined,
                      'Negocio',
                      business,
                    ),
                    _modalInfoRow(
                      Icons.content_cut,
                      'Servicio',
                      service,
                    ),
                    _modalInfoRow(
                      Icons.calendar_today_outlined,
                      'Fecha',
                      date,
                    ),
                    _modalInfoRow(
                      Icons.access_time,
                      'Hora',
                      time,
                    ),
                    _modalInfoRow(
                      Icons.info_outline,
                      'Estado',
                      status.toLowerCase(),
                    ),
                    _modalInfoRow(
                      Icons.notes,
                      'Comentarios',
                      comment,
                    ),
                    if (shopForNavigation != null) ...[
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.storefront_outlined, size: 18),
                          label: const Text(
                            'Ver negocio',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onPressed: () {
                            Navigator.pop(sheetContext, false);
                            Navigator.pushNamed(
                              context,
                              '/businessDetail',
                              arguments: shopForNavigation,
                            );
                          },
                        ),
                      ),
                    ],
                    if (canShowRoute) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.route, size: 18),
                          label: const Text(
                            'Ver ruta al negocio',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onPressed: () {
                            Navigator.pop(sheetContext, false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BusinessMapScreen(
                                  shop: shopForNavigation,
                                  formattedAddress: addressText,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    if (canCancel && resId != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: cancelling
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.red.shade700,
                                  ),
                                )
                              : const Icon(Icons.cancel_outlined, size: 18),
                          label: Text(
                            cancelling ? 'Cancelando...' : 'Cancelar Reserva',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onPressed: cancelling
                              ? null
                              : () async {
                                  setModalState(() => cancelling = true);
                                  final ok = await _cancelReservationById(resId);
                                  if (!context.mounted) return;
                                  setModalState(() => cancelling = false);
                                  if (ok) {
                                    Navigator.pop(sheetContext, true);
                                  }
                                },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (wasUpdated == true && mounted) {
      _fetchReservations();
    }
  }

  Widget _buildStatusBadge(String estado) {
    Color bgColor = Colors.orange.shade100;
    Color txtColor = Colors.orange.shade900;

    final lower = estado.toLowerCase();
    if (lower == 'confirmada' ||
        lower == 'completada' ||
        lower == 'finalizada' ||
        lower == 'realizada') {
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

  Widget _buildTopBanner(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      color: primaryColor,
      padding: EdgeInsets.fromLTRB(20, topInset + 10, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Mis Reservas",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          IconButton(
            tooltip: "Favoritos",
            onPressed: () => Navigator.pushNamed(context, '/favorites'),
            icon: const Icon(
              Icons.favorite,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> get _filteredReservations {
    final onlyMaps = reservations.whereType<Map>().toList();
    if (selectedFilter == 'Todas') return onlyMaps;
    return onlyMaps.where((r) {
      final estado = (r['estado'] ?? '').toString().toLowerCase();
      if (selectedFilter == 'Próximas') {
        return estado == 'pendiente' || estado == 'confirmada';
      }
      return estado == 'cancelada';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredReservations;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          _buildTopBanner(context),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: ['Todas', 'Próximas', 'Canceladas'].map((filter) {
                final isSelected = selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: secondaryColor,
                    backgroundColor: surfaceColor,
                    showCheckmark: isSelected,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected
                            ? secondaryColor
                            : Colors.grey.shade300,
                      ),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : textMainColor,
                      fontWeight: FontWeight.w500,
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
                            final item =
                                Map<String, dynamic>.from(list[index] as Map);

                            final negocioObj = item['negocio'] is Map
                                ? Map<String, dynamic>.from(
                                    item['negocio'] as Map,
                                  )
                                : <String, dynamic>{};
                            final servicioObj = item['servicio'] is Map
                                ? Map<String, dynamic>.from(
                                    item['servicio'] as Map,
                                  )
                                : <String, dynamic>{};

                            final negocio = (item['negocio_nombre'] ??
                                    negocioObj['nombre'] ??
                                    negocioObj['name'] ??
                                    'Negocio')
                                .toString();
                            final servicio = (item['servicio_nombre'] ??
                                    servicioObj['nombre'] ??
                                    servicioObj['name'] ??
                                    'Servicio')
                                .toString();

                            final fecha = item['fecha']?.toString() ?? '';
                            final horaRaw = item['hora_inicio']?.toString() ??
                                item['hora']?.toString() ??
                                '';
                            final hora = horaRaw.length >= 5
                                ? horaRaw.substring(0, 5)
                                : horaRaw;
                            final estado =
                                (item['estado'] ?? 'Pendiente').toString();

                            return Card(
                              color: surfaceColor,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                onTap: () => _openReservationDetail(item),
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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