import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '/models/shop.dart';
import '/services/api_service.dart';

class BusinessListScreen extends StatefulWidget {
  final String? category;
  const BusinessListScreen({super.key, this.category});

  @override
  State<BusinessListScreen> createState() => _BusinessListScreenState();
}

class _BusinessListScreenState extends State<BusinessListScreen> {
  List<Shop> shops = [];
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
  double? latitud;
  double? longitud;
  bool locating = false;

  final Color primaryColor = const Color(0xFFE2725B);
  final Color secondaryColor = const Color(0xFF2A9D8F);
  final Color backgroundColor = const Color(0xFFFAF6F1);
  final Color surfaceColor = const Color(0xFFFFFFFF);
  final Color textMainColor = const Color(0xFF2B2118);
  final Color textSecondaryColor = const Color(0xFF7A7267);

  static const Map<String, String> _sortOptions = {
    "relevancia": "Relevancia",
    "nombre": "Nombre (A-Z)",
    "precio_asc": "Menor precio",
    "precio_desc": "Mayor precio",
    "distancia": "Más cercanos",
    "populares": "Más populares",
  };

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
    } catch (_) {
      // Las categorías son opcionales para poder mostrar el catálogo.
    }
  }

  Future<void> _loadShops() async {
    if (!mounted) return;
    final requestId = ++_requestId;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await searchCatalog(
        q: query,
        categoriaId: selectedCategoryId,
        categoria: selectedCategoryId == null && selectedCategory != "Todos"
            ? selectedCategory
            : null,
        ciudad: ciudad.isEmpty ? null : ciudad,
        lat: latitud,
        lng: longitud,
        radioKm: latitud != null && longitud != null ? 25 : null,
        fecha: disponibleFecha == null ? null : _formatDate(disponibleFecha!),
        hora: disponibleHora == null ? null : _formatTime(disponibleHora!),
        orden: orden,
      );

      if (!mounted || requestId != _requestId) return;
      setState(() {
        shops = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        shops = [];
        isLoading = false;
        errorMessage = "No se pudieron cargar los negocios. Intenta de nuevo.";
      });
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

  void _changeSort(String? value) {
    if (value == null) return;
    setState(() => orden = value);
    _loadShops();
  }

  Future<void> _openCityFilter() async {
    final controller = TextEditingController(text: ciudad);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Filtrar por ubicación"),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: "Ciudad",
            hintText: "Ej. Huamantla",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Aplicar"),
          ),
        ],
      ),
    );

    controller.dispose();
    if (result == null) return;
    setState(() => ciudad = result.trim());
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _useMyLocation() async {
    if (latitud != null && longitud != null) {
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
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage(
          "Activa la ubicación del dispositivo para usar esta opción.",
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage("No se otorgó permiso para acceder a la ubicación.");
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      if (!mounted) return;
      setState(() {
        latitud = position.latitude;
        longitud = position.longitude;
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
      latitud = null;
      longitud = null;
    });
    _loadShops();
  }

  bool get _hasActiveFilters =>
      query.isNotEmpty ||
      ciudad.isNotEmpty ||
      selectedCategory != "Todos" ||
      disponibleFecha != null ||
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
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: textSecondaryColor),
                        onPressed: () {
                          searchController.clear();
                          _onSearchChanged("");
                        },
                      )
                    : null,
              ),
            ),
          ),
          _buildCategoryChips(),
          _buildFilterBar(),
          const SizedBox(height: 4),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final items = <Widget>[
      _categoryChip("Todos", null),
      ...categories.map(
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

  bool get _hasLocation => latitud != null && longitud != null;

  Widget _buildFilterBar() {
    // HU_41: "más cercanos" solo tiene sentido si conocemos la ubicación.
    final sortEntries = _sortOptions.entries
        .where((entry) => entry.key != "distancia" || _hasLocation)
        .toList();
    final sortValue = sortEntries.any((entry) => entry.key == orden)
        ? orden
        : "relevancia";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: sortValue,
                  isExpanded: true,
                  icon: Icon(Icons.sort, color: primaryColor),
                  items: sortEntries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(
                            entry.value,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: textMainColor),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _changeSort,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          _filterButton(
            icon: _hasLocation ? Icons.my_location : Icons.near_me_outlined,
            active: _hasLocation,
            busy: locating,
            tooltip: _hasLocation
                ? "Quitar ubicación actual"
                : "Buscar negocios cerca de mí",
            onPressed: locating ? null : _useMyLocation,
          ),
          const SizedBox(width: 6),
          _filterButton(
            icon: Icons.location_on_outlined,
            active: ciudad.isNotEmpty,
            tooltip: "Filtrar por ciudad",
            onPressed: _openCityFilter,
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

    if (shops.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _hasActiveFilters
                ? "No se encontraron negocios con los filtros seleccionados."
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

  Widget _buildShopCard(Shop shop) {
    final imageUrl = _getImageUrl(shop.imagenNegocio);
    final address = shop.direccion ?? shop.ciudad ?? "Ubicación no registrada";

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
                        if (shop.distanciaKm != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.near_me,
                            size: 13,
                            color: textSecondaryColor,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            "${shop.distanciaKm!.toStringAsFixed(1)} km",
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
