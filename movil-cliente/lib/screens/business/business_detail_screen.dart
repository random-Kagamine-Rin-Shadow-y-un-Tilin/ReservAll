import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/models/shop.dart';
import '/services/api_service.dart';
import '/services/service_description_helper.dart';
import '/models/service_model.dart';
import '/services/service_detail_screen.dart';
import '/screens/business/business_map_screen.dart';
import '/screens/business/business_route_map_screen.dart';

class BusinessDetailScreen extends StatefulWidget {
  const BusinessDetailScreen({super.key});

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  bool isLoading = true;
  bool isFavorite = false;
  String? errorMessage;
  Shop? shop;
  ShopDetail? detail;

  final Color primaryColor = const Color(0xFFE2725B);
  final Color secondaryColor = const Color(0xFF2A9D8F);
  final Color backgroundColor = const Color(0xFFFAF6F1);
  final Color surfaceColor = const Color(0xFFFFFFFF);
  final Color textMainColor = const Color(0xFF2B2118);
  final Color textSecondaryColor = const Color(0xFF7A7267);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (shop == null && isLoading) {
      _loadFromArguments();
    }
  }

  Future<void> _loadFromArguments() async {
    final args = ModalRoute.of(context)?.settings.arguments;

    Shop? initialShop;
    if (args is Shop) {
      initialShop = args;
    } else if (args is Map) {
      initialShop = Shop.fromJson(Map<String, dynamic>.from(args));
    }

    if (initialShop == null) {
      setState(() {
        isLoading = false;
        errorMessage = "No se recibió el negocio a consultar.";
      });
      return;
    }

    setState(() {
      shop = initialShop;
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await fetchShopDetail(initialShop.id);
      if (!mounted) return;

      final resolvedShop = result.resolvedShop.copyWith(
        distanciaKm: result.resolvedShop.distanciaKm ?? initialShop.distanciaKm,
      );

      setState(() {
        detail = result;
        shop = resolvedShop;
        isLoading = false;
      });
      await _checkIfFavorite(initialShop.id);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = "No se pudo cargar la información desde el servidor.";
      });
    }
  }

  Future<void> _checkIfFavorite(dynamic shopId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/client/favorites"),
        headers: {"accept": "application/json", "x-api-key": apiKey},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List favs = [];
        if (data is List) {
          favs = data;
        } else if (data is Map) {
          favs = data['favorites'] ?? data['data'] ?? [];
        }

        final exists = favs.any((item) {
          final id = item['id'] ?? item['id_negocio'] ?? item['business_id'];
          return id.toString() == shopId.toString();
        });

        if (mounted) {
          setState(() {
            isFavorite = exists;
          });
        }
      }
    } catch (e) {
      debugPrint("Error al verificar favorito desde Supabase: $e");
    }
  }

  Future<void> _toggleFavorite() async {
    if (shop == null) return;
    final shopId = shop!.id;

    try {
      final endpoint = isFavorite
          ? "/client/remove-favorite/$shopId"
          : "/client/add-favorite/$shopId";

      final response = await http.post(
        Uri.parse("$baseUrl$endpoint"),
        headers: {"accept": "application/json", "x-api-key": apiKey},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          isFavorite = !isFavorite;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isFavorite ? "Añadido a favoritos" : "Eliminado de favoritos",
              ),
              backgroundColor: primaryColor,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        debugPrint(
          "Error del servidor al modificar favorito: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      debugPrint("Error de conexión al modificar favorito: $e");
    }
  }

  void _openBusinessMap(Shop currentShop, String? addressText) {
    if (!currentShop.hasCoordinates) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BusinessMapScreen(
          shop: currentShop,
          formattedAddress: addressText,
        ),
      ),
    );
  }

  String _getImageUrl(dynamic rawImage) {
    if (rawImage == null) return '';
    String img = rawImage.toString().trim();
    if (img.isEmpty || img == 'null') return '';
    if (img.startsWith("http://") || img.startsWith("https://")) {
      return img;
    }
    if (img.startsWith("/")) {
      return "$baseUrl$img";
    }
    return "$baseUrl/static/$img";
  }

  String _dayLabel(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    return value.trim();
  }

  String _timeLabel(dynamic value) {
    if (value == null) return '';
    final parts = value.toString().split(':');
    if (parts.length >= 2) {
      return "${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}";
    }
    return value.toString();
  }

  String? _addressLabel() {
    final address = detail?.direccion;
    if (address == null) {
      final raw = shop?.direccion?.trim() ?? '';
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

    return parts.isEmpty ? null : parts.join(', ');
  }

  String _priceLabel(dynamic raw) {
    if (raw == null) return '';
    final value = double.tryParse(raw.toString());
    if (value == null) return '\$$raw';
    return '\$${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final currentShop = shop;

    if (isLoading && currentShop == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(backgroundColor: primaryColor),
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    if (currentShop == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text("Negocio"),
          backgroundColor: primaryColor,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              errorMessage ?? "",
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondaryColor),
            ),
          ),
        ),
      );
    }

    final imageUrl = _getImageUrl(currentShop.imagenNegocio);
    final addressText = _addressLabel();
    final hasDescription = currentShop.descripcion.trim().isNotEmpty;
    final hasInfoCard =
        addressText != null ||
        currentShop.precioMinimo != null ||
        currentShop.hasCoordinates;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          currentShop.nombre,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.redAccent : Colors.white,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: _loadFromArguments,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl.isNotEmpty) ...[
                _buildHeroImage(imageUrl),
                const SizedBox(height: 20),
              ],
              _buildTitleRow(currentShop),
              const SizedBox(height: 20),
              if (errorMessage != null) ...[
                _buildInlineWarning(errorMessage!),
                const SizedBox(height: 16),
              ],
              if (hasDescription) ...[
                Text(
                  "Acerca del negocio",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textMainColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentShop.descripcion,
                  style: TextStyle(
                    fontSize: 15,
                    color: textSecondaryColor,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 20),
              ],
              if (hasInfoCard) ...[
                _buildInfoCard(currentShop, addressText),
                const SizedBox(height: 20),
              ],
              if (detail != null && detail!.horarios.isNotEmpty) ...[
                _buildScheduleSection(),
                const SizedBox(height: 20),
              ],
              if (detail != null && detail!.servicios.isNotEmpty) ...[
                _buildServicesSection(),
                const SizedBox(height: 20),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/bookingCreate',
                      arguments: currentShop,
                    );
                  },
                  icon: const Icon(Icons.calendar_today, color: Colors.white),
                  label: const Text(
                    "Reservar cita",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage(String imageUrl) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade200,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              Center(child: Icon(Icons.store, size: 64, color: primaryColor)),
        ),
      ),
    );
  }

  Widget _buildTitleRow(Shop currentShop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentShop.nombre,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textMainColor,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (currentShop.categoriaNegocio.trim().isNotEmpty)
                    Chip(
                      label: Text(currentShop.categoriaNegocio),
                      backgroundColor: secondaryColor.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: secondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  if (currentShop.distanciaKm != null)
                    Chip(
                      avatar: Icon(
                        Icons.near_me,
                        size: 16,
                        color: textSecondaryColor,
                      ),
                      label: Text(
                        "${currentShop.distanciaKm!.toStringAsFixed(1)} km",
                      ),
                      backgroundColor: surfaceColor,
                      labelStyle: TextStyle(color: textSecondaryColor),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
            ],
          ),
        ),
        if (currentShop.valoracion != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade400, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  currentShop.valoracion!.toStringAsFixed(1),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textMainColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInfoCard(Shop currentShop, String? addressText) {
    return Card(
      color: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (addressText != null)
              Row(
                children: [
                  Icon(Icons.location_on, color: primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      addressText,
                      style: TextStyle(
                        color: textMainColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            if (addressText != null && currentShop.precioMinimo != null)
              const Divider(height: 20),
            if (currentShop.precioMinimo != null)
              Row(
                children: [
                  Icon(Icons.payments_outlined, color: secondaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Desde \$${currentShop.precioMinimo!.toStringAsFixed(0)}",
                      style: TextStyle(
                        color: textMainColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            if (currentShop.hasCoordinates) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _openBusinessMap(currentShop, addressText),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text("Ver en mapa"),
                ),
              ),
              if (currentShop.latitud != null &&
                  currentShop.longitud != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BusinessRouteMapScreen(
                            businessName: currentShop.nombre,
                            businessLat: currentShop.latitud!,
                            businessLng: currentShop.longitud!,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text("Cómo llegar"),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection() {
    final horarios = detail!.horarios;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Horarios de atención",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textMainColor,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          color: surfaceColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: horarios.map((horario) {
                final descanso = horario['hora_descanso'];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.access_time,
                    color: secondaryColor,
                    size: 20,
                  ),
                  title: Text(
                    _dayLabel(horario['dia']?.toString()),
                    style: TextStyle(
                      color: textMainColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: descanso == null
                      ? null
                      : Text(
                          "Descanso: ${_timeLabel(descanso)}",
                          style: TextStyle(color: textSecondaryColor),
                        ),
                  trailing: Text(
                    "${_timeLabel(horario['hora_apertura'])} - ${_timeLabel(horario['hora_cierre'])}",
                    style: TextStyle(
                      color: textMainColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection() {
    final servicios = detail!.servicios;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Servicios disponibles",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textMainColor,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          color: surfaceColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: servicios.map((rawServicio) {
              final servicioMap = Map<String, dynamic>.from(rawServicio as Map);
              final int sId = int.tryParse(
                    (servicioMap['id_servicio'] ?? servicioMap['id'] ?? 0)
                        .toString(),
                  ) ??
                  0;
              final String sName = servicioMap['nombre']?.toString() ?? '';
              final duracion = servicioMap['duracion_minutos'];
              final precioTexto = _priceLabel(servicioMap['precio']);
              final descripcionTexto = ServiceDescriptionHelper.resolve(
                raw: servicioMap,
                serviceId: sId > 0 ? sId : null,
                serviceName: sName,
              );

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Icon(
                  Icons.check_circle_outline,
                  color: secondaryColor,
                ),
                title: Text(
                  sName,
                  style: TextStyle(
                    color: textMainColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (duracion != null)
                      Text(
                        "$duracion min",
                        style: TextStyle(
                          color: textSecondaryColor,
                          fontSize: 13,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      descripcionTexto,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textSecondaryColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (precioTexto.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          precioTexto,
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: textSecondaryColor,
                    ),
                  ],
                ),
                onTap: () {
                  final enrichedMap = {
                    ...servicioMap,
                    'descripcion': descripcionTexto,
                    'estado_servicio': servicioMap['estado_servicio'] ?? true,
                    'cantidad_servicio': servicioMap['cantidad_servicio'] ?? 1,
                    'negocio_id': int.tryParse(shop!.id.toString()) ?? 0,
                    'nombre_negocio': shop!.nombre,
                  };
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ServiceDetailScreen(
                        serviceId: sId,
                        initialService: ServiceModel.fromJson(enrichedMap),
                        businessName: shop!.nombre,
                        onReserveTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            '/bookingCreate',
                            arguments: shop,
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineWarning(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: textSecondaryColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}