import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/services/api_service.dart';

class BusinessListScreen extends StatefulWidget {
  final String? category;
  const BusinessListScreen({super.key, this.category});

  @override
  State<BusinessListScreen> createState() => _BusinessListScreenState();
}

class _BusinessListScreenState extends State<BusinessListScreen> {
  List<dynamic> shops = [];
  bool isLoading = false;
  bool _isFirstLoad = true;
  final TextEditingController searchController = TextEditingController();
  late String? selectedCategory;

  final List<String> categories = [
    "Todos",
    "Barberia",
    "Spa",
    "Restaurante",
    "Belleza",
    "Otro"
  ];

  final Color primaryColor = const Color(0xFFE2725B);      
  final Color secondaryColor = const Color(0xFF2A9D8F);    
  final Color backgroundColor = const Color(0xFFFAF6F1);   
  final Color surfaceColor = const Color(0xFFFFFFFF);     
  final Color textMainColor = const Color(0xFF2B2118);     
  final Color textSecondaryColor = const Color(0xFF7A7267);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstLoad) {
      final routeArgs = ModalRoute.of(context)?.settings.arguments as String?;
      selectedCategory = widget.category ?? routeArgs ?? "Todos";
      fetchShopsList(category: selectedCategory == "Todos" ? null : selectedCategory);
      _isFirstLoad = false;
    }
  }

  Future<void> fetchShopsList({String? category}) async {
    setState(() => isLoading = true);
    try {
      final bool isAll = category == null || category == "Todos";
      
      const Map<String, int> categoryIds = {
        "Barberia": 1,
        "Spa": 2,
        "Restaurante": 3,
        "Belleza": 4,
        "Otro": 5,
      };

     
      String url = "$baseUrl/client/list-shops";
      if (!isAll && category != null) {
        url = "$baseUrl/client/list-shops?category=$category";
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {"accept": "application/json", "x-api-key": apiKey},
      );
      
      if (response.statusCode == 200) {
        List<dynamic> allShops = jsonDecode(response.body);

        if (!isAll && category != null) {
          final int? targetId = categoryIds[category];

          allShops = allShops.where((shop) {
            var shopCatId = shop['fk_categoria'] ?? 
                              shop['id_categoria'] ?? 
                              shop['categoria_id'];

            var shopCatName = shop['categoria'] ?? 
                                shop['nombre_categoria'] ?? 
                                shop['category'];

            if (shopCatId is Map) {
              shopCatId = shopCatId['id_categoria'] ?? shopCatId['id'];
            }
            if (shopCatName is Map) {
              shopCatName = shopCatName['nombre_categoria'] ?? shopCatName['nombre'];
            }

            bool matchesId = targetId != null && shopCatId != null && shopCatId.toString() == targetId.toString();
            
            bool matchesName = shopCatName != null && 
                shopCatName.toString().toLowerCase().trim() == category.toLowerCase().trim();

            return matchesId || matchesName;
          }).toList();
        }

        setState(() => shops = allShops);
      }
    } catch (e) {
      print("Error al cargar negocios: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> searchShops(String query) async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/client/search-by-name?name=$query"),
        headers: {"accept": "application/json", "x-api-key": apiKey},
      );
      if (response.statusCode == 200) {
        setState(() => shops = jsonDecode(response.body));
      }
    } catch (e) {
      print("Error en búsqueda: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          selectedCategory == "Todos" ? "Negocios" : selectedCategory!,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              style: TextStyle(color: textMainColor),
              onChanged: (value) {
                if (value.trim().isEmpty) {
                  fetchShopsList(category: selectedCategory == "Todos" ? null : selectedCategory);
                } else {
                  searchShops(value.trim());
                }
              },
              decoration: InputDecoration(
                hintText: "Buscar negocio...",
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
                          fetchShopsList(category: selectedCategory == "Todos" ? null : selectedCategory);
                        },
                      )
                    : null,
              ),
            ),
          ),

          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    backgroundColor: surfaceColor,
                    selectedColor: secondaryColor,
                    onSelected: (bool selected) {
                      setState(() {
                        selectedCategory = cat;
                        searchController.clear();
                      });
                      fetchShopsList(category: cat == "Todos" ? null : cat);
                    },
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : textMainColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : shops.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            searchController.text.isNotEmpty
                                ? "No hay resultados referentes a '${searchController.text}'"
                                : "No hay negocios registrados en la categoría '$selectedCategory'.",
                            style: TextStyle(fontSize: 16, color: textSecondaryColor),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: shops.length,
                        itemBuilder: (context, index) {
                          final shop = shops[index];
                          return Card(
                            color: surfaceColor,
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              title: Text(
                                shop['nombre'] ?? '',
                                style: TextStyle(
                                  color: textMainColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                shop['descripcion'] ?? '',
                                style: TextStyle(color: textSecondaryColor),
                              ),
                              leading:
                                  (shop['imagen_negocio'] != null &&
                                      shop['imagen_negocio'].toString().startsWith(
                                        "http",
                                      ))
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        shop['imagen_negocio'],
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : CircleAvatar(
                                      backgroundColor: primaryColor.withValues(alpha: 0.2),
                                      child: Icon(Icons.store, color: primaryColor),
                                    ),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/businessDetail',
                                  arguments: shop,
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}