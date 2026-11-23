import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '/models/shop.dart';
import '/screens/business/business_map_screen.dart';
import '/services/api_service.dart';
import '/services/location_service.dart';
import '/services/service_description_helper.dart';

class BusinessListScreen extends StatefulWidget {
  final String? category;
  const BusinessListScreen({super.key, this.category});

  @override
  State<BusinessListScreen> createState() => _BusinessListScreenState();
}

class _BusinessListScreenState extends State<BusinessListScreen> {
  static const List<double> _radiusOptionsKm = [1, 3, 5, 10, 25];
  static const List<double> _priceMinOptions = [50, 100, 200];
  static const List<double> _priceMaxOptions = [200, 500, 1000];
  static const List<int> _durationMaxOptions = [15, 30, 60, 90, 120];

  List<Shop> shops = [];
  List<Map<String, dynamic>> matchedServices = [];
  List<ShopCategory> categories = [];
  bool isLoading = false;
  String? errorMessage;

  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;
  bool _initialized = false;
  int _requestId = 0;

  String selectedCategory = "Todos";
  int? selectedCategoryId;
  String query = "";
  String ciudad = "";
  String orden = "relevancia";
  DateTime? disponibleFecha;
  TimeOfDay? disponibleHora;
  double? minPrecio;
  double? maxPrecio;
  int? maxDuracionMin;
  double? latitud;
  double? longitud;
  double radioKm = 5;
  bool locating = false;

  final Color primaryColor = const Color(0xFFE2725B);
  final Color secondaryColor = const Color(0xFF2A9D8F);
  final Color backgroundColor = const Color(0xFFFAF6F1);
  final Color surfaceColor = const Color(0xFFFFFFFF);
  final Color textMainColor = const Color(0xFF2B2118);
  final Color textSecondaryColor = const Color(0xFF7A7267);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    selectedCategory =
        widget.category ?? (routeArgs is String ? routeArgs : null) ?? "Todos";
    _initialLoad();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _initialLoad() async {
    await _loadCategories();
    if (mounted) {
      await _loadShops();
    }
  }

  Future<void> _loadCategories() async {
    try {
      final result = await fetchCategories();
      if (!mounted) return;
      setState(() {
        categories = result;
        if (selectedCategory != "Todos") {
          final matches = result.where(
            (category) =>
                category.nombre.toLowerCase().trim() ==
                selectedCategory.toLowerCase().trim(),
          );
          if (matches.isNotEmpty) {
            selectedCategoryId = matches.first.id;
            selectedCategory = matches.first.nombre;
          }
        }
      });
    } catch (_) {}
  }

  bool _isServiceActive(Map<String, dynamic> servicioMap) {
    final rawActive = servicioMap['estado_servicio'] ??
        servicioMap['activo'] ??
        servicioMap['is_active'] ??
        servicioMap['disponible'];

    if (rawActive == null) {
      final estadoStr =
          (servicioMap['estado'] ?? '').toString().trim().toLowerCase();
      if (estadoStr == 'inactivo' ||
          estadoStr == 'inactive' ||
          estadoStr == 'desactivado') {
        return false;
      }
      return true;
    }

    if (rawActive is bool) return rawActive;
    if (rawActive is num) return rawActive != 0;

    final normalized = rawActive.toString().trim().toLowerCase();
    return normalized != 'false' &&
        normalized != '0' &&
        normalized != 'inactivo' &&
        normalized != 'inactive' &&
        normalized != 'no';
  }

  String? _buildAddressFromDetail(ShopDetail shopDetail, Shop fallbackShop) {
    final address = shopDetail.direccion;
    if (address == null) {
      final raw = fallbackShop.direccion?.trim() ?? '';
      return raw.isEmpty ? null : raw;
    }

    final street = [
      address['direccion_calle'],
      address['numero_local'],
      address['numero_interior'],
    ]
        .where((v) => v != null && v.toString().trim().isNotEmpty)
        .join(' ');
    final city = address['ciudad']?.toString().trim();
    final state = address['estado']?.toString().trim();

    final parts = <String>[];
    if (street.isNotEmpty) parts.add(street);
    if (city != null && city.isNotEmpty) parts.add(city);
    if (state != null && state.isNotEmpty) parts.add(state);

    if (parts.isNotEmpty) return parts.join(', ');
    final raw = fallbackShop.direccion?.trim() ?? '';
    return raw.isEmpty ? null : raw;
  }

