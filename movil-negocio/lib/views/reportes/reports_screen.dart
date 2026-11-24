import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../controllers/report_controller.dart';
import '../../models/report_model.dart';

class ReportsScreen extends StatefulWidget {
  final int shopId;
  const ReportsScreen({super.key, required this.shopId});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportController>().cargar(widget.shopId);
    });
  }

  Future<void> _recargar() => context.read<ReportController>().cargar(
        widget.shopId,
      );

  Future<void> _elegirRango() async {
    final ctrl = context.read<ReportController>();
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 730)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: ctrl.desde, end: ctrl.hasta),
    );
    if (rango == null) return;
    await ctrl.cargar(
      widget.shopId,
      desde: rango.start,
      hasta: rango.end,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reportes'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Cambiar rango',
            onPressed: _elegirRango,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _recargar,
          ),
        ],
      ),
      body: Consumer<ReportController>(
        builder: (context, ctrl, _) {
          if (ctrl.isLoading && ctrl.report == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (ctrl.errorMessage != null && ctrl.report == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 56,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ctrl.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _recargar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          final report = ctrl.report;
          if (report == null) {
            return const Center(child: Text('No hay datos del reporte'));
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _recargar,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
              children: [
                _RangoBanner(
                  desde: ctrl.desde,
                  hasta: ctrl.hasta,
                  dias: report.rango.dias,
                  onTap: _elegirRango,
                ),
                const SizedBox(height: 12),
                _TotalesCard(totales: report.totales),
                const SizedBox(height: 12),
                _ComparacionCard(
                  actual: report.totales,
                  anterior: report.comparacion,
                ),
                const SizedBox(height: 12),
                _SeccionLista(
                  titulo: 'Servicios top',
                  vacio: 'Sin servicios en el rango',
                  filas: report.serviciosTop
                      .map(
                        (s) => _FilaDatos(
                          titulo: s.nombre,
                          detalle: '${s.reservas} reservas · '
                              '${s.completadas} completadas',
                          valor: '\$${s.ingresos.toStringAsFixed(2)}',
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                _SeccionLista(
                  titulo: 'Personal top',
                  vacio: 'Sin personal en el rango',
                  filas: report.profesionalesTop
                      .map(
                        (p) => _FilaDatos(
                          titulo: p.nombre,
                          detalle: '${p.reservas} reservas · '
                              '${p.completadas} completadas',
                          valor: '\$${p.ingresos.toStringAsFixed(2)}',
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                _SeccionLista(
                  titulo: 'Reservas por estado',
                  vacio: 'Sin reservas en el rango',
                  filas: report.estados
                      .map(
                        (e) => _FilaDatos(
                          titulo: e.estado.label,
                          detalle: '',
                          valor: '${e.total}',
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                _SeccionLista(
                  titulo: 'Días de la semana',
                  vacio: 'Sin datos',
                  filas: report.diasSemana
                      .map(
                        (d) => _FilaDatos(
                          titulo: d.label,
                          detalle: '${d.total} reservas',
                          valor: '\$${d.ingresos.toStringAsFixed(2)}',
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                _SeccionLista(
                  titulo: 'Horas pico',
                  vacio: 'Sin datos',
                  filas: report.horasPico
                      .map(
                        (h) => _FilaDatos(
                          titulo:
                              '${h.hora.toString().padLeft(2, '0')}:00',
                          detalle: '',
                          valor: '${h.total} reservas',
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                _SeccionLista(
                  titulo: 'Evolución diaria',
                  vacio: 'Sin datos en el rango',
                  filas: report.diario
                      .map(
                        (d) => _FilaDatos(
                          titulo:
                              '${d.fecha.day.toString().padLeft(2, '0')}/'
                              '${d.fecha.month.toString().padLeft(2, '0')}',
                          detalle: '${d.total} reservas · '
                              '${d.canceladas} canceladas',
                          valor: '\$${d.ingresos.toStringAsFixed(2)}',
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _fecha(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';

class _RangoBanner extends StatelessWidget {
  final DateTime desde;
  final DateTime hasta;
  final int dias;
  final VoidCallback onTap;
  const _RangoBanner({
    required this.desde,
    required this.hasta,
    required this.dias,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.date_range, color: AppColors.primary),
        title: Text('${_fecha(desde)} — ${_fecha(hasta)}'),
        subtitle: Text('$dias día${dias == 1 ? "" : "s"}'),
        trailing: const Icon(Icons.edit, size: 18),
        onTap: onTap,
      ),
    );
  }
}

class _TotalesCard extends StatelessWidget {
  final ReportTotals totales;
  const _TotalesCard({required this.totales});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Totales',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _dato('Ingresos', '\$${totales.ingresos.toStringAsFixed(2)}',
                    AppColors.success),
                _dato('Reservas', '${totales.reservas}', AppColors.primary),
                _dato('Completadas', '${totales.completadas}',
                    AppColors.success),
                _dato('Canceladas', '${totales.canceladas}', AppColors.error),
                _dato('Pendientes', '${totales.pendientes}', AppColors.warning),
                _dato('Confirmadas', '${totales.confirmadas}', AppColors.info),
                _dato(
                  'Ticket promedio',
                  '\$${totales.ticketPromedio.toStringAsFixed(2)}',
                  AppColors.info,
                ),
                _dato(
                  'Tasa cancelación',
                  '${totales.tasaCancelacion.toStringAsFixed(1)}%',
                  AppColors.error,
                ),
                _dato('Clientes únicos', '${totales.clientesUnicos}',
                    AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dato(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparacionCard extends StatelessWidget {
  final ReportTotals actual;
  final ReportTotals anterior;
  const _ComparacionCard({required this.actual, required this.anterior});

  int _diff(int a, int b) => a - b;
  double _diffDouble(double a, double b) => a - b;

  @override
  Widget build(BuildContext context) {
    final difReservas = _diff(actual.reservas, anterior.reservas);
    final difIngresos = _diffDouble(actual.ingresos, anterior.ingresos);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparación con el periodo anterior',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _fila('Reservas', difReservas),
            const SizedBox(height: 8),
            _fila('Ingresos', difIngresos, dinero: true),
          ],
        ),
      ),
    );
  }

  Widget _fila(String label, num diff, {bool dinero = false}) {
    final positivo = diff >= 0;
    final color = positivo ? AppColors.success : AppColors.error;
    final texto = dinero
        ? '${positivo ? "+" : "-"}\$${diff.abs().toStringAsFixed(2)}'
        : '${positivo ? "+" : ""}$diff';
    return Row(
      children: [
        Expanded(child: Text(label)),
        Icon(
          positivo ? Icons.trending_up : Icons.trending_down,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _FilaDatos {
  final String titulo;
  final String detalle;
  final String valor;
  _FilaDatos({
    required this.titulo,
    required this.detalle,
    required this.valor,
  });
}

class _SeccionLista extends StatelessWidget {
  final String titulo;
  final String vacio;
  final List<_FilaDatos> filas;
  const _SeccionLista({
    required this.titulo,
    required this.vacio,
    required this.filas,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            if (filas.isEmpty)
              Text(
                vacio,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              )
            else
              ...filas.map(
                (f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.titulo,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            if (f.detalle.isNotEmpty)
                              Text(
                                f.detalle,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        f.valor,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
