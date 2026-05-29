import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/widgets/finanzas_card.dart';
import '../../core/widgets/finanzas_top_app_bar.dart';
import '../../shared/models/meta_ahorro.dart';
import '../../shared/models/aporte_ahorro.dart';
import '../../shared/services/database_helper.dart';
import '../../shared/services/data_refresh_notifier.dart';
import '../../shared/widgets/registrar_aporte_modal.dart';
import '../../shared/widgets/confirm_dialog.dart';

class AhorrosScreen extends StatefulWidget {
  const AhorrosScreen({super.key});

  @override
  State<AhorrosScreen> createState() => _AhorrosScreenState();
}

class _AhorrosScreenState extends State<AhorrosScreen> {
  List<MetaAhorro> _metas = [];
  Map<int, double> _totalesPorMeta = {};
  Map<int, List<AporteAhorro>> _aportesPorMeta = {};
  bool _loading = true;
  MetaAhorro? _metaActiva;

  @override
  void initState() {
    super.initState();
    _load();
    DataRefreshNotifier().addListener(_load);
  }

  @override
  void dispose() {
    DataRefreshNotifier().removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final db = DatabaseHelper();
    final metas = await db.getMetas();
    final totales = <int, double>{};
    final aportes = <int, List<AporteAhorro>>{};
    for (final m in metas) {
      if (m.id == null) continue;
      totales[m.id!] = await db.getTotalAportesByMeta(m.id!);
      aportes[m.id!] = await db.getAportesByMeta(m.id!);
    }
    
    // Simular un retraso corto para el shimmer elegante de Revolut
    await Future.delayed(const Duration(milliseconds: 450));

    if (!mounted) return;
    setState(() {
      _metas = metas;
      _totalesPorMeta = totales;
      _aportesPorMeta = aportes;
      _metaActiva = metas.isNotEmpty
          ? (_metaActiva != null
              ? metas.firstWhere(
                  (m) => m.id == _metaActiva!.id,
                  orElse: () => metas.first,
                )
              : metas.first)
          : null;
      _loading = false;
    });
  }

