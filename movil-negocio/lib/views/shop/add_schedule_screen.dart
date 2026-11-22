import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../controllers/shop_controller.dart';

class AddScheduleScreen extends StatefulWidget {
  final int shopId;
  const AddScheduleScreen({super.key, required this.shopId});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  static const _dias = <Map<String, String>>[
    {'value': 'lunes', 'label': 'Lunes'},
    {'value': 'martes', 'label': 'Martes'},
    {'value': 'miercoles', 'label': 'Miércoles'},
    {'value': 'jueves', 'label': 'Jueves'},
    {'value': 'viernes', 'label': 'Viernes'},
    {'value': 'sabado', 'label': 'Sábado'},
    {'value': 'domingo', 'label': 'Domingo'},
  ];

  String? _dia;
  TimeOfDay _apertura = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _cierre = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay? _descanso;

  @override
  void initState() {
    super.initState();
    final existentes = context.read<ShopController>()
        .fullProfile
        ?.schedules
        .map((s) => s.dia)
        .toSet() ??
        <String>{};
    final disponibles =
        _dias.where((d) => !existentes.contains(d['value'])).toList();
    _dia = disponibles.isNotEmpty ? disponibles.first['value'] : null;
  }

  String _format(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:00';

  List<Map<String, String>> get _disponibles {
    final existentes = context.watch<ShopController>().fullProfile?.schedules
            .map((s) => s.dia)
            .toSet() ??
        <String>{};
    return _dias
        .where((d) => !existentes.contains(d['value']) || d['value'] == _dia)
        .toList();
  }

  Future<void> _guardar() async {
    if (_dia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un día'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final apertura = _apertura.hour * 60 + _apertura.minute;
    final cierre = _cierre.hour * 60 + _cierre.minute;
    if (apertura >= cierre) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La hora de apertura debe ser menor que la de cierre'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final controller = context.read<ShopController>();
    final ok = await controller.registerSchedule(
      widget.shopId,
      dia: _dia!,
      horaApertura: _format(_apertura),
      horaCierre: _format(_cierre),
      horaDescanso: _descanso != null ? _format(_descanso!) : null,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _elegir({required bool apertura}) async {
    final actual = apertura ? _apertura : _cierre;
    final picked = await showTimePicker(context: context, initialTime: actual);
    if (picked == null) return;
    setState(() {
      if (apertura) {
        _apertura = picked;
      } else {
        _cierre = picked;
      }
    });
  }

  Future<void> _elegirDescanso() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _descanso ?? const TimeOfDay(hour: 14, minute: 0),
    );
    if (picked != null) setState(() => _descanso = picked);
  }

  @override
  Widget build(BuildContext context) {
    final disponibles = _disponibles;
    if (disponibles.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Nuevo horario'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Ya tienes horarios registrados para todos los días.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo horario'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            value: _dia,
            decoration: const InputDecoration(
              labelText: 'Día',
              border: OutlineInputBorder(),
            ),
            items: disponibles
                .map(
                  (d) => DropdownMenuItem(
                    value: d['value'],
                    child: Text(d['label']!),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _dia = v),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.login, color: AppColors.primary),
              title: const Text('Hora de apertura'),
              subtitle: Text(_apertura.format(context)),
              trailing: const Icon(Icons.edit, size: 18),
              onTap: () => _elegir(apertura: true),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.primary),
              title: const Text('Hora de cierre'),
              subtitle: Text(_cierre.format(context)),
              trailing: const Icon(Icons.edit, size: 18),
              onTap: () => _elegir(apertura: false),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.free_breakfast, color: AppColors.primary),
              title: const Text('Descanso (opcional)'),
              subtitle: Text(
                _descanso == null
                    ? 'Sin descanso'
                    : _descanso!.format(context),
              ),
              trailing: _descanso == null
                  ? const Icon(Icons.add)
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _descanso = null),
                    ),
              onTap: _elegirDescanso,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _guardar,
            icon: const Icon(Icons.save),
            label: const Text('Guardar horario'),
          ),
        ],
      ),
    );
  }
}