  double? _parsePrice(Map<String, dynamic> svcMap, Shop fallbackShop) {
    final raw = svcMap['precio'] ??
        svcMap['precio_servicio'] ??
        svcMap['tarifa'] ??
        svcMap['costo'] ??
        fallbackShop.precioMinimo;
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    final cleaned = raw.toString().replaceAll(RegExp(r'[^0-9.,-]'), '').replaceAll(',', '').trim();
    return double.tryParse(cleaned);
  }

  int? _parseDuration(Map<String, dynamic> svcMap) {
    final raw = svcMap['duracion_minutos'] ??
        svcMap['duracion'] ??
        svcMap['tiempo_minutos'] ??
        svcMap['duracionMinutos'];
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    final cleaned = raw.toString().replaceAll(RegExp(r'[^0-9]'), '').trim();
    return int.tryParse(cleaned);
  }

  String _resolveServiceCategory(Map<String, dynamic> svcMap, Shop resolvedShop) {
    final rawCat = svcMap['categoria'] ??
        svcMap['categoria_servicio'] ??
        svcMap['categoria_nombre'] ??
        svcMap['category'];
    if (rawCat != null && rawCat.toString().trim().isNotEmpty) {
      return rawCat.toString().trim();
    }
    return resolvedShop.categoriaNegocio;
  }

  bool _matchesHu21ServiceFilters({
    required String serviceName,
    required String serviceDescription,
    required String serviceCategory,
    required double? price,
    required int? durationMin,
    required String searchTerm,
  }) {
    if (searchTerm.isNotEmpty) {
      final matchesText = serviceName.toLowerCase().contains(searchTerm) ||
          serviceDescription.toLowerCase().contains(searchTerm) ||
          serviceCategory.toLowerCase().contains(searchTerm);
      if (!matchesText) return false;
    }

    if (selectedCategory != "Todos") {
      final targetCat = selectedCategory.trim().toLowerCase();
      final svcCat = serviceCategory.trim().toLowerCase();
      if (svcCat.isNotEmpty && svcCat != targetCat) {
        return false;
      }
    }

    if (minPrecio != null) {
      if (price == null || price < minPrecio!) return false;
    }

    if (maxPrecio != null) {
      if (price == null || price > maxPrecio!) return false;
    }

    if (maxDuracionMin != null) {
      if (durationMin == null || durationMin > maxDuracionMin!) return false;
    }

    return true;
  }

  Future<List<Map<String, dynamic>>> _searchMatchingActiveServices(
    List<Shop> candidateShops,
    String searchTerm,
    int requestId,
  ) async {
    final term = searchTerm.trim().toLowerCase();
    if (candidateShops.isEmpty) return const [];

    final targets = candidateShops.take(20).toList();
    final results = <Map<String, dynamic>>[];
    await Future.wait(
      targets.map((shop) async {
        try {
          final shopDetail = await fetchShopDetail(shop.id);
          if (!mounted || requestId != _requestId) return;

          final resolvedShop = shopDetail.resolvedShop.copyWith(
            distanciaKm:
                shopDetail.resolvedShop.distanciaKm ?? shop.distanciaKm,
          );
          final formattedAddress =
              _buildAddressFromDetail(shopDetail, resolvedShop);

          for (final rawSvc in shopDetail.servicios) {
            if (rawSvc is! Map) continue;
            final svcMap = Map<String, dynamic>.from(rawSvc);
            if (!_isServiceActive(svcMap)) continue;

            final int sId = int.tryParse(
                  (svcMap['id_servicio'] ?? svcMap['id'] ?? 0).toString(),
                ) ??
                0;
            final String sName = (svcMap['nombre'] ??
                    svcMap['name'] ??
                    svcMap['titulo'] ??
                    'Servicio')
                .toString();
            final String sDesc = ServiceDescriptionHelper.resolve(
              raw: svcMap,
              serviceId: sId > 0 ? sId : null,
              serviceName: sName,
            );
            final String sCat = _resolveServiceCategory(svcMap, resolvedShop);
            final double? parsedPrice = _parsePrice(svcMap, resolvedShop);
            final int? parsedDuration = _parseDuration(svcMap);

            final passes = _matchesHu21ServiceFilters(
              serviceName: sName,
              serviceDescription: sDesc,
              serviceCategory: sCat,
              price: parsedPrice,
              durationMin: parsedDuration,
              searchTerm: term,
            );

            if (passes) {
              results.add({
                'shop': resolvedShop,
                'formattedAddress': formattedAddress,
                'serviceId': sId,
                'serviceName': sName,
                'serviceDescription': sDesc,
                'serviceCategory': sCat,
                'duration': parsedDuration,
                'price': parsedPrice,
                'image': _getImageUrl(
                  svcMap['imagen'] ??
                      svcMap['imagen_url'] ??
                      svcMap['imagenServicio'] ??
                      svcMap['foto'] ??
                      resolvedShop.imagenNegocio,
                ),
              });
            }
          }
        } catch (_) {}
      }),
    );

    return results;
  }

