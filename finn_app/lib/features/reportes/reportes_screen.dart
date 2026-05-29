import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/widgets/finanzas_card.dart';
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
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _gastos = gastos;
      _ingresos = income ?? 0;
      _loading = false;
    });
  }

  double get _totalGastos => _gastos.fold(0.0, (sum, g) => sum + g.monto);
  double get _disponible => _ingresos - _totalGastos;

  Map<String, double> get _gastosPorCategoria {
    final map = <String, double>{};
    for (final g in _gastos) {
      map[g.categoria] = (map[g.categoria] ?? 0) + g.monto;
    }
    return map;
  }

  List<Gasto> get _gastosFijos => _gastos.where((g) => g.esFijo).toList();
  List<Gasto> get _gastosVariables => _gastos.where((g) => !g.esFijo).toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_loading) {
      return Scaffold(
        appBar: const FinanzasTopAppBar(subtitle: 'Reportes'),
        body: Shimmer.fromColors(
          baseColor: Colors.white.withValues(alpha: 0.05),
          highlightColor: Colors.white.withValues(alpha: 0.12),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _shimmerBox(height: 160),
              const SizedBox(height: 20),
              _shimmerBox(height: 28, width: 180),
              const SizedBox(height: 12),
              _shimmerBox(height: 260),
              const SizedBox(height: 20),
              _shimmerBox(height: 28, width: 200),
              const SizedBox(height: 12),
              _shimmerBox(height: 220),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const FinanzasTopAppBar(subtitle: 'Reportes'),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            if (_gastos.isEmpty) ...[
              _buildEmptyState(cs, tt, context),
            ] else ...[
              _buildSummaryCard(cs, tt),
              const SizedBox(height: 20),

              if (_gastosPorCategoria.isNotEmpty) ...[
                _SectionLabel(label: 'Distribución por categoría', tt: tt),
                const SizedBox(height: 12),
                _buildDonutChart(cs, tt),
                const SizedBox(height: 24),
              ],

              _SectionLabel(label: 'Fijos vs Variables', tt: tt),
              const SizedBox(height: 12),
              _buildBarChart(cs, tt),
              const SizedBox(height: 24),

              if (_gastosFijos.isNotEmpty) ...[
                _SectionLabel(label: 'Gastos fijos registrados', tt: tt),
                const SizedBox(height: 12),
                ..._gastosFijos.map((g) => _GastoFijoTile(g: g, cs: cs, tt: tt)),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs, TextTheme tt, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.analytics_rounded, size: 72, color: cs.primary),
          ),
          const SizedBox(height: 28),
          Text(
            'Sin datos aún',
            style: tt.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Registra tus primeros gastos para ver tus reportes financieros.',
            style: tt.bodySmall?.copyWith(color: Colors.grey.shade500, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: 220,
            height: 52,
            child: FilledButton.icon(
              onPressed: () => context.push('/gastos/agregar'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Agregar gasto', style: TextStyle(fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ColorScheme cs, TextTheme tt) {
    final porcentajeGastado = _ingresos > 0 ? (_totalGastos / _ingresos * 100) : 0.0;
    final overBudget = porcentajeGastado > 100;
    final barColor = porcentajeGastado > 80 ? cs.error : cs.primary;

    return FinanzasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen del mes', style: tt.headlineMedium),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'Ingresos',
                  value: 'S/ ${_ingresos.toStringAsFixed(0)}',
                  color: cs.primary,
                  icon: Icons.south_west_rounded,
                ),
              ),
              Expanded(
                child: _SummaryTile(
                  label: 'Gastos',
                  value: 'S/ ${_totalGastos.toStringAsFixed(0)}',
                  color: cs.error,
                  icon: Icons.north_east_rounded,
                ),
              ),
              Expanded(
                child: _SummaryTile(
                  label: 'Libre',
                  value: 'S/ ${_disponible.toStringAsFixed(0)}',
                  color: _disponible >= 0 ? cs.primary : cs.error,
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: _ingresos > 0 ? (_totalGastos / _ingresos).clamp(0.0, 1.0) : 0,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                overBudget
                    ? 'Superaste tu presupuesto'
                    : '${porcentajeGastado.toStringAsFixed(1)}% del ingreso gastado',
                style: tt.bodySmall?.copyWith(
                  color: overBudget ? cs.error : Colors.grey,
                ),
              ),
              if (overBudget)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '¡Alerta!',
                    style: tt.labelSmall?.copyWith(color: cs.error, letterSpacing: 0.5),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(ColorScheme cs, TextTheme tt) {
    final categories = _gastosPorCategoria.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final colors = [
      cs.primary,
      cs.secondary,
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
      cs.error,
    ];

    return FinanzasCard(
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 52,
                sections: List.generate(categories.length, (i) {
                  final entry = categories[i];
                  final pct = _totalGastos > 0 ? (entry.value / _totalGastos * 100) : 0.0;
                  return PieChartSectionData(
                    value: entry.value,
                    title: '${pct.toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    color: colors[i % colors.length],
                    radius: 34,
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(categories.length, (i) {
              final pct = _totalGastos > 0
                  ? (categories[i].value / _totalGastos * 100).toStringAsFixed(0)
                  : '0';
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors[i % colors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${categories[i].key} ($pct%)',
                    style: tt.bodySmall?.copyWith(fontSize: 12),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(ColorScheme cs, TextTheme tt) {
    final totalFijos = _gastosFijos.fold(0.0, (sum, g) => sum + g.monto);
    final totalVariables = _gastosVariables.fold(0.0, (sum, g) => sum + g.monto);
    final maxY = [_ingresos, totalFijos, totalVariables].reduce((a, b) => a > b ? a : b);

    return FinanzasCard(
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            maxY: maxY > 0 ? maxY * 1.25 : 100,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => const Color(0xFF1E1E1E),
                tooltipRoundedRadius: 12,
                getTooltipItem: (group, gIdx, rod, rIdx) {
                  const labels = ['Ingresos', 'Fijos', 'Variables'];
                  return BarTooltipItem(
                    '${labels[group.x]}\nS/ ${rod.toY.toStringAsFixed(0)}',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, meta) {
                    const labels = ['Ingresos', 'Fijos', 'Variables'];
                    final idx = val.toInt();
                    if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(labels[idx],
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY > 0 ? maxY / 4 : 25,
              getDrawingHorizontalLine: (_) => FlLine(
                color: Colors.white.withValues(alpha: 0.05),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: [
              _barGroup(0, _ingresos, cs.primary),
              _barGroup(1, totalFijos, const Color(0xFFF59E0B)),
              _barGroup(2, totalVariables, cs.error),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y, Color color) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(
        toY: y,
        color: color,
        width: 32,
        borderRadius: BorderRadius.circular(8),
        backDrawRodData: BackgroundBarChartRodData(
          show: true,
          toY: 0,
          color: Colors.transparent,
        ),
      ),
    ]);
  }

  Widget _shimmerBox({required double height, double? width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final TextTheme tt;
  const _SectionLabel({required this.label, required this.tt});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: tt.headlineMedium);
  }
}

class _GastoFijoTile extends StatelessWidget {
  final Gasto g;
  final ColorScheme cs;
  final TextTheme tt;
  const _GastoFijoTile({required this.g, required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FinanzasCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.repeat_rounded, color: Color(0xFFF59E0B), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.nombre,
                      style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(g.categoria, style: tt.bodySmall),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'S/ ${g.monto.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _SummaryTile({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
