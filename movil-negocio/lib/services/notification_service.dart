import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/reserva_model.dart';

/// Avisos locales de reservas.
///
/// Sin Firebase/FCM no existen notificaciones push remotas hacia la app
/// Flutter. Esta servicio programa un aviso en el dispositivo con la hora de
/// cada reserva cuando la app consulta el backend, así que funciona también
/// con la app cerrada mientras el sistema operativo permita alarmas exactas.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _prefKey = 'reservall:scheduled-notifications:v1';
  static const _channelId = 'reservall_reservas';
  static const _channelName = 'Avisos de reservas';
  static const _channelDescription =
      'Avisos cuando está por empezar una reserva';

  bool _inicializado = false;

  Future<void> init() async {
    if (_inicializado) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
      ),
    );

    if (Platform.isAndroid) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        ),
      );
      await androidPlugin?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _inicializado = true;
  }

  /// Reprograma los avisos con la lista actual de reservas próximas.
  /// Las reservas reprogramadas o canceladas pierden su aviso anterior.
  Future<void> sincronizar(List<ReservaProxima> proximas) async {
    try {
      await init();
    } catch (_) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final anteriores = (prefs.getStringList(_prefKey) ?? [])
        .map(int.tryParse)
        .whereType<int>()
        .toList();
    final ahora = DateTime.now();
    final programadas = <int>[];

    for (final proxima in proximas) {
      final reserva = proxima.reserva;
      if (reserva.estado != EstadoReserva.pendiente &&
          reserva.estado != EstadoReserva.confirmada) {
        continue;
      }

      final inicio = _horaInicio(reserva);
      if (inicio == null) continue;

      const minDelay = Duration(seconds: 30);
      const maxDelay = Duration(days: 7);
      final delay = inicio.difference(ahora);
      if (delay < minDelay || delay > maxDelay) continue;

      final id = reserva.idReserva;
      try {
        await _cancelar(id);
        await _programar(id, proxima, inicio);
        programadas.add(id);
      } catch (_) {
        // Si un aviso falla, no se detienen los demás.
      }
    }

    for (final id in anteriores) {
      if (!programadas.contains(id)) {
        try {
          await _cancelar(id);
        } catch (_) {}
      }
    }

    await prefs.setStringList(
      _prefKey,
      programadas.map((id) => id.toString()).toList(),
    );
  }

  DateTime? _horaInicio(ReservaListItem reserva) {
    final partes = reserva.horaInicio.split(':');
    if (partes.length < 2) return null;

    final hora = int.tryParse(partes[0]);
    final minuto = int.tryParse(partes[1]);
    if (hora == null || minuto == null) return null;

    return DateTime(
      reserva.fecha.year,
      reserva.fecha.month,
      reserva.fecha.day,
      hora,
      minuto,
    );
  }

  Future<void> _programar(
    int id,
    ReservaProxima proxima,
    DateTime inicio,
  ) async {
    final reserva = proxima.reserva;
    final hora = reserva.horaInicio.length >= 5
        ? reserva.horaInicio.substring(0, 5)
        : reserva.horaInicio;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.event,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    // Se usa el instante en milisegundos para no depender de la zona horaria
    // del paquete `timezone`: `inicio` ya es una hora local del dispositivo.
    final programada = tz.TZDateTime.fromMillisecondsSinceEpoch(
      tz.UTC,
      inicio.millisecondsSinceEpoch,
    );
    const titulo = 'Tu reserva empieza ahora';
    final cuerpo =
        '${reserva.clienteNombre} · ${reserva.servicioNombre} · $hora · '
        '${proxima.negocioNombre}';

    if (Platform.isAndroid) {
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: titulo,
          body: cuerpo,
          scheduledDate: programada,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: '/reservas',
        );
        return;
      } catch (_) {
        // Android 12+ puede denegar alarmas exactas; se usa una alarma
        // aproximada para que el aviso igualmente llegue.
      }
    }

    await _plugin.zonedSchedule(
      id: id,
      title: titulo,
      body: cuerpo,
      scheduledDate: programada,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '/reservas',
    );
  }

  Future<void> _cancelar(int id) => _plugin.cancel(id: id);

  /// Al cerrar sesión se quitan los avisos programados del dispositivo.
  Future<void> cancelarTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_prefKey) ?? [])
        .map(int.tryParse)
        .whereType<int>()
        .toList();
    for (final id in ids) {
      try {
        await _cancelar(id);
      } catch (_) {}
    }
    await prefs.remove(_prefKey);
  }
}
