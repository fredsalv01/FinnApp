import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/widgets/finanzas_top_app_bar.dart';
import '../../shared/models/gasto.dart';
import '../../shared/services/database_helper.dart';
import '../../shared/services/user_preferences.dart';
import '../../shared/services/data_refresh_notifier.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  List<Gasto> _gastos = [];
  double _ingresos = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    DataRefreshNotifier().addListener(_loadData);
  }

  @override
  void dispose() {
    DataRefreshNotifier().removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = DatabaseHelper();
    final prefs = UserPreferences();
    final gastos = await db.getGastos();
    final income = await prefs.getUserIncome();
    if (!mounted) return;
    setState(() {
      _gastos = gastos;
      _ingresos = income ?? 0;
      _loading = false;
    });
  }

  double get _totalGastos =>
      _gastos.fold(0.0, (sum, g) => sum + g.monto);

  double get _disponible => _ingresos - _totalGastos;

  Map<String, double> get _gastosPorCategoria {
    final map = <String, double>{};
    for (final g in _gastos) {
      map[g.categoria] = (map[g.categoria] ?? 0) + g.monto;
    }
    return map;
  }

  List<Gasto> get _gastosFijos =>
      _gastos.where((g) => g.esFijo).toList();

  List<Gasto> get _gastosVariables =>
      _gastos.where((g) => !g.esFijo).toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_loading) {
      return const Scaffold(
        appBar: FinanzasTopAppBar(subtitle: 'Reportes'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const FinanzasTopAppBar(subtitle: 'Reportes'),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- Resumen financiero ---
            _buildSummaryCard(cs, tt),
            const SizedBox(height: 20),

            // --- Gráfico de Dona: distribución por categoría ---
            if (_gastosPorCategoria.isNotEmpty) ...[
              Text('Distribución por categoría',
                  style: tt.headlineMedium),
              const SizedBox(height: 12),
              _buildDonutChart(cs, tt),
              const SizedBox(height: 24),
            ],

            // --- Gráfico de Barras: fijos vs variables ---
            Text('Gastos fijos vs variables', style: tt.headlineMedium),
            const SizedBox(height: 12),
            _buildBarChart(cs, tt),
            const SizedBox(height: 24),

            // --- Lista de gastos fijos ---
            if (_gastosFijos.isNotEmpty) ...[
              Text('Gastos fijos registrados',
                  style: tt.headlineMedium),
              const SizedBox(height: 8),
              ..._gastosFijos.map((g) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cs.primaryContainer,
                        child: Icon(Icons.repeat,
                            color: cs.onPrimaryContainer, size: 20),
                      ),
                      title: Text(g.nombre),
                      subtitle: Text(g.categoria),
                      trailing: Text(
                        'S/ ${g.monto.toStringAsFixed(2)}',
                        style: tt.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  )),
            ],

            // --- Empty state ---
            if (_gastos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 80),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.analytics_outlined,
                          size: 64,
                          color: cs.onSurface.withValues(alpha:0.2)),
                      const SizedBox(height: 12),
                      Text('Aún no hay gastos registrados',
                          style: tt.bodySmall),
                      const SizedBox(height: 4),
                      Text('Agrega gastos para ver tus reportes',
                          style: tt.bodySmall),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ============ SUMMARY CARD ============
  Widget _buildSummaryCard(ColorScheme cs, TextTheme tt) {
    final porcentajeGastado =
        _ingresos > 0 ? (_totalGastos / _ingresos * 100) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen del mes', style: tt.headlineMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    label: 'Ingresos',
                    value: 'S/ ${_ingresos.toStringAsFixed(2)}',
                    color: cs.primary,
                    icon: Icons.arrow_downward,
                  ),
                ),
                Expanded(
                  child: _SummaryTile(
                    label: 'Gastos',
                    value: 'S/ ${_totalGastos.toStringAsFixed(2)}',
                    color: cs.error,
                    icon: Icons.arrow_upward,
                  ),
                ),
                Expanded(
                  child: _SummaryTile(
                    label: 'Disponible',
                    value: 'S/ ${_disponible.toStringAsFixed(2)}',
                    color: _disponible >= 0
                        ? cs.primary
                        : cs.error,
                    icon: Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _ingresos > 0
                    ? (_totalGastos / _ingresos).clamp(0.0, 1.0)
                    : 0,
                minHeight: 8,
                backgroundColor: cs.onSurface.withValues(alpha:0.1),
                valueColor: AlwaysStoppedAnimation(
                  porcentajeGastado > 80 ? cs.error : cs.primary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${porcentajeGastado.toStringAsFixed(1)}% del ingreso gastado',
              style: tt.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  // ============ DONUT CHART ============
  Widget _buildDonutChart(ColorScheme cs, TextTheme tt) {
    final categories = _gastosPorCategoria.entries.toList();
    final colors = [
      cs.primary,
      cs.error,
      const Color(0xFF6366F1),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: List.generate(categories.length, (i) {
                    final entry = categories[i];
                    final pct = _totalGastos > 0
                        ? (entry.value / _totalGastos * 100)
                        : 0.0;
                    return PieChartSectionData(
                      value: entry.value,
                      title: '${pct.toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      color: colors[i % colors.length],
                      radius: 32,
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: List.generate(categories.length, (i) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[i % colors.length],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${categories[i].key} (\$${categories[i].value.toStringAsFixed(0)})',
                      style: tt.bodySmall,
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ============ BAR CHART ============
  Widget _buildBarChart(ColorScheme cs, TextTheme tt) {
    final totalFijos =
        _gastosFijos.fold(0.0, (sum, g) => sum + g.monto);
    final totalVariables =
        _gastosVariables.fold(0.0, (sum, g) => sum + g.monto);
    final maxY = [_ingresos, totalFijos, totalVariables]
        .reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: maxY > 0 ? maxY * 1.2 : 100,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, gIdx, rod, rIdx) {
                    final labels = ['Ingresos', 'Fijos', 'Variables'];
                    return BarTooltipItem(
                      '${labels[group.x]}\n\$${rod.toY.toStringAsFixed(2)}',
                      const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      const labels = ['Ingresos', 'Fijos', 'Variables'];
                      final idx = val.toInt();
                      if (idx < 0 || idx >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(labels[idx],
                            style: const TextStyle(fontSize: 12)),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                BarChartGroupData(x: 0, barRods: [
                  BarChartRodData(
                    toY: _ingresos,
                    color: cs.primary,
                    width: 28,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ]),
                BarChartGroupData(x: 1, barRods: [
                  BarChartRodData(
                    toY: totalFijos,
                    color: const Color(0xFFF59E0B),
                    width: 28,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ]),
                BarChartGroupData(x: 2, barRods: [
                  BarChartRodData(
                    toY: totalVariables,
                    color: cs.error,
                    width: 28,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============ MINI WIDGET ============
class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