  bool get _hasServiceSearchActive =>
      query.trim().isNotEmpty ||
      minPrecio != null ||
      maxPrecio != null ||
      maxDuracionMin != null;

  Future<void> _loadShops() async {
    if (!mounted) return;
    final requestId = ++_requestId;
    final currentQuery = query.trim();

    setState(() {
      isLoading = true;
      errorMessage = null;
      if (!_hasServiceSearchActive) {
        matchedServices = [];
      }
    });

    try {
      var result = await searchCatalog(
        q: currentQuery,
        categoriaId: selectedCategoryId,
        categoria: selectedCategoryId == null && selectedCategory != "Todos"
            ? selectedCategory
            : null,
        ciudad: ciudad.isEmpty ? null : ciudad,
        lat: latitud,
        lng: longitud,
        radioKm: _hasLocation ? radioKm : null,
        fecha: disponibleFecha == null ? null : _formatDate(disponibleFecha!),
        hora: disponibleHora == null ? null : _formatTime(disponibleHora!),
        orden: orden,
      );

      if (_hasLocation) {
        result = LocationService.attachDistancesAndSort(
          result,
          userLat: latitud!,
          userLng: longitud!,
          maxRadiusKm: radioKm,
        );
        if (orden != "distancia") {
          _sortShops(result, orden);
        }
      }

      List<Map<String, dynamic>> foundServices = const [];
      if (_hasServiceSearchActive) {
        var pool = result;
        if (pool.isEmpty) {
          pool = await searchCatalog(
            q: "",
            categoriaId: selectedCategoryId,
            categoria: selectedCategoryId == null && selectedCategory != "Todos"
                ? selectedCategory
                : null,
            ciudad: ciudad.isEmpty ? null : ciudad,
            lat: latitud,
            lng: longitud,
            radioKm: _hasLocation ? radioKm : null,
            fecha: disponibleFecha == null
                ? null
                : _formatDate(disponibleFecha!),
            hora: disponibleHora == null ? null : _formatTime(disponibleHora!),
            orden: orden,
          );
        }
        foundServices = await _searchMatchingActiveServices(
          pool,
          currentQuery.toLowerCase(),
          requestId,
        );
      }

      if (!mounted || requestId != _requestId) return;
      setState(() {
        shops = result;
        matchedServices = foundServices;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        shops = [];
        matchedServices = [];
        isLoading = false;
        errorMessage = "No se pudieron cargar los negocios. Intenta de nuevo.";
      });
    }
  }

