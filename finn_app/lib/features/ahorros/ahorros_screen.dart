import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
      return const Scaffold(
        appBar: FinanzasTopAppBar(subtitle: 'Tus ahorros'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_metas.isEmpty) {
      return Scaffold(
        appBar: const FinanzasTopAppBar(subtitle: 'Tus ahorros'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.savings_outlined,
                    size: 80, color: cs.onSurface.withValues(alpha: 0.25)),
                const SizedBox(height: 16),
                Text('Aún no tienes metas',
                    style: tt.headlineMedium, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('Define tu primera meta de ahorro para comenzar',
                    style: tt.bodySmall, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => ctx.push('/ahorros/nueva-meta'),
                  icon: const Icon(Icons.add),
                  label: const Text('Crear meta'),
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
      appBar: const FinanzasTopAppBar(subtitle: 'Tus ahorros'),
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
    double acumulado = 0;
    for (var i = 0; i < ordenados.length; i++) {
      acumulado += ordenados[i].monto;
      spots.add(FlSpot(i.toDouble(), acumulado));
    }
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: cs.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: cs.primary.withValues(alpha: 0.1),
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
