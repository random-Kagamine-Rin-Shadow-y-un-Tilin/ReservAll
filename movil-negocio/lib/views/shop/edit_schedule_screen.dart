import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../controllers/shop_controller.dart';
import '../../models/shop_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_widget.dart';

class EditScheduleScreen extends StatefulWidget {
  final int shopId;
  final ShopSchedule schedule;

  const EditScheduleScreen({
    super.key,
    required this.shopId,
    required this.schedule,
  });

  @override
  State<EditScheduleScreen> createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends State<EditScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TimeOfDay _apertura;
  late TimeOfDay _cierre;
  TimeOfDay? _descanso;

  @override
  void initState() {
    super.initState();
    _apertura =
        _parseTime(widget.schedule.horaApertura) ??
        const TimeOfDay(hour: 9, minute: 0);
    _cierre =
        _parseTime(widget.schedule.horaCierre) ??
        const TimeOfDay(hour: 18, minute: 0);
    if (widget.schedule.horaDescanso != null) {
      _descanso = _parseTime(widget.schedule.horaDescanso!);
    }
  }

  TimeOfDay? _parseTime(String time) {
    try {
      final parts = time.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _pickApertura() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _apertura,
    );
    if (picked != null) setState(() => _apertura = picked);
  }

  Future<void> _pickCierre() async {
    final picked = await showTimePicker(context: context, initialTime: _cierre);
    if (picked != null) setState(() => _cierre = picked);
  }

  Future<void> _pickDescanso() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _descanso ?? const TimeOfDay(hour: 14, minute: 0),
    );
    if (picked != null) setState(() => _descanso = picked);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<ShopController>();
    final success = await controller.editSchedule(
      widget.shopId,
      widget.schedule.idHorario,
      horaApertura: _formatTime(_apertura),
      horaCierre: _formatTime(_cierre),
      horaDescanso: _descanso != null ? _formatTime(_descanso!) : null,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Horario actualizado'),
          backgroundColor: AppColors.success,
        ),
      );
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

  Widget _timeTile(String label, TimeOfDay time, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.access_time, color: AppColors.primary),
        title: Text(label),
        subtitle: Text(time.format(context)),
        trailing: const Icon(Icons.edit, size: 20),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar ${widget.schedule.dia}'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),
      body: Consumer<ShopController>(
        builder: (context, controller, child) {
          if (controller.isLoading) return const LoadingWidget();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _timeTile('Hora de apertura', _apertura, _pickApertura),
                  _timeTile('Hora de cierre', _cierre, _pickCierre),
                  _timeTile(
                    'Hora de descanso (opcional)',
                    _descanso ?? const TimeOfDay(hour: 14, minute: 0),
                    _pickDescanso,
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Guardar cambios',
                    onPressed: _handleSave,
                    isPrimary: true,
                    icon: Icons.save,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
