import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/services/api_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<dynamic> favoritesList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFavorites();
  }

  Future<Map<String, String>> _getHeaders() async {
    return {
      "accept": "application/json",
      "content-type": "application/json",
      "x-api-key": apiKey,
    };
  }

  Future<void> fetchFavorites() async {
    setState(() => isLoading = true);
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("$baseUrl/client/favorites"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data is List) {
            favoritesList = data;
          } else if (data is Map) {
            favoritesList = data['favorites'] ?? data['data'] ?? [];
          } else {
            favoritesList = [];
          }
        });
      } else {
        print("Error al cargar favoritos: ${response.statusCode}");
      }
    } catch (e) {
      print("Error de conexión al cargar favoritos: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> removeFavorite(dynamic shopId, int index) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse("$baseUrl/client/remove-favorite"),
        headers: headers,
        body: jsonEncode({"id_negocio": shopId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          favoritesList.removeAt(index);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Eliminado de favoritos"),
              backgroundColor: Color(0xFFE2725B),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        print("Error al eliminar favorito: ${response.statusCode}");
      }
    } catch (e) {
      print("Error de conexión al eliminar favorito: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFFE2725B);
    final Color backgroundColor = const Color(0xFFFAF6F1);
    final Color textMainColor = const Color(0xFF2B2118);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Mis Favoritos",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : favoritesList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        "Aún no tienes negocios favoritos",
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchFavorites,
                  color: primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: favoritesList.length,
                    itemBuilder: (context, index) {
                      final item = favoritesList[index];
                      final String nombre = item['nombre'] ?? item['nombre_negocio'] ?? 'Negocio';
                      final String imagen = item['imagen_negocio'] ?? item['imagen'] ?? '';
                      final String categoria = item['categoria'] ?? item['nombre_categoria'] ?? '';
                      final shopId = item['id'] ?? item['id_negocio'] ?? item['business_id'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imagen.isNotEmpty && imagen != "null"
                                ? Image.network(
                                    imagen.startsWith("http") ? imagen : "$baseUrl/static/$imagen",
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(width: 60, height: 60, color: Colors.grey.shade200, child: Icon(Icons.store, color: primaryColor)),
                                  )
                                : Container(width: 60, height: 60, color: Colors.grey.shade200, child: Icon(Icons.store, color: primaryColor)),
                          ),
                          title: Text(
                            nombre,
                            style: TextStyle(fontWeight: FontWeight.bold, color: textMainColor, fontSize: 16),
                          ),
                          subtitle: categoria.isNotEmpty
                              ? Text(
                                  categoria,
                                  style: TextStyle(color: Colors.grey.shade600),
                                )
                              : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.favorite, color: Colors.redAccent),
                            onPressed: () => removeFavorite(shopId, index),
                          ),
                          onTap: () {
                            Navigator.pushNamed(context, '/businessDetail', arguments: item);
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}