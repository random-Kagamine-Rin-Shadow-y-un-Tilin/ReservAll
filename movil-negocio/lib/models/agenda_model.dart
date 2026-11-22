import 'reserva_model.dart';
import 'shop_model.dart';

class AgendaSlot {
  final String horaInicio;
  final String horaFin;
  final bool disponible;
  final String? motivo;

  AgendaSlot({
    required this.horaInicio,
    required this.horaFin,
    required this.disponible,
    this.motivo,
  });

  factory AgendaSlot.fromJson(Map<String, dynamic> json) => AgendaSlot(
        horaInicio: json['hora_inicio']?.toString() ?? '',
        horaFin: json['hora_fin']?.toString() ?? '',
        disponible: json['disponible'] == true,
        motivo: json['motivo']?.toString(),
      );
}

class AgendaBlock {
  final int idBloqueo;
  final int negocioId;
  final DateTime fecha;
  final String? horaInicio;
  final String? horaFin;
  final String? motivo;
  final DateTime? fechaCreacion;

  AgendaBlock({
    required this.idBloqueo,
    required this.negocioId,
    required this.fecha,
    this.horaInicio,
    this.horaFin,
    this.motivo,
    this.fechaCreacion,
  });

  factory AgendaBlock.fromJson(Map<String, dynamic> json) => AgendaBlock(
        idBloqueo: int.tryParse('${json['id_bloqueo']}') ?? 0,
        negocioId: int.tryParse('${json['negocio_id']}') ?? 0,
        fecha: DateTime.tryParse('${json['fecha']}') ?? DateTime.now(),
        horaInicio: json['hora_inicio']?.toString(),
        horaFin: json['hora_fin']?.toString(),
        motivo: json['motivo']?.toString(),
        fechaCreacion: json['fecha_creacion'] == null
            ? null
            : DateTime.tryParse('${json['fecha_creacion']}'),
      );

  bool get diaCompleto => horaInicio == null && horaFin == null;
}

class AgendaDay {
  final DateTime fecha;
  final String diaSemana;
  final bool abierto;
  final bool bloqueado;
  final ShopSchedule? horario;
  final List<ReservaListItem> reservas;
  final List<AgendaBlock> bloqueos;
  final List<AgendaSlot> disponibilidad;

  AgendaDay({
    required this.fecha,
    required this.diaSemana,
    required this.abierto,
    required this.bloqueado,
    this.horario,
    this.reservas = const [],
    this.bloqueos = const [],
    this.disponibilidad = const [],
  });

  factory AgendaDay.fromJson(Map<String, dynamic> json) => AgendaDay(
        fecha: DateTime.tryParse('${json['fecha']}') ?? DateTime.now(),
        diaSemana: json['dia_semana']?.toString() ?? '',
        abierto: json['abierto'] == true,
        bloqueado: json['bloqueado'] == true,
        horario: json['horario'] is Map<String, dynamic>
            ? ShopSchedule.fromJson(json['horario'] as Map<String, dynamic>)
            : null,
        reservas: (json['reservas'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ReservaListItem.fromJson)
            .toList(),
        bloqueos: (json['bloqueos'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(AgendaBlock.fromJson)
            .toList(),
        disponibilidad: (json['disponibilidad'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(AgendaSlot.fromJson)
            .toList(),
      );

  int get slotsLibres => disponibilidad.where((s) => s.disponible).length;
}

class AgendaRange {
  final DateTime desde;
  final DateTime hasta;
  final int dias;

  AgendaRange({required this.desde, required this.hasta, required this.dias});

  factory AgendaRange.fromJson(Map<String, dynamic> json) => AgendaRange(
        desde: DateTime.tryParse('${json['desde']}') ?? DateTime.now(),
        hasta: DateTime.tryParse('${json['hasta']}') ?? DateTime.now(),
        dias: int.tryParse('${json['dias']}') ?? 0,
      );
}

class AgendaSummary {
  final int totalReservas;
  final int pendientes;
  final int confirmadas;
  final int completadas;
  final int canceladas;
  final int diasAbiertos;
  final int diasBloqueados;
  final int diasCerrados;

  AgendaSummary({
    required this.totalReservas,
    required this.pendientes,
    required this.confirmadas,
    required this.completadas,
    required this.canceladas,
    required this.diasAbiertos,
    required this.diasBloqueados,
    required this.diasCerrados,
  });

  factory AgendaSummary.fromJson(Map<String, dynamic> json) => AgendaSummary(
        totalReservas: int.tryParse('${json['total_reservas']}') ?? 0,
        pendientes: int.tryParse('${json['pendientes']}') ?? 0,
        confirmadas: int.tryParse('${json['confirmadas']}') ?? 0,
        completadas: int.tryParse('${json['completadas']}') ?? 0,
        canceladas: int.tryParse('${json['canceladas']}') ?? 0,
        diasAbiertos: int.tryParse('${json['dias_abiertos']}') ?? 0,
        diasBloqueados: int.tryParse('${json['dias_bloqueados']}') ?? 0,
        diasCerrados: int.tryParse('${json['dias_cerrados']}') ?? 0,
      );
}

class AgendaResponse {
  final int negocioId;
  final AgendaRange rango;
  final List<ShopSchedule> horarios;
  final List<AgendaDay> dias;
  final AgendaSummary resumen;

  AgendaResponse({
    required this.negocioId,
    required this.rango,
    required this.horarios,
    required this.dias,
    required this.resumen,
  });

  factory AgendaResponse.fromJson(Map<String, dynamic> json) => AgendaResponse(
        negocioId: int.tryParse('${json['negocio_id']}') ?? 0,
        rango: AgendaRange.fromJson(
          (json['rango'] as Map<String, dynamic>?) ?? const {},
        ),
        horarios: (json['horarios'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ShopSchedule.fromJson)
            .toList(),
        dias: (json['dias'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(AgendaDay.fromJson)
            .toList(),
        resumen: AgendaSummary.fromJson(
          (json['resumen'] as Map<String, dynamic>?) ?? const {},
        ),
      );
}

class BlockListResponse {
  final List<AgendaBlock> items;
  final int total;

  BlockListResponse({required this.items, required this.total});

  factory BlockListResponse.fromJson(Map<String, dynamic> json) =>
      BlockListResponse(
        items: (json['items'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(AgendaBlock.fromJson)
            .toList(),
        total: int.tryParse('${json['total']}') ?? 0,
      );
}