  void _sortShops(List<Shop> list, String sortKey) {
    switch (sortKey) {
      case "nombre":
        list.sort(
          (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
        );
        break;
      case "precio_asc":
        list.sort(
          (a, b) => (a.precioMinimo ?? double.infinity)
              .compareTo(b.precioMinimo ?? double.infinity),
        );
        break;
      case "precio_desc":
        list.sort(
          (a, b) => (b.precioMaximo ?? b.precioMinimo ?? -1)
              .compareTo(a.precioMaximo ?? a.precioMinimo ?? -1),
        );
        break;
      case "populares":
        list.sort(
          (a, b) => (b.valoracion ?? -1).compareTo(a.valoracion ?? -1),
        );
        break;
      case "distancia":
      default:
        list.sort(
          (a, b) => (a.distanciaKm ?? double.infinity)
              .compareTo(b.distanciaKm ?? double.infinity),
        );
        break;
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return "${date.year}-$month-$day";
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  void _onSearchChanged(String value) {
    setState(() => query = value.trim());
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _loadShops();
    });
  }

  void _selectCategory(String name, int? id) {
    setState(() {
      selectedCategory = name;
      selectedCategoryId = id;
    });
    _loadShops();
  }

  void _selectRadius(double radius) {
    if (radioKm == radius) return;
    setState(() => radioKm = radius);
    _loadShops();
  }

  Future<void> _openPriceRangeFilter() async {
    double? tempMin = minPrecio;
    double? tempMax = maxPrecio;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Filtrar servicios por precio",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textMainColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Precio mínimo",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text("Sin mín."),
                          selected: tempMin == null,
                          selectedColor: secondaryColor,
                          onSelected: (_) =>
                              setModalState(() => tempMin = null),
                        ),
                        ..._priceMinOptions.map(
                          (val) => ChoiceChip(
                            label: Text("\$${val.toStringAsFixed(0)}"),
                            selected: tempMin == val,
                            selectedColor: secondaryColor,
                            onSelected: (_) =>
                                setModalState(() => tempMin = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Precio máximo",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text("Sin máx."),
                          selected: tempMax == null,
                          selectedColor: secondaryColor,
                          onSelected: (_) =>
                              setModalState(() => tempMax = null),
                        ),
                        ..._priceMaxOptions.map(
                          (val) => ChoiceChip(
                            label: Text("\$${val.toStringAsFixed(0)}"),
                            selected: tempMax == val,
                            selectedColor: secondaryColor,
                            onSelected: (_) =>
                                setModalState(() => tempMax = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text("Aplicar"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;
    setState(() {
      minPrecio = tempMin;
      maxPrecio = tempMax;
    });
    _loadShops();
  }

  Future<void> _openDurationFilter() async {
    final selected = await showModalBottomSheet<int?>(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                "Duración máxima del servicio",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              title: const Text("Cualquier duración"),
              trailing:
                  maxDuracionMin == null ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, null),
            ),
            ..._durationMaxOptions.map(
              (mins) => ListTile(
                title: Text("Hasta $mins min"),
                trailing:
                    maxDuracionMin == mins ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, mins),
              ),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    setState(() => maxDuracionMin = selected);
    _loadShops();
  }

  Future<void> _openAvailabilityFilter() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: disponibleFecha ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: "Fecha disponible",
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: disponibleHora ?? TimeOfDay.now(),
      helpText: "Hora (opcional)",
    );
    if (!mounted) return;

    setState(() {
      disponibleFecha = date;
      disponibleHora = time;
    });
    _loadShops();
  }

  void _showMessage(String message, {bool openSettings = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: openSettings
            ? SnackBarAction(
                label: "Ajustes",
                onPressed: () async {
                  await Geolocator.openAppSettings();
                },
              )
            : null,
      ),
    );
  }

  Future<void> _useMyLocation() async {
    if (_hasLocation) {
      setState(() {
        latitud = null;
        longitud = null;
        if (orden == "distancia") orden = "relevancia";
      });
      _loadShops();
      return;
    }

    setState(() => locating = true);
    try {
      final locationResult = await LocationService.getCurrentLocation();
      if (!mounted) return;

      if (!locationResult.isSuccess || locationResult.position == null) {
        _showMessage(
          locationResult.errorMessage ??
              "No se pudo obtener tu ubicación. Intenta de nuevo.",
          openSettings: locationResult.openSettingsSuggested,
        );
        return;
      }

      setState(() {
        latitud = locationResult.position!.latitude;
        longitud = locationResult.position!.longitude;
        orden = "distancia";
      });
      _loadShops();
    } catch (_) {
      _showMessage("No se pudo obtener tu ubicación. Intenta de nuevo.");
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  void _clearFilters() {
    _debounce?.cancel();
    searchController.clear();
    setState(() {
      query = "";
      ciudad = "";
      selectedCategory = "Todos";
      selectedCategoryId = null;
      orden = "relevancia";
      disponibleFecha = null;
      disponibleHora = null;
      minPrecio = null;
      maxPrecio = null;
      maxDuracionMin = null;
      latitud = null;
      longitud = null;
      radioKm = 5;
      matchedServices = [];
    });
    _loadShops();
  }

  bool get _hasActiveFilters =>
      query.isNotEmpty ||
      ciudad.isNotEmpty ||
      selectedCategory != "Todos" ||
      disponibleFecha != null ||
      minPrecio != null ||
      maxPrecio != null ||
      maxDuracionMin != null ||
      latitud != null ||
      orden != "relevancia";

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

  String _priceLabel(Shop shop) {
    if (shop.precioMinimo == null && shop.precioMaximo == null) {
      return "Precio no disponible";
    }
    if (shop.precioMinimo != null &&
        shop.precioMaximo != null &&
        shop.precioMinimo != shop.precioMaximo) {
      return "\$${shop.precioMinimo!.toStringAsFixed(0)} - "
          "\$${shop.precioMaximo!.toStringAsFixed(0)}";
    }
    final value = shop.precioMinimo ?? shop.precioMaximo!;
    return "Desde \$${value.toStringAsFixed(0)}";
  }

  String _singlePriceLabel(dynamic rawPrice) {
    if (rawPrice == null) return "Precio no disponible";
    final value = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice.toString());
    if (value == null) return "\$$rawPrice";
    return "\$${value.toStringAsFixed(2)}";
  }

  String _distanceLabel(Shop shop) {
    final dist = shop.distanciaKm;
    if (dist == null) return "";
    if (dist < 1.0) {
      return "${(dist * 1000).round()} m";
    }
    return "${dist.toStringAsFixed(1)} km";
  }

  void _openServiceDetailsModal(Map<String, dynamic> item) {
    final Shop shop = item['shop'] as Shop;
    final String? formattedAddress = item['formattedAddress'] as String?;
    final String sName = item['serviceName'] as String;
    final String sDesc = item['serviceDescription'] as String;
    final dynamic duration = item['duration'];
    final String priceText = _singlePriceLabel(item['price']);
    final String imgUrl = (item['image'] as String?) ?? '';
    final String addressDisplay = formattedAddress ??
        shop.direccion ??
        shop.ciudad ??
        "Ubicación no registrada";
    final bool canShowRoute = shop.hasCoordinates;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              18,
              20,
              20 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: imgUrl.isNotEmpty
                          ? Image.network(
                              imgUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _serviceImagePlaceholder(),
                            )
                          : _serviceImagePlaceholder(),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textMainColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            priceText,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "Descripción",
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: textMainColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sDesc,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 18,
                      color: secondaryColor,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Negocio: ",
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: textMainColor,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        shop.nombre,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (duration != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 18, color: secondaryColor),
                      const SizedBox(width: 10),
                      Text(
                        "Duración: ",
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: textMainColor,
                        ),
                      ),
                      Text(
                        "$duration min",
                        style: TextStyle(
                          fontSize: 13.5,
                          color: textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: secondaryColor,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Dirección: ",
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: textMainColor,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        addressDisplay,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.storefront_outlined, size: 18),
                    label: const Text(
                      "Ver negocio",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.pushNamed(
                        context,
                        '/businessDetail',
                        arguments: shop,
                      );
                    },
                  ),
                ),
                if (canShowRoute) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: secondaryColor,
                        side: BorderSide(color: secondaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.route, size: 18),
                      label: const Text(
                        "Ver ruta",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BusinessMapScreen(
                              shop: shop,
                              formattedAddress: formattedAddress,
                            ),
                          ),
                        );
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          selectedCategory == "Todos" ? "Negocios" : selectedCategory,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Actualizar",
            icon: const Icon(Icons.refresh),
            onPressed: _loadShops,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              controller: searchController,
              style: TextStyle(color: textMainColor),
              onChanged: _onSearchChanged,
              onSubmitted: (_) => _loadShops(),
              decoration: InputDecoration(
                hintText: "Buscar por nombre, servicio o categoría...",
                hintStyle: TextStyle(color: textSecondaryColor),
                prefixIcon: Icon(Icons.search, color: primaryColor),
                filled: true,
                fillColor: surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (searchController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.clear, color: textSecondaryColor),
                        onPressed: () {
                          searchController.clear();
                          _onSearchChanged("");
                        },
                      ),
                    IconButton(
                      tooltip: "Buscar",
                      icon: Icon(Icons.arrow_forward, color: secondaryColor),
                      onPressed: _loadShops,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildCategoryChips(),
          _buildFilterBar(),
          if (_hasLocation) _buildRadiusChips(),
          const SizedBox(height: 4),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final regularCategories = categories
        .where((c) => c.nombre.trim().toLowerCase() != "otro")
        .toList();
    final otherCategories = categories
        .where((c) => c.nombre.trim().toLowerCase() == "otro")
        .toList();

    final items = <Widget>[
      _categoryChip("Todos", null),
      ...regularCategories.map(
        (category) => _categoryChip(category.nombre, category.id),
      ),
      ...otherCategories.map(
        (category) => _categoryChip(category.nombre, category.id),
      ),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => items[index],
      ),
    );
  }

