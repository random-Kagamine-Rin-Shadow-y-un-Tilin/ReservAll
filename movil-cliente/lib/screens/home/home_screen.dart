import 'package:flutter/material.dart';
import '../business/business_list_screen.dart';
import '../booking/booking_list_screen.dart';
import '../profile/profile_screen.dart';
// Asegúrate de importar tu pantalla de favoritos creada previamente:
import '../favorites/favorites_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Se añade FavoritesScreen a la lista de pantallas controladas por el BottomNavigationBar
  final List<Widget> _screens = [
    const _HomeContent(),
    const FavoritesScreen(), // <-- Pestaña de Favoritos
    const BookingListScreen(), 
    const ProfileScreen(),  
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F1),
      appBar: AppBar(
        title: const Text('SRLN'),
        backgroundColor: const Color(0xFFE2725B),
        centerTitle: true,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFFE2725B),
        unselectedItemColor: const Color(0xFF7A7267),
        type: BottomNavigationBarType.fixed, // Necesario si tienes 4 o más elementos
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoritos'), // <-- Ícono en la barra
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Reservas'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Agenda tu próxima cita en segundos',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2B2118)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Restaurantes, barberías, spas y más — todo en un solo lugar, sin llamadas ni esperas.',
              style: TextStyle(fontSize: 14, color: Color(0xFF7A7267)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _categoryCard(context, Icons.restaurant, 'Restaurante', const Color(0xFFE9C46A)),
                const SizedBox(width: 12),
                _categoryCard(context, Icons.cut, 'Barberia', const Color(0xFF2A9D8F)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _categoryCard(context, Icons.spa, 'Spa', const Color(0xFFE2725B)),
                const SizedBox(width: 12),
                _categoryCard(context, Icons.brush, 'Belleza', const Color(0xFFE63946)),
              ],
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE2725B),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/business');
              },
              child: const Text('Reservar ahora', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _categoryCard(BuildContext context, IconData icon, String title, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/business', arguments: title);
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B2118))),
          ],
        ),
      ),
    );
  }
}