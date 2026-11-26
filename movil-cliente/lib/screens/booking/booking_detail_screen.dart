import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/shop.dart';
import '../../services/api_service.dart';
import '/screens/business/business_map_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final dynamic reservationId;
  final Map<String, dynamic>? reservation;

  const BookingDetailScreen({
    super.key,
    this.reservationId,
    this.reservation,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final Color primaryColor = const Color(0xFFE2725B);
  final Color secondaryColor = const Color(0xFF2A9D8F);
  final Color backgroundColor = const Color(0xFFFAF6F1);
  final Color surfaceColor = const Color(0xFFFFFFFF);
  final Color textMainColor = const Color(0xFF2B2118);
  final Color textSecondaryColor = const Color(0xFF7A7267);

  bool _initialized = false;
  bool _isLoading = false;
  bool _isCancelling = false;
  String? _errorMessage;

  dynamic _reservationId;
  Map<String, dynamic> _res = <String, dynamic>{};

  dynamic _extractIdFromMap(Map<dynamic, dynamic> map) {
    return map['id_reserva'] ??
        map['id'] ??
        map['reserva_id'] ??
        map['booking_id'];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    dynamic id = widget.reservationId;
    Map<String, dynamic> initialMap = <String, dynamic>{};

    if (widget.reservation != null) {
      initialMap = Map<String, dynamic>.from(widget.reservation!);
      id ??= _extractIdFromMap(initialMap);
    }

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final argMap = Map<String, dynamic>.from(args);
      if (argMap['reservation'] is Map) {
        final nested = Map<String, dynamic>.from(argMap['reservation'] as Map);
        initialMap = {...initialMap, ...nested};
        id ??= argMap['reservationId'] ??
            _extractIdFromMap(argMap) ??
            _extractIdFromMap(nested);
      } else {
        initialMap = {...initialMap, ...argMap};
        id ??= argMap['reservationId'] ?? _extractIdFromMap(argMap);
      }
    } else if (args != null) {
      id ??= args;
    }

    _reservationId = id;
    _res = initialMap;

    if (_reservationId != null) {
      _fetchReservationFromSupabase();
    } else if (_res.isEmpty) {
      _errorMessage = 'No se recibió la información de la reserva.';
    }
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionCookie = prefs.getString('session_cookie');

    final headers = <String, String>{
      'accept': 'application/json',
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
    };

    if (sessionCookie != null && sessionCookie.isNotEmpty) {
      headers['Cookie'] = sessionCookie;
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

  Map<String, dynamic>? _findReservationInResponse(dynamic decoded) {
    final targetId = _reservationId?.toString().trim();
    if (targetId == null || targetId.isEmpty) return null;

    List<dynamic> list = const [];
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map) {
      final rawList = decoded['reservas'] ??
          decoded['reservations'] ??
          decoded['items'] ??
          decoded['data'];
      if (rawList is List) {
        list = rawList;
      } else {
        final single = decoded['reservation'] ?? decoded['reserva'];
        if (single is Map) {
          return Map<String, dynamic>.from(single);
        }
        final candidateId = _extractIdFromMap(decoded)?.toString().trim();
        if (candidateId == targetId) {
          return Map<String, dynamic>.from(decoded);
        }
      }
    }

    for (final item in list) {
      if (item is Map) {
        final map = Map<String, dynamic>.from(item);
        final itemId = _extractIdFromMap(map)?.toString().trim();
        if (itemId == targetId) {
          return map;
        }
      }
    }
    return null;
  }

  Future<void> _fetchReservationFromSupabase() async {
    if (_reservationId == null || !mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/client/reservations'),
        headers: headers,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final found = _findReservationInResponse(decoded);
        setState(() {
          if (found != null) {
            _res = {..._res, ...found};
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = _extractErrorDetail(
            response.body,
            'No se pudo actualizar la reserva desde Supabase.',
          );
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error de conexión al consultar Supabase.';
      });
    }
  }

  String? _resolveImageUrl(dynamic rawImage) {
    final url = resolveImageUrl(rawImage);
    return url.isEmpty ? null : url;
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
        parts.add('C.P. $postalCode');
      }

      if (parts.isNotEmpty) return parts.join(', ');
    }
    return null;
  }

  Shop? _buildShopFromReservation() {
    final negocioObj = _res['negocio'] is Map
        ? Map<String, dynamic>.from(_res['negocio'] as Map)
        : const <String, dynamic>{};

    final negocioId = _res['negocio_id'] ??
        _res['id_negocio'] ??
        negocioObj['id'] ??
        negocioObj['id_negocio'];

    final nombre = (_res['negocio_nombre'] ??
            negocioObj['nombre'] ??
            negocioObj['name'] ??
            '')
        .toString()
        .trim();

    if (negocioId == null && nombre.isEmpty && negocioObj.isEmpty) {
      return null;
    }

    final direccion = _formatAddress(
      _res['direccion'] ??
          _res['direcciones_negocio'] ??
          negocioObj['direccion'] ??
          negocioObj['direcciones_negocio'],
    );

    final rawImg = _res['imagen'] ??
        negocioObj['imagenNegocio'] ??
        negocioObj['imagen'];

    final map = <String, dynamic>{
      ...negocioObj,
      if (negocioId != null) 'id': negocioObj['id'] ?? negocioId,
      if (negocioId != null) 'id_negocio': negocioObj['id_negocio'] ?? negocioId,
      if (nombre.isNotEmpty) 'nombre': nombre,
      'direccion': ?direccion,
      if (rawImg != null) 'imagenNegocio': _resolveImageUrl(rawImg) ?? rawImg,
    };

    return Shop.fromJson(map);
  }

  Future<void> _cancelReservation(dynamic reservationId) async {
    if (!mounted) return;
    setState(() => _isCancelling = true);

    try {
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/client/reservations/$reservationId/cancel'),
        headers: headers,
      );

      if (!mounted) return;
      setState(() => _isCancelling = false);

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reserva cancelada correctamente.'),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchReservationFromSupabase();
        if (mounted) {
          Navigator.pop(context, true);
        }
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
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error de conexión al cancelar.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmCancelDialog(dynamic reservationId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Cancelar reserva?'),
        content: const Text(
          'Esta acción liberará el horario seleccionado y no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(dialogContext);
              _cancelReservation(reservationId);
            },
            child: const Text(
              'Sí, cancelar',
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
            '$label: ',
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

  @override
  Widget build(BuildContext context) {
    final id = _extractIdFromMap(_res) ?? _reservationId;
    final negocioObj = _res['negocio'] is Map
        ? Map<String, dynamic>.from(_res['negocio'] as Map)
        : const <String, dynamic>{};
    final servicioObj = _res['servicio'] is Map
        ? Map<String, dynamic>.from(_res['servicio'] as Map)
        : const <String, dynamic>{};

    final business = (_res['negocio_nombre'] ??
            negocioObj['nombre'] ??
            negocioObj['name'] ??
            'Negocio')
        .toString();
    final service = (_res['servicio_nombre'] ??
            servicioObj['nombre'] ??
            servicioObj['name'] ??
            'Servicio')
        .toString();
    final date = (_res['fecha'] ??
            _res['fecha_reserva'] ??
            _res['fecha_cita'] ??
            '')
        .toString();
    final timeRaw = (_res['hora_inicio'] ?? _res['hora'] ?? '').toString();
    final time = timeRaw.length >= 5 ? timeRaw.substring(0, 5) : timeRaw;
    final status = (_res['estado'] ?? 'Pendiente').toString();
    final commentRaw = _res['comentario']?.toString().trim() ?? '';
    final comment =
        commentRaw.isEmpty ? 'Sin comentarios adicionales' : commentRaw;

    final bookedAtRaw = (_res['created_at'] ??
            _res['fecha_creacion'] ??
            _res['fecha_registro'] ??
            '')
        .toString()
        .trim();

    final addressText = _formatAddress(
      _res['direccion'] ??
          _res['direcciones_negocio'] ??
          negocioObj['direccion'] ??
          negocioObj['direcciones_negocio'],
    );
    final imageUrl = _resolveImageUrl(
      _res['imagen'] ?? negocioObj['imagenNegocio'] ?? negocioObj['imagen'],
    );
    final targetShop = _buildShopFromReservation();

    final canCancel =
        status.toLowerCase() == 'pendiente' ||
        status.toLowerCase() == 'confirmada';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Detalle de reserva'),
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Actualizar desde Supabase',
            onPressed: _fetchReservationFromSupabase,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading && _res.isEmpty
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              color: primaryColor,
              onRefresh: _fetchReservationFromSupabase,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  color: surfaceColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Detalle de Reserva',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textMainColor,
                              ),
                            ),
                            _buildStatusBadge(status),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: (imageUrl != null && imageUrl.isNotEmpty)
                                  ? Image.network(
                                      imageUrl,
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
                                    business,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textMainColor,
                                    ),
                                  ),
                                  if (addressText != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 14,
                                          color: primaryColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            addressText,
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
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _detailRow(Icons.storefront, 'Negocio', business),
                        _detailRow(Icons.cut, 'Servicio', service),
                        _detailRow(Icons.calendar_today, 'Fecha', date),
                        _detailRow(Icons.access_time, 'Hora', time),
                        if (bookedAtRaw.isNotEmpty &&
                            bookedAtRaw.toLowerCase() != 'null')
                          _detailRow(Icons.history, 'Reservado el', bookedAtRaw),
                        _detailRow(Icons.info_outline, 'Estado', status),
                        _detailRow(Icons.comment, 'Comentarios', comment),
                        const SizedBox(height: 16),
                        if (targetShop != null)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: secondaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.storefront_outlined),
                              label: const Text(
                                'Ver negocio',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/businessDetail',
                                  arguments: targetShop,
                                );
                              },
                            ),
                          ),
                        if (targetShop != null && targetShop.hasCoordinates) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                side: BorderSide(color: primaryColor),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.map_outlined),
                              label: const Text(
                                'Ver en mapa',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BusinessMapScreen(
                                      shop: targetShop,
                                      formattedAddress: addressText,
                                    ),
                                  ),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: _isCancelling
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.red,
                                      ),
                                    )
                                  : const Icon(Icons.cancel_outlined),
                              label: Text(
                                _isCancelling
                                    ? 'Cancelando...'
                                    : 'Cancelar reserva',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onPressed: _isCancelling
                                  ? null
                                  : () => _confirmCancelDialog(id),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}