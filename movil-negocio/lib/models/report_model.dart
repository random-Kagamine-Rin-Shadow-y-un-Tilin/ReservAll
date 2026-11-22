import 'reserva_model.dart';

class ReportTotals {
  final int reservas;
  final int completadas;
  final int canceladas;
  final int pendientes;
  final int confirmadas;
  final double ingresos;
  final double ticketPromedio;
  final double tasaCancelacion;
  final int clientesUnicos;

  ReportTotals({
    required this.reservas,
    required this.completadas,
    required this.canceladas,
    required this.pendientes,
    required this.confirmadas,
    required this.ingresos,
    required this.ticketPromedio,
    required this.tasaCancelacion,
    required this.clientesUnicos,
  });

  factory ReportTotals.fromJson(Map<String, dynamic> json) => ReportTotals(
        reservas: int.tryParse('${json['reservas']}') ?? 0,
        completadas: int.tryParse('${json['completadas']}') ?? 0,
        canceladas: int.tryParse('${json['canceladas']}') ?? 0,
        pendientes: int.tryParse('${json['pendientes']}') ?? 0,
        confirmadas: int.tryParse('${json['confirmadas']}') ?? 0,
        ingresos: double.tryParse('${json['ingresos']}') ?? 0.0,
        ticketPromedio: double.tryParse('${json['ticket_promedio']}') ?? 0.0,
        tasaCancelacion:
            double.tryParse('${json['tasa_cancelacion']}') ?? 0.0,
        clientesUnicos: int.tryParse('${json['clientes_unicos']}') ?? 0,
      );
}

class ReportRange {
  final DateTime desde;
  final DateTime hasta;
  final int dias;

  ReportRange({required this.desde, required this.hasta, required this.dias});

  factory ReportRange.fromJson(Map<String, dynamic> json) => ReportRange(
        desde: DateTime.tryParse('${json['desde']}') ?? DateTime.now(),
        hasta: DateTime.tryParse('${json['hasta']}') ?? DateTime.now(),
        dias: int.tryParse('${json['dias']}') ?? 0,
      );
}

class ReportDailyPoint {
  final DateTime fecha;
  final int total;
  final int completadas;
  final int canceladas;
  final double ingresos;

  ReportDailyPoint({
    required this.fecha,
    required this.total,
    required this.completadas,
    required this.canceladas,
    required this.ingresos,
  });

  factory ReportDailyPoint.fromJson(Map<String, dynamic> json) =>
      ReportDailyPoint(
        fecha: DateTime.tryParse('${json['fecha']}') ?? DateTime.now(),
        total: int.tryParse('${json['total']}') ?? 0,
        completadas: int.tryParse('${json['completadas']}') ?? 0,
        canceladas: int.tryParse('${json['canceladas']}') ?? 0,
        ingresos: double.tryParse('${json['ingresos']}') ?? 0.0,
      );
}

class ReportServiceItem {
  final int servicioId;
  final String nombre;
  final int reservas;
  final int completadas;
  final double ingresos;

  ReportServiceItem({
    required this.servicioId,
    required this.nombre,
    required this.reservas,
    required this.completadas,
    required this.ingresos,
  });

  factory ReportServiceItem.fromJson(Map<String, dynamic> json) =>
      ReportServiceItem(
        servicioId: int.tryParse('${json['servicio_id']}') ?? 0,
        nombre: json['nombre']?.toString() ?? '',
        reservas: int.tryParse('${json['reservas']}') ?? 0,
        completadas: int.tryParse('${json['completadas']}') ?? 0,
        ingresos: double.tryParse('${json['ingresos']}') ?? 0.0,
      );
}

class ReportProfessionalItem {
  final int profesionalId;
  final String nombre;
  final int reservas;
  final int completadas;
  final double ingresos;

  ReportProfessionalItem({
    required this.profesionalId,
    required this.nombre,
    required this.reservas,
    required this.completadas,
    required this.ingresos,
  });

  factory ReportProfessionalItem.fromJson(Map<String, dynamic> json) =>
      ReportProfessionalItem(
        profesionalId: int.tryParse('${json['profesional_id']}') ?? 0,
        nombre: json['nombre']?.toString() ?? '',
        reservas: int.tryParse('${json['reservas']}') ?? 0,
        completadas: int.tryParse('${json['completadas']}') ?? 0,
        ingresos: double.tryParse('${json['ingresos']}') ?? 0.0,
      );
}

class ReportStatusItem {
  final EstadoReserva estado;
  final int total;

  ReportStatusItem({required this.estado, required this.total});

  factory ReportStatusItem.fromJson(Map<String, dynamic> json) =>
      ReportStatusItem(
        estado: EstadoReserva.fromString(json['estado']?.toString() ?? ''),
        total: int.tryParse('${json['total']}') ?? 0,
      );
}

class ReportWeekdayItem {
  final int dia;
  final String label;
  final int total;
  final double ingresos;

  ReportWeekdayItem({
    required this.dia,
    required this.label,
    required this.total,
    required this.ingresos,
  });

  factory ReportWeekdayItem.fromJson(Map<String, dynamic> json) =>
      ReportWeekdayItem(
        dia: int.tryParse('${json['dia']}') ?? 0,
        label: json['label']?.toString() ?? '',
        total: int.tryParse('${json['total']}') ?? 0,
        ingresos: double.tryParse('${json['ingresos']}') ?? 0.0,
      );
}

class ReportHourItem {
  final int hora;
  final int total;

  ReportHourItem({required this.hora, required this.total});

  factory ReportHourItem.fromJson(Map<String, dynamic> json) => ReportHourItem(
        hora: int.tryParse('${json['hora']}') ?? 0,
        total: int.tryParse('${json['total']}') ?? 0,
      );
}

class Report {
  final ReportRange rango;
  final ReportTotals totales;
  final ReportTotals comparacion;
  final List<ReportDailyPoint> diario;
  final List<ReportServiceItem> serviciosTop;
  final List<ReportProfessionalItem> profesionalesTop;
  final List<ReportStatusItem> estados;
  final List<ReportWeekdayItem> diasSemana;
  final List<ReportHourItem> horasPico;

  Report({
    required this.rango,
    required this.totales,
    required this.comparacion,
    required this.diario,
    required this.serviciosTop,
    required this.profesionalesTop,
    required this.estados,
    required this.diasSemana,
    required this.horasPico,
  });

  factory Report.fromJson(Map<String, dynamic> json) => Report(
        rango: ReportRange.fromJson(
          (json['rango'] as Map<String, dynamic>?) ?? const {},
        ),
        totales: ReportTotals.fromJson(
          (json['totales'] as Map<String, dynamic>?) ?? const {},
        ),
        comparacion: ReportTotals.fromJson(
          (json['comparacion'] as Map<String, dynamic>?) ?? const {},
        ),
        diario: (json['diario'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ReportDailyPoint.fromJson)
            .toList(),
        serviciosTop: (json['servicios_top'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ReportServiceItem.fromJson)
            .toList(),
        profesionalesTop: (json['profesionales_top'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ReportProfessionalItem.fromJson)
            .toList(),
        estados: (json['estados'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ReportStatusItem.fromJson)
            .toList(),
        diasSemana: (json['dias_semana'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ReportWeekdayItem.fromJson)
            .toList(),
        horasPico: (json['horas_pico'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ReportHourItem.fromJson)
            .toList(),
      );
}
