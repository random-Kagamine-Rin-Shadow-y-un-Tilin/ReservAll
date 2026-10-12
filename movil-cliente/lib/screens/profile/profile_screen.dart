import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F1),
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: const Color(0xFFE2725B),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Aquí irán los datos del usuario',
          style: TextStyle(fontSize: 18, color: Color(0xFF2B2118)),
        ),
      ),
    );
  }
}
