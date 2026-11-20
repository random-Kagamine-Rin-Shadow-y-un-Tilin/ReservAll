import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/service_model.dart';
import '../../services/api_service.dart';
import '../../services/service_description_helper.dart';

class ServiceDetailScreen extends StatefulWidget {
  final int serviceId;
  final ServiceModel? initialService;
  final String? businessName;
  final VoidCallback? onReserveTap;

  const ServiceDetailScreen({
    super.key,
    required this.serviceId,
    this.initialService,
    this.businessName,
    this.onReserveTap,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  bool isLoading = true;
  ServiceModel? service;
  String? resolvedBusinessName;
  String? errorMessage;

  final Color primaryColor = const Color(0xFFE2725B);
  final Color secondaryColor = const Color(0xFF2A9D8F);
  final Color backgroundColor = const Color(0xFFFAF6F1);
  final Color surfaceColor = const Color(0xFFFFFFFF);
  final Color textMainColor = const Color(0xFF2B2118);
  final Color textSecondaryColor = const Color(0xFF7A7267);

  @override
  void initState() {
    super.initState();
    if (widget.initialService != null) {
      service = widget.initialService!.copyWith(
        descripcion: ServiceDescriptionHelper.resolve(
          serviceId: widget.initialService!.idServicio,
          serviceName: widget.initialService!.nombre,
          currentDescription: widget.initialService!.descripcion,
        ),
      );
    }
    resolvedBusinessName =
        widget.businessName ?? widget.initialService?.nombreNegocio;
    _loadServiceDetail();
  }

  Future<Map<String, String>> _getHeaders() async {
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

  Future<void> _loadServiceDetail() async {
    setState(() {
      isLoading = service == null;
      errorMessage = null;
    });

    try {
      final headers = await _getHeaders();

      final candidateUrls = [
        "$baseUrl/services/${widget.serviceId}",
        "$baseUrl/servicios/${widget.serviceId}",
      ];

      ServiceModel? fetchedService;

      for (final url in candidateUrls) {
        final response = await http.get(Uri.parse(url), headers: headers);
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final Map<String, dynamic>? rawMap =
              (decoded is Map<String, dynamic> &&
                  decoded['data'] is Map<String, dynamic>)
              ? decoded['data'] as Map<String, dynamic>
              : (decoded is Map<String, dynamic> ? decoded : null);

          if (rawMap != null) {
            final parsed = ServiceModel.fromJson(rawMap);
            final resolvedDesc = ServiceDescriptionHelper.resolve(
              raw: rawMap,
              serviceId: parsed.idServicio > 0 ? parsed.idServicio : widget.serviceId,
              serviceName: parsed.nombre,
              currentDescription: service?.descripcion,
            );
            fetchedService = parsed.copyWith(descripcion: resolvedDesc);
            break;
          }
        }
      }

      if (fetchedService != null) {
        service = fetchedService;
        if (fetchedService.nombreNegocio != null &&
            fetchedService.nombreNegocio!.isNotEmpty) {
          resolvedBusinessName = fetchedService.nombreNegocio;
        }
      } else if (service != null) {
        service = service!.copyWith(
          descripcion: ServiceDescriptionHelper.resolve(
            serviceId: service!.idServicio > 0 ? service!.idServicio : widget.serviceId,
            serviceName: service!.nombre,
            currentDescription: service!.descripcion,
          ),
        );
      }

      if ((resolvedBusinessName == null || resolvedBusinessName!.isEmpty) &&
          service != null &&
          service!.negocioId > 0) {
        await _fetchBusinessName(service!.negocioId, headers);
      }

      if (!mounted) return;
      setState(() {
        isLoading = false;
        if (service == null) {
          errorMessage =
              "No se encontró información para el servicio #${widget.serviceId}.";
        }
      });
    } catch (e) {
      debugPrint("Error cargando detalle del servicio: $e");
      if (!mounted) return;
      setState(() {
        isLoading = false;
        if (service == null) {
          errorMessage = "Error de conexión al consultar el servicio.";
        }
      });
    }
  }

  Future<void> _fetchBusinessName(
    int negocioId,
    Map<String, String> headers,
  ) async {
    final businessUrls = [
      "$baseUrl/businesses/$negocioId",
      "$baseUrl/negocios/$negocioId",
    ];

    for (final url in businessUrls) {
      try {
        final res = await http.get(Uri.parse(url), headers: headers);
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          final data =
              (decoded is Map<String, dynamic> &&
                  decoded['data'] is Map<String, dynamic>)
              ? decoded['data'] as Map<String, dynamic>
              : (decoded is Map<String, dynamic> ? decoded : null);

          final name = (data?['nombre'] ?? data?['nombre_negocio'])
              ?.toString()
              .trim();
          if (name != null && name.isNotEmpty) {
            resolvedBusinessName = name;
            break;
          }
        }
      } catch (_) {}
    }
  }

  void _handleReserve() {
    if (service == null || !service!.estaDisponible) return;

    if (widget.onReserveTap != null) {
      widget.onReserveTap!();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Continuando a disponibilidad para '${service!.nombre}'...",
        ),
        backgroundColor: secondaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Detalle del Servicio",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : errorMessage != null && service == null
              ? _buildErrorState()
              : _buildDetailContent(),
      bottomNavigationBar: (!isLoading && service != null)
          ? _buildBottomReserveBar()
          : null,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: primaryColor),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? "Servicio no disponible",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: textMainColor),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: _loadServiceDetail,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                "Reintentar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailContent() {
    final item = service!;
    final businessLabel =
        (resolvedBusinessName != null && resolvedBusinessName!.isNotEmpty)
            ? resolvedBusinessName!
            : "Negocio #${item.negocioId}";

    final disponibilidadTexto = item.estaDisponible
        ? (item.horarioDisponibilidad != null &&
                item.horarioDisponibilidad!.isNotEmpty
            ? "Disponible (${item.horarioDisponibilidad})"
            : "Disponible (${item.cantidadServicio} ${item.cantidadServicio == 1 ? 'cupo' : 'cupos'} activos)")
        : "No disponible actualmente";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.categoriaServicio.toUpperCase(),
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: item.estaDisponible
                            ? secondaryColor.withOpacity(0.15)
                            : Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.estaDisponible
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 16,
                            color: item.estaDisponible
                                ? secondaryColor
                                : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.estaDisponible ? "Disponible" : "Inactivo",
                            style: TextStyle(
                              color: item.estaDisponible
                                  ? secondaryColor
                                  : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  item.nombre,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textMainColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.storefront, size: 18, color: secondaryColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        businessLabel,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: secondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.attach_money,
                        label: "Precio",
                        value: "\$${item.precio.toStringAsFixed(2)} MXN",
                        accentColor: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.schedule,
                        label: "Duración",
                        value: item.duracionFormateada,
                        accentColor: secondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Descripción",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textMainColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.descripcion,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Disponibilidad",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textMainColor,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.event_available,
                  title: "Estado del servicio",
                  subtitle: disponibilidadTexto,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.business,
                  title: "Negocio",
                  subtitle: businessLabel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accentColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: textSecondaryColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textMainColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: secondaryColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textMainColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 14, color: textSecondaryColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomReserveBar() {
    final item = service!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  item.estaDisponible ? primaryColor : Colors.grey.shade400,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: item.estaDisponible ? _handleReserve : null,
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            label: Text(
              item.estaDisponible
                  ? "Continuar para Reservar"
                  : "Servicio No Disponible",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}