  Widget _categoryChip(String name, int? id) {
    final isSelected = selectedCategory == name;
    return ChoiceChip(
      label: Text(name),
      selected: isSelected,
      backgroundColor: surfaceColor,
      selectedColor: secondaryColor,
      onSelected: (_) => _selectCategory(name, id),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : textMainColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildRadiusChips() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        itemCount: _radiusOptionsKm.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Center(
              child: Text(
                "Radio:",
                style: TextStyle(
                  color: textSecondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final radius = _radiusOptionsKm[index - 1];
          final isSelected = radioKm == radius;
          return ChoiceChip(
            visualDensity: VisualDensity.compact,
            label: Text("${radius.toStringAsFixed(0)} km"),
            selected: isSelected,
            backgroundColor: surfaceColor,
            selectedColor: primaryColor,
            onSelected: (_) => _selectRadius(radius),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : textMainColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          );
        },
      ),
    );
  }

  bool get _hasLocation => latitud != null && longitud != null;

  Widget _buildFilterBar() {
    final hasPriceFilter = minPrecio != null || maxPrecio != null;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _nearbyActionButton(),
          const SizedBox(width: 6),
          _filterButton(
            icon: Icons.payments_outlined,
            active: hasPriceFilter,
            tooltip: "Precio mín / máx",
            onPressed: _openPriceRangeFilter,
          ),
          const SizedBox(width: 6),
          _filterButton(
            icon: Icons.timer_outlined,
            active: maxDuracionMin != null,
            tooltip: "Duración máxima",
            onPressed: _openDurationFilter,
          ),
          const SizedBox(width: 6),
          _filterButton(
            icon: Icons.event_available,
            active: disponibleFecha != null,
            tooltip: "Filtrar por disponibilidad",
            onPressed: _openAvailabilityFilter,
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(width: 6),
            _filterButton(
              icon: Icons.filter_alt_off,
              active: false,
              tooltip: "Limpiar filtros",
              onPressed: _clearFilters,
            ),
          ],
        ],
      ),
    );
  }

  Widget _nearbyActionButton() {
    return TextButton.icon(
      onPressed: locating ? null : _useMyLocation,
      style: TextButton.styleFrom(
        backgroundColor: _hasLocation ? secondaryColor : surfaceColor,
        foregroundColor: _hasLocation ? Colors.white : primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: locating
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _hasLocation ? Colors.white : primaryColor,
              ),
            )
          : Icon(
              _hasLocation ? Icons.my_location : Icons.near_me_outlined,
              size: 18,
            ),
      label: Text(
        _hasLocation
            ? "Cerca · ${radioKm.toStringAsFixed(0)} km"
            : "Cercanos",
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _filterButton({
    required IconData icon,
    required bool active,
    required String tooltip,
    required VoidCallback? onPressed,
    bool busy = false,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: active ? secondaryColor : surfaceColor,
        foregroundColor: active ? Colors.white : primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: busy
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: primaryColor,
              ),
            )
          : Icon(icon),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 48, color: textSecondaryColor),
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondaryColor),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadShops,
                style: FilledButton.styleFrom(backgroundColor: primaryColor),
                child: const Text("Reintentar"),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasServiceSearchActive) {
      if (matchedServices.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              query.trim().isNotEmpty
                  ? "No se encontraron servicios activos para \"$query\" con los filtros seleccionados."
                  : "No se encontraron servicios activos con los filtros seleccionados.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: textSecondaryColor),
            ),
          ),
        );
      }

      return RefreshIndicator(
        color: primaryColor,
        onRefresh: _loadShops,
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: matchedServices.length,
          itemBuilder: (context, index) =>
              _buildServiceCard(matchedServices[index]),
        ),
      );
    }

    if (shops.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _hasActiveFilters
                ? _hasLocation
                    ? "No se encontraron negocios dentro de ${radioKm.toStringAsFixed(0)} km con los filtros seleccionados."
                    : "No se encontraron negocios con los filtros seleccionados."
                : "No hay negocios registrados por el momento.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: textSecondaryColor),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: _loadShops,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: shops.length,
        itemBuilder: (context, index) => _buildShopCard(shops[index]),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> item) {
    final Shop shop = item['shop'] as Shop;
    final String sName = item['serviceName'] as String;
    final String sDesc = item['serviceDescription'] as String;
    final String priceText = _singlePriceLabel(item['price']);
    final String imgUrl = (item['image'] as String?) ?? '';
    final dynamic duration = item['duration'];

    return Card(
      color: surfaceColor,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openServiceDetailsModal(item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imgUrl.isNotEmpty
                    ? Image.network(
                        imgUrl,
                        width: 68,
                        height: 68,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _serviceImagePlaceholder(),
                      )
                    : _serviceImagePlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textMainColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shop.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sDesc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          priceText,
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                        if (duration != null) ...[
                          const Spacer(),
                          Text(
                            "$duration min",
                            style: TextStyle(
                              color: textSecondaryColor,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: textSecondaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _serviceImagePlaceholder() {
    return Container(
      width: 68,
      height: 68,
      color: secondaryColor.withValues(alpha: 0.14),
      child: Icon(Icons.miscellaneous_services, color: secondaryColor),
    );
  }

  Widget _buildShopCard(Shop shop) {
    final imageUrl = _getImageUrl(shop.imagenNegocio);
    final address = shop.direccion ?? shop.ciudad ?? "Ubicación no registrada";
    final distanceText = _distanceLabel(shop);

    return Card(
      color: surfaceColor,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushNamed(context, '/businessDetail', arguments: shop);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textMainColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: secondaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            shop.categoriaNegocio,
                            style: TextStyle(
                              color: secondaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (distanceText.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.near_me,
                            size: 13,
                            color: textSecondaryColor,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            distanceText,
                            style: TextStyle(
                              color: textSecondaryColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: textSecondaryColor,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          _priceLabel(shop),
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        if (shop.serviciosCount > 0)
                          Text(
                            "${shop.serviciosCount} servicio(s)",
                            style: TextStyle(
                              color: textSecondaryColor,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                    if (shop.servicios.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        shop.servicios.length > 2
                            ? "${shop.servicios.take(2).join(' · ')} · …"
                            : shop.servicios.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textSecondaryColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          shop.valoracion == null
                              ? Icons.star_border
                              : Icons.star,
                          color: Colors.amber,
                          size: 15,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          shop.valoracion == null
                              ? "Sin valoraciones"
                              : shop.valoracion!.toStringAsFixed(1),
                          style: TextStyle(
                            color: textSecondaryColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: textSecondaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 76,
      height: 76,
      color: primaryColor.withValues(alpha: 0.12),
      child: Icon(Icons.store, color: primaryColor),
    );
  }
}