  Future<void> _registrarAporte(MetaAhorro meta) async {
    if (meta.id == null) return;
    final aporte = await showModalBottomSheet<AporteAhorro>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => RegistrarAporteModal(
        metaId: meta.id!,
        metaNombre: meta.nombre,
      ),
    );
    if (aporte == null) return;
    await DatabaseHelper().insertAporte(aporte);
    DataRefreshNotifier().refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aporte registrado')),
    );
  }

  Future<void> _eliminarMeta(MetaAhorro meta) async {
    if (meta.id == null) return;
    final ok = await showConfirmDialog(
      context,
      title: 'Eliminar meta',
      message:
          '¿Eliminar la meta "${meta.nombre}" y todos sus aportes? Esta acción no se puede deshacer.',
    );
    if (!ok) return;
    await DatabaseHelper().deleteMeta(meta.id!);
    DataRefreshNotifier().refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Meta eliminada')),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final tt = Theme.of(ctx).textTheme;

    if (_loading) {
      return Scaffold(
        appBar: const FinanzasTopAppBar(subtitle: 'Tus ahorros'),
        body: Shimmer.fromColors(
          baseColor: Colors.white.withValues(alpha: 0.05),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_metas.isEmpty) {
      return Scaffold(
        appBar: const FinanzasTopAppBar(subtitle: 'Tus ahorros'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.secondary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.savings_outlined,
                      size: 64, color: cs.secondary),
                ),
                const SizedBox(height: 24),
                Text('Aún no tienes metas de ahorro',
                    style: tt.headlineMedium, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('Empieza a guardar para tus proyectos, viajes o fondos de emergencia.',
                    style: tt.bodySmall?.copyWith(color: Colors.grey), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                SizedBox(
                  height: 50,
                  width: 220,
                  child: FilledButton.icon(
                    onPressed: () => ctx.push('/ahorros/nueva-meta'),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear Meta de Ahorro', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final meta = _metaActiva ?? _metas.first;
    final ahorrado = _totalesPorMeta[meta.id] ?? 0;
    final aportes = _aportesPorMeta[meta.id] ?? [];
    final progreso = meta.montoObjetivo > 0
        ? (ahorrado / meta.montoObjetivo).clamp(0.0, 1.0)
        : 0.0;
    final mesesRest = ((meta.fechaLimite.year - DateTime.now().year) * 12) +
        (meta.fechaLimite.month - DateTime.now().month);
    final faltante = (meta.montoObjetivo - ahorrado).clamp(0, double.infinity);
    final mensualSugerido = mesesRest > 0 ? faltante / mesesRest : faltante;

    return Scaffold(
      appBar: FinanzasTopAppBar(
        subtitle: 'Tus ahorros',
        onAdd: () => ctx.push('/ahorros/nueva-meta'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selector de meta si hay más de una
              if (_metas.length > 1)
                _SelectorMetas(
                  metas: _metas,
                  activa: meta,
                  totales: _totalesPorMeta,
                  onTap: (m) => setState(() => _metaActiva = m),
                  cs: cs,
                  tt: tt,
                ),
              if (_metas.length > 1) const SizedBox(height: 12),

              // Card meta activa
              FinanzasCard(
                color: cs.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('META ACTIVA',
                        style: tt.labelSmall?.copyWith(
                            color: Colors.white70, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(meta.nombre,
                        style: tt.headlineLarge?.copyWith(color: Colors.white)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('S/ ${ahorrado.toStringAsFixed(0)}',
                            style: tt.displayMedium
                                ?.copyWith(color: Colors.white, fontSize: 32)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('de S/ ${meta.montoObjetivo.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.white70)),
                            Text(
                              mesesRest > 0
                                  ? '$mesesRest meses restantes'
                                  : 'Plazo cumplido',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progreso,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor:
                            const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (mesesRest > 0 && faltante > 0)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(children: [
                          const Icon(Icons.lightbulb_outline,
                              color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ahorrar S/ ${mensualSugerido.toStringAsFixed(0)}/mes para llegar a tu meta',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ]),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Botones acción
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _registrarAporte(meta),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Registrar aporte'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _eliminarMeta(meta),
                    icon: Icon(Icons.delete_outline, size: 16, color: cs.error),
                    label: Text('Eliminar',
                        style: TextStyle(color: cs.error)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Gráfico evolución (basado en aportes acumulados)
              if (aportes.isNotEmpty)
                FinanzasCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Evolución del ahorro', style: tt.headlineMedium),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 150,
                        child: _buildEvolucionChart(aportes, cs),
                      ),
                    ],
                  ),
                ),
              if (aportes.isNotEmpty) const SizedBox(height: 12),

              // Historial aportes
              Text('Historial de aportes', style: tt.headlineMedium),
              const SizedBox(height: 8),
              if (aportes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('Sin aportes aún', style: tt.bodySmall),
                  ),
                )
              else
                ...aportes.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FinanzasCard(
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.savings,
                              color: cs.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('MMMM yyyy', 'es')
                                    .format(a.fecha),
                                style: tt.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                              Text(DateFormat('dd/MM/yyyy').format(a.fecha),
                                  style: tt.bodySmall),
                            ],
                          ),
                        ),
                        Text(
                          'S/ ${a.monto.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: cs.primary),
                        ),
                      ]),
                    ),
                  ),
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEvolucionChart(List<AporteAhorro> aportes, ColorScheme cs) {
    // Ordenar por fecha ascendente para construir acumulado
    final ordenados = [...aportes]..sort((a, b) => a.fecha.compareTo(b.fecha));
    final spots = <FlSpot>[];
    final fechas = <int, String>{};

    // Siempre empezar desde 0 para que se vea la línea de evolución
    spots.add(const FlSpot(0, 0));
    fechas[0] = 'Inicio';

    double acumulado = 0;
    for (var i = 0; i < ordenados.length; i++) {
      acumulado += ordenados[i].monto;
      final idx = i + 1; // offset por el punto inicial
      spots.add(FlSpot(idx.toDouble(), acumulado));
      fechas[idx] = DateFormat('dd/MM').format(ordenados[i].fecha);
    }

    // Si la meta activa tiene objetivo, agregar línea de referencia
    final meta = _metaActiva ?? (_metas.isNotEmpty ? _metas.first : null);
    final maxY = meta != null && meta.montoObjetivo > acumulado
        ? meta.montoObjetivo * 1.1
        : acumulado * 1.2;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY > 0 ? maxY : 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? maxY / 4 : 25,
          getDrawingHorizontalLine: (value) => FlLine(
            color: cs.onSurface.withValues(alpha: 0.08),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (!fechas.containsKey(idx)) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    fechas[idx]!,
                    style: TextStyle(
                      fontSize: 10,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        extraLinesData: meta != null
            ? ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: meta.montoObjetivo,
                    color: cs.primary.withValues(alpha: 0.3),
                    strokeWidth: 1.5,
                    dashArray: [6, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.primary.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                      labelResolver: (_) =>
                          'Meta: S/ ${meta.montoObjetivo.toStringAsFixed(0)}',
                    ),
                  ),
                ],
              )
            : null,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  'S/ ${spot.y.toStringAsFixed(2)}',
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: cs.primary,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, barData, idx) {
                return FlDotCirclePainter(
                  radius: idx == 0 ? 0 : 4,
                  color: cs.primary,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  cs.primary.withValues(alpha: 0.25),
                  cs.primary.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorMetas extends StatelessWidget {
  final List<MetaAhorro> metas;
  final MetaAhorro activa;
  final Map<int, double> totales;
  final ValueChanged<MetaAhorro> onTap;
  final ColorScheme cs;
  final TextTheme tt;
  const _SelectorMetas({
    required this.metas,
    required this.activa,
    required this.totales,
    required this.onTap,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: metas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final m = metas[i];
          final isActive = m.id == activa.id;
          final total = totales[m.id] ?? 0;
          final pct = m.montoObjetivo > 0
              ? (total / m.montoObjetivo * 100).toStringAsFixed(0)
              : '0';
          return GestureDetector(
            onTap: () => onTap(m),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? cs.primary
                    : cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.nombre,
                      style: TextStyle(
                          color: isActive ? Colors.white : cs.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  Text('$pct% completado',
                      style: TextStyle(
                          color:
                              isActive ? Colors.white70 : cs.onSurfaceVariant,
                          fontSize: 11)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
