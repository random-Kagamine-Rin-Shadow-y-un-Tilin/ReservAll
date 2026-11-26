import 'package:flutter/material.dart';

/// Clave global para navegar sin usar el BuildContext de una pantalla que el
/// propio rebuild del auth puede estar por desmontar (p. ej. al cerrar sesión).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
