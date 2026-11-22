import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/shop.dart';
import '../../services/api_service.dart';
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
  String currentUserName = 'Cliente';

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

  Future <void> _loadCurrentUserName() async {
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

  String? _formatAddress(dynamic rawAddress) {
    if (rawAddress == null) return null;
    if (rawAddress is List && rawAddress.isNotEmpty) {
      return _formatAddress(rawAddress.first);
    }
    if (rawAddress is String) {
      final trimmed = rawAddress.trim();
      if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return null;
      return trimmed;
    }
    if (rawAddress is Map) {
      final map = Map<String, dynamic>.from(rawAddress);
      final direct = _formatAddress(
        map['direccion_completa'] ??
            map['formatted_address'] ??
            map['direccion'] ??
            map['direcciones_negocio'],
      );
      if (direct != null) return direct;

      final street = [
        map['direccion_calle'] ?? map['calle'] ?? map['street'],
        map['numero_local'] ?? map['numero_exterior'] ?? map['numero'],
        map['numero_interior'] ?? map['interior'],
      ]
          .where((v) => v != null && v.toString().trim().isNotEmpty)
          .map((v) => v.toString().trim())
          .join(' ');

      final colonia = map['colonia']?.toString().trim();
      final city = map['ciudad']?.toString().trim();
      final state = map['estado']?.toString().trim();
      final postalCode =
          (map['codigo_postal'] ?? map['cp'])?.toString().trim();

      final parts = <String>[];
      if (street.isNotEmpty) parts.add(street);
      if (colonia != null && colonia.isNotEmpty) parts.add(colonia);
      if (city != null && city.isNotEmpty) parts.add(city);
      if (state != null && state.isNotEmpty) parts.add(state);
      if (postalCode != null && postalCode.isNotEmpty) {
        parts.add("C.P. $postalCode");
      }

      if (parts.isNotEmpty) return parts.join(', ');
    }
    return null;
  }

  String? _resolveShopAddress(Map<String, dynamic> source) {
    final negocioMap = source['negocio'] is Map
        ? Map<String, dynamic>.from(source['negocio'] as Map)
        : <String, dynamic>{};
    final shopMap = source['shop'] is Map
        ? Map<String, dynamic>.from(source['shop'] as Map)
        : <String, dynamic>{};
    final dataMap = source['data'] is Map
        ? Map<String, dynamic>.from(source['data'] as Map)
        : <String, dynamic>{};

    final candidates = [
      source['direcciones_negocio'],
      source['direccion'],
      source['ubicacion'],
      source['direccion_negocio'],
      source['address'],
      source['direccion_obj'],
      negocioMap['direcciones_negocio'],
      negocioMap['direccion'],
      negocioMap['ubicacion'],
      negocioMap['direccion_obj'],
      shopMap['direcciones_negocio'],
      shopMap['direccion'],
      shopMap['ubicacion'],
      dataMap['direcciones_negocio'],
      dataMap['direccion'],
      dataMap['ubicacion'],
    ];

    for (final candidate in candidates) {
      final formatted = _formatAddress(candidate);
      if (formatted != null) return formatted;
    }

    return _formatAddress(source);
  }

  String? _resolveImageUrl(dynamic rawImage) {
    if (rawImage == null) return null;
    final img = rawImage.toString().trim();
    if (img.isEmpty || img.toLowerCase() == 'null') return null;
    if (img.startsWith('http://') || img.startsWith('https://')) {
      return img;
    }
    if (img.startsWith('/')) {
      return "$baseUrl$img";
    }
    return "$baseUrl/static/$img";
  }

  Future<void> _fetchReservations() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse("$baseUrl/client/reservations"),
        headers: headers,
      );

      if (!mounted) return;

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
        final detail = _extractErrorDetail(
          response.body,
          (response.statusCode == 401 || response.statusCode == 403)
              ? 'No tienes permiso para consultar estas reservas.'
              : 'No se pudieron cargar las reservas',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $detail"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
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

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Reserva cancelada correctamente."),
            backgroundColor: Colors.green,
          ),
        );
        _fetchReservations();
      } else {
        final detail = _extractErrorDetail(
          response.body,
          (response.statusCode == 401 || response.statusCode == 403)
              ? 'Solo el usuario propietario de la reserva puede modificarla.'
              : 'No se pudo cancelar',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $detail"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error de conexión al cancelar."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _resolveClientName(Map<String, dynamic> res) {
    final clienteObj = res['cliente'] is Map
        ? Map<String, dynamic>.from(res['cliente'] as Map)
        : <String, dynamic>{};
    final usuarioObj = res['usuario'] is Map
        ? Map<String, dynamic>.from(res['usuario'] as Map)
        : <String, dynamic>{};

    final fromReservation = _extractNameFromJson(res['cliente_nombre']) ??
        _extractNameFromJson(res['nombre_cliente']) ??
        _extractNameFromJson(res['usuario_nombre']) ??
        _extractNameFromJson(clienteObj) ??
        _extractNameFromJson(usuarioObj) ??
        (res['cliente'] is String ? _extractNameFromJson(res['cliente']) : null);

    if (fromReservation != null && fromReservation.isNotEmpty) {
      return fromReservation;
    }

    if (currentUserName.trim().isNotEmpty) {
      return currentUserName.trim();
    }

    return 'Cliente';
  }

  Shop? _buildTargetShop({
    required dynamic negocioId,
    required String nombreNegocio,
    String? direccionNegocio,
    String? imagenNegocio,
    Shop? fetchedShop,
    Map<String, dynamic>? shopRawData,
  }) {
    if (fetchedShop != null) return fetchedShop;
    if (negocioId == null && shopRawData == null) return null;

    final baseMap = <String, dynamic>{
      if (shopRawData != null) ...shopRawData,
      'id': shopRawData?['id'] ?? shopRawData?['id_negocio'] ?? negocioId,
      'id_negocio':
          shopRawData?['id_negocio'] ?? shopRawData?['id'] ?? negocioId,
      'nombre': nombreNegocio,
      if (direccionNegocio != null &&
          direccionNegocio != "Ubicación no especificada" &&
          direccionNegocio != "Cargando ubicación...")
        'direccion': direccionNegocio,
      if (imagenNegocio != null && imagenNegocio.isNotEmpty)
        'imagenNegocio': imagenNegocio,
    };

    return Shop.fromJson(baseMap);
  }

  void _openBusinessDetail({
    required dynamic negocioId,
    required String nombreNegocio,
    String? direccionNegocio,
    String? imagenNegocio,
    Shop? fetchedShop,
    Map<String, dynamic>? shopRawData,
  }) {
    final targetShop = _buildTargetShop(
      negocioId: negocioId,
      nombreNegocio: nombreNegocio,
      direccionNegocio: direccionNegocio,
      imagenNegocio: imagenNegocio,
      fetchedShop: fetchedShop,
      shopRawData: shopRawData,
    );
    if (targetShop == null) return;

    Navigator.pushNamed(
      context,
      '/businessDetail',
      arguments: targetShop,
    );
  }

  void _openBusinessMap({
    required Shop? targetShop,
    required String direccionNegocio,
  }) {
    if (targetShop == null || !targetShop.hasCoordinates) return;

    final formattedAddress = (direccionNegocio != "Ubicación no especificada" &&
            direccionNegocio != "Cargando ubicación...")
        ? direccionNegocio
        : targetShop.direccion;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BusinessMapScreen(
          shop: targetShop,
          formattedAddress: formattedAddress,
        ),
      ),
    );
  }

  void _showReservationDetail(Map<String, dynamic> res) {
    final id = res['id_reserva'] ?? res['id'];

    final negocioObj = res['negocio'] is Map
        ? Map<String, dynamic>.from(res['negocio'] as Map)
        : <String, dynamic>{};

    final dynamic negocioId =
        res['negocio_id'] ??
        res['id_negocio'] ??
        negocioObj['id'] ??
        negocioObj['id_negocio'] ??
        res['id_shop'] ??
        res['shop_id'];

    final String initialNegocioName = (res['negocio_nombre'] ??
            negocioObj['nombre'] ??
            negocioObj['name'] ??
            'Negocio')
        .toString();

    final servicioObj = res['servicio'] is Map
        ? Map<String, dynamic>.from(res['servicio'] as Map)
        : <String, dynamic>{};

    final servicio = (res['servicio_nombre'] ??
            servicioObj['nombre'] ??
            servicioObj['name'] ??
            'Servicio agendado')
        .toString();

    final cliente = _resolveClientName(res);
    final fecha = res['fecha']?.toString() ?? '';
    final horaRaw =
        res['hora_inicio']?.toString() ?? res['hora']?.toString() ?? '';
    final hora = horaRaw.length >= 5 ? horaRaw.substring(0, 5) : horaRaw;

    final estado = (res['estado'] ?? 'Pendiente').toString();
    final comentarioRaw = res['comentario']?.toString().trim() ?? '';
    final comentario =
        comentarioRaw.isEmpty ? 'Sin comentarios adicionales' : comentarioRaw;

    final bool canCancel =
        estado.toLowerCase() == 'pendiente' ||
        estado.toLowerCase() == 'confirmada';

    final initialAddress = _resolveShopAddress(res);

    String nombreNegocio = initialNegocioName;
    String? imagenNegocio = _resolveImageUrl(
      res['imagen'] ?? negocioObj['imagenNegocio'] ?? negocioObj['imagen'],
    );
    String direccionNegocio = initialAddress ??
        (negocioId != null
            ? "Cargando ubicación..."
            : "Ubicación no especificada");
    String descripcionNegocio = "";
    Shop? fetchedShop;
    Map<String, dynamic>? fetchedShopMap;
    bool isLoadingShopData = negocioId != null;
    bool shopDataRequested = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> fetchShopInfo() async {
            if (negocioId == null) {
              if (!context.mounted) return;
              setModalState(() {
                direccionNegocio =
                    initialAddress ?? "Ubicación no especificada";
                isLoadingShopData = false;
              });
              return;
            }

            try {
              final shopDetail = await fetchShopDetail(negocioId);
              if (!context.mounted) return;

              final resolvedShop = shopDetail.resolvedShop;
              final formattedDetailAddress =
                  _formatAddress(shopDetail.direccion);
              final extraMap = <String, dynamic>{
                if (shopDetail.direccion != null)
                  'direccion': shopDetail.direccion,
              };
              final shopLocation =
                  resolvedShop.direccion?.trim().isNotEmpty == true
                      ? resolvedShop.direccion!.trim()
                      : (formattedDetailAddress ??
                          (resolvedShop.ciudad?.trim().isNotEmpty == true
                              ? resolvedShop.ciudad!.trim()
                              : (_resolveShopAddress(extraMap) ??
                                  initialAddress)));

              setModalState(() {
                fetchedShop = resolvedShop;
                fetchedShopMap = extraMap.isNotEmpty ? extraMap : null;
                nombreNegocio = resolvedShop.nombre.trim().isNotEmpty
                    ? resolvedShop.nombre.trim()
                    : initialNegocioName;
                imagenNegocio =
                    _resolveImageUrl(resolvedShop.imagenNegocio) ??
                        imagenNegocio;
                direccionNegocio = shopLocation ?? "Ubicación no especificada";
                if (resolvedShop.descripcion.trim().isNotEmpty) {
                  descripcionNegocio = resolvedShop.descripcion.trim();
                }
                isLoadingShopData = false;
              });
            } catch (_) {
              if (!context.mounted) return;
              setModalState(() {
                direccionNegocio =
                    initialAddress ?? "Ubicación no especificada";
                isLoadingShopData = false;
              });
            }
          }

          if (!shopDataRequested && isLoadingShopData) {
            shopDataRequested = true;
            Future.microtask(fetchShopInfo);
          }

          final currentTargetShop = _buildTargetShop(
            negocioId: negocioId,
            nombreNegocio: nombreNegocio,
            direccionNegocio: direccionNegocio,
            imagenNegocio: imagenNegocio,
            fetchedShop: fetchedShop,
            shopRawData:
                fetchedShopMap ?? (negocioObj.isNotEmpty ? negocioObj : null),
          );

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
                                    errorBuilder: (_, _, _) =>
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
                                        "Cargando ubicación...",
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
                  _detailRow(Icons.person_outline, "Cliente", cliente),
                  _detailRow(Icons.storefront, "Negocio", nombreNegocio),
                  _detailRow(Icons.cut, "Servicio", servicio),
                  _detailRow(Icons.calendar_today, "Fecha", fecha),
                  _detailRow(Icons.access_time, "Hora", hora),
                  _detailRow(Icons.info_outline, "Estado", estado),
                  _detailRow(Icons.comment, "Comentarios", comentario),
                  const SizedBox(height: 16),
                  if (currentTargetShop != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.storefront_outlined),
                        label: const Text(
                          "Ver negocio",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.pop(modalContext);
                          _openBusinessDetail(
                            negocioId: negocioId,
                            nombreNegocio: nombreNegocio,
                            direccionNegocio: direccionNegocio,
                            imagenNegocio: imagenNegocio,
                            fetchedShop: currentTargetShop,
                            shopRawData: fetchedShopMap ??
                                (negocioObj.isNotEmpty ? negocioObj : null),
                          );
                        },
                      ),
                    ),
                  if (currentTargetShop != null &&
                      currentTargetShop.hasCoordinates) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text(
                          "Ver en mapa",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.pop(modalContext);
                          _openBusinessMap(
                            targetShop: currentTargetShop,
                            direccionNegocio: direccionNegocio,
                          );
                        },
                      ),
                    ),
                  ],
                  if (canCancel && id != null) ...[
                    const SizedBox(height: 10),
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
                          Navigator.pop(modalContext);
                          _confirmCancelDialog(id);
                        },
                      ),
                    ),
                  ],
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
      builder: (dialogContext) => AlertDialog(
        title: const Text("¿Cancelar reserva?"),
        content: const Text(
          "Esta acción liberará el horario seleccionado y no se puede deshacer.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Volver"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(dialogContext);
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
        color: secondaryColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.store, color: secondaryColor, size: 30),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                                onTap: () => _showReservationDetail(item),
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