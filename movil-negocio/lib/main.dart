import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_colors.dart';
import 'controllers/auth_controller.dart';
import 'controllers/category_controller.dart';
import 'controllers/shop_controller.dart';
import 'controllers/user_controller.dart';
import 'services/api_service.dart';
import 'views/auth/login_screen.dart';
import 'views/home/home_screen.dart';
import 'controllers/profesional_controller.dart';
import 'controllers/reserva_controller.dart';
import 'controllers/service_controller.dart';
import 'controllers/agenda_controller.dart';
import 'controllers/client_controller.dart';
import 'controllers/report_controller.dart';
import 'controllers/location_controller.dart';
import 'services/reserva_service.dart';
import 'services/agenda_service.dart';
import 'services/client_service.dart';
import 'services/report_service.dart';
import 'services/location_service.dart';

void main() {
  ApiService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthController()),
        ChangeNotifierProvider(create: (context) => ShopController()),
        ChangeNotifierProvider(create: (context) => UserController()),
        ChangeNotifierProvider(create: (_) => CategoryController()),
        ChangeNotifierProvider(create: (_) => ProfesionalController()),
        ChangeNotifierProvider(create: (_) => ServiceController()),
        ChangeNotifierProvider(
          create: (_) => ReservaController(ReservaService(ApiService())),
        ),
        ChangeNotifierProvider(
          create: (_) => AgendaController(AgendaService()),
        ),
        ChangeNotifierProvider(
          create: (_) => ClientController(ClientService()),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportController(ReportService()),
        ),
        ChangeNotifierProvider(
          create: (_) => LocationController(LocationService()),
        ),
      ],
      child: MaterialApp(
        title: 'SRNL Back',
        theme: AppTheme.lightTheme,
        home: Consumer<AuthController>(
          builder: (context, authController, child) {
            if (authController.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (authController.isAuthenticated) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<ShopController>().getMyShops();
                context.read<UserController>().getUserProfile();
              });
              return const HomeScreen();
            }

            return const LoginScreen();
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
