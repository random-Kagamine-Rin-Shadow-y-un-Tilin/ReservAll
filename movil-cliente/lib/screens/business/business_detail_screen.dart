import 'package:flutter/material.dart';
import '/models/shop.dart';
import '/services/api_service.dart';

class BusinessDetailScreen extends StatefulWidget {
  const BusinessDetailScreen({super.key});

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  bool isLoading = true;
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
      setState(() {
        detail = result;
        shop = result.general;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = "No se pudo cargar la información completa del negocio.";
      });
    }
  }

  String _getImageUrl(dynamic rawImage) {
    if (rawImage == null) return '';
    String img = rawImage.toString().trim();
    if (img.isEmpty || img == 'null') return '';
    if (img.startsWith("http://") || img.startsWith("https://")) {
      return img;
    }
    if (img.startsWith("/")) {
      return "http://10.0.0.6:8000$img";
    }
    return "http://10.0.0.6:8000/static/$img";
  }

  String _dayLabel(String? value) {
    const labels = {
      "lunes": "Lunes",
      "martes": "Martes",
      "miercoles": "Miércoles",
      "jueves": "Jueves",
      "viernes": "Viernes",
      "sabado": "Sábado",
      "domingo": "Domingo",
    };
    final key = (value ?? '').toLowerCase().trim();
    return labels[key] ?? (value ?? '');
  }

  String _timeLabel(dynamic value) {
    if (value == null) return '';
    final parts = value.toString().split(':');
    if (parts.length >= 2) {
      return "${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}";
    }
    return value.toString();
  }

  String _addressLabel() {
    final address = detail?.direccion;
    if (address == null) {
      return shop?.direccion ?? "Ubicación no registrada";
    }

    final street =
        [
              address['direccion_calle'],
              address['numero_local'],
              address['numero_interior'],
            ]
            .where(
              (value) => value != null && value.toString().trim().isNotEmpty,
            )
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

    return parts.isEmpty ? "Ubicación no registrada" : parts.join(', ');
  }

  String _priceLabel(dynamic raw) {
    if (raw == null) return 'Precio no disponible';
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
              errorMessage ?? "Negocio no disponible.",
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondaryColor),
            ),
          ),
        ),
      );
    }

    final imageUrl = _getImageUrl(currentShop.imagenNegocio);

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
              _buildHeroImage(imageUrl),
              const SizedBox(height: 20),
              _buildTitleRow(currentShop),
              const SizedBox(height: 20),
              if (errorMessage != null) ...[
                _buildInlineWarning(errorMessage!),
                const SizedBox(height: 16),
              ],
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
                currentShop.descripcion.isNotEmpty
                    ? currentShop.descripcion
                    : "Sin descripción disponible.",
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondaryColor,
                  height: 1.4,
                ),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 20),
              _buildInfoCard(currentShop),
              const SizedBox(height: 20),
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
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Icon(Icons.store, size: 64, color: primaryColor),
                ),
              )
            : Center(child: Icon(Icons.store, size: 64, color: primaryColor)),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.shade400, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(
                currentShop.valoracion == null ? Icons.star_border : Icons.star,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                currentShop.valoracion == null
                    ? "Sin valorar"
                    : currentShop.valoracion!.toStringAsFixed(1),
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

  Widget _buildInfoCard(Shop currentShop) {
    return Card(
      color: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _addressLabel(),
                    style: TextStyle(
                      color: textMainColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Icon(Icons.payments_outlined, color: secondaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    currentShop.precioMinimo == null
                        ? "Precio no disponible"
                        : "Desde \$${currentShop.precioMinimo!.toStringAsFixed(0)}",
                    style: TextStyle(
                      color: textMainColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
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
                    "${_timeLabel(horario['hora_apertura'])} - "
                    "${_timeLabel(horario['hora_cierre'])}",
                    style: TextStyle(color: textMainColor),
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
            children: servicios.map((servicio) {
              final duracion = servicio['duracion_minutos'];
              return ListTile(
                leading: Icon(
                  Icons.check_circle_outline,
                  color: secondaryColor,
                ),
                title: Text(
                  servicio['nombre']?.toString() ?? 'Servicio',
                  style: TextStyle(
                    color: textMainColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  duracion == null ? "" : "$duracion min",
                  style: TextStyle(color: textSecondaryColor),
                ),
                trailing: Text(
                  _priceLabel(servicio['precio']),
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
