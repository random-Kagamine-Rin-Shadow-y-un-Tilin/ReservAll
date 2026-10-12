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
  final TextEditingController searchController = TextEditingController();

  Future<void> fetchShopsList() async {
    try {
      final url = widget.category != null
          ? "$baseUrl/client/list-shops?category=${widget.category}"
          : "$baseUrl/client/list-shops";

      final response = await http.get(
        Uri.parse(url),
        headers: {"accept": "application/json", "x-api-key": apiKey},
      );
      if (response.statusCode == 200) {
        setState(() => shops = jsonDecode(response.body));
      }
    } catch (e) {
      print("Error al cargar negocios: $e");
    }
  }

  Future<void> searchShops(String query) async {
    if (query.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Escribe al menos 2 letras")),
      );
      return;
    }
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/client/search?q=$query"),
        headers: {"accept": "application/json", "x-api-key": apiKey},
      );
      if (response.statusCode == 200) {
        setState(() => shops = jsonDecode(response.body));
      }
    } catch (e) {
      print("Error en búsqueda: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchShopsList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category ?? "Negocios"), 
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Buscar negocio...",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => searchShops(searchController.text),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: shops.length,
              itemBuilder: (context, index) {
                final shop = shops[index];
                return Card(
                  child: ListTile(
                    title: Text(shop['nombre']),
                    subtitle: Text(shop['descripcion']),
                    leading: (shop['imagen_negocio'] != null &&
                              shop['imagen_negocio'].toString().startsWith("http"))
                        ? Image.network(
                            shop['imagen_negocio'],
                            width: 50,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.store),
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
