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
import '../../core/services/sync_service.dart';

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
      backgroundColor: const Color(0xFF15181C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (_) => RegistrarAporteModal(
        metaId: meta.id!,
        metaNombre: meta.nombre,
      ),
    );

    if (aporte == null) return;

    await DatabaseHelper().insertAporte(aporte);
    DataRefreshNotifier().refresh();
    SyncService().syncAportesAsync();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1C1F24),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: const Text('Aporte registrado'),
      ),
    );
  }

  Future<void> _eliminarMeta(MetaAhorro meta) async {
    if (meta.id == null) return;

    final ok = await showConfirmDialog(
      context,
      title: 'Eliminar meta',
      message:
          '¿Eliminar la meta "${meta.nombre}" y todos sus aportes?',
    );

    if (!ok) return;

    await DatabaseHelper().deleteMeta(meta.id!);
    DataRefreshNotifier().refresh();
    SyncService().syncMetasAsync();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1C1F24),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: const Text('Meta eliminada'),
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final tt = Theme.of(ctx).textTheme;

    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F1115),
        appBar: const FinanzasTopAppBar(
          subtitle: 'Tus ahorros',
        ),
        body: Shimmer.fromColors(
          baseColor: Colors.white.withValues(alpha: 0.04),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_metas.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F1115),
        appBar: const FinanzasTopAppBar(
          subtitle: 'Tus ahorros',
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.savings_rounded,
                    size: 68,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Aún no tienes metas de ahorro',
                  style: tt.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Empieza a construir tus metas financieras y sigue tu progreso mes a mes.',
                  style: tt.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 34),
                SizedBox(
                  width: 240,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: () => ctx.push('/ahorros/nueva-meta'),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text(
                      'Crear Meta',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
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

    final mesesRest =
        ((meta.fechaLimite.year - DateTime.now().year) * 12) +
            (meta.fechaLimite.month - DateTime.now().month);

    final faltante =
        (meta.montoObjetivo - ahorrado).clamp(0, double.infinity);

    final mensualSugerido =
        mesesRest > 0 ? faltante / mesesRest : faltante;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
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

              if (_metas.length > 1)
                _SelectorMetas(
                  metas: _metas,
                  activa: meta,
                  totales: _totalesPorMeta,
                  onTap: (m) => setState(() => _metaActiva = m),
                  cs: cs,
                  tt: tt,
                ),

              if (_metas.length > 1)
                const SizedBox(height: 14),

              // CARD PRINCIPAL
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF00C896),
                      Color(0xFF00B383),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C896)
                          .withValues(alpha: 0.18),
                      blurRadius: 28,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: FinanzasCard(
                  color: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        'META ACTIVA',
                        style: tt.labelSmall?.copyWith(
                          color: Colors.white70,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        meta.nombre,
                        style: tt.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 22),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                          Text(
                            'S/ ${ahorrado.toStringAsFixed(0)}',
                            style: tt.displayMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 38,
                            ),
                          ),

                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [

                              Text(
                                'de S/ ${meta.montoObjetivo.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withValues(alpha: 0.12),
                                  borderRadius:
                                      BorderRadius.circular(99),
                                ),
                                child: Text(
                                  mesesRest > 0
                                      ? '⏳ $mesesRest meses'
                                      : '🎯 Completado',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progreso,
                          minHeight: 10,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.2),
                          valueColor:
                              const AlwaysStoppedAnimation(
                            Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      if (mesesRest > 0 && faltante > 0)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color:
                                Colors.white.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [

                              const Icon(
                                Icons.lightbulb_outline_rounded,
                                color: Colors.white70,
                                size: 18,
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: Text(
                                  'Ahorra S/ ${mensualSugerido.toStringAsFixed(0)}/mes para completar tu meta',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // BOTONES
              Row(
                children: [

                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: () =>
                            _registrarAporte(meta),
                        icon: const Icon(
                          Icons.add_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Registrar aporte',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          elevation: 0,
                          backgroundColor: cs.primary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Container(
                    decoration: BoxDecoration(
                      color:
                          Colors.white.withValues(alpha: 0.04),
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_horiz_rounded,
                        color: cs.onSurface
                            .withValues(alpha: 0.8),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      color: const Color(0xFF1A1C20),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _eliminarMeta(meta);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: cs.error,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Eliminar meta',
                                style: TextStyle(
                                  color: cs.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // CHART
              if (aportes.isNotEmpty)
                FinanzasCard(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      Text(
                        'Evolución del ahorro',
                        style: tt.headlineMedium,
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        height: 170,
                        child: _buildEvolucionChart(
                          aportes,
                          cs,
                        ),
                      ),
                    ],
                  ),
                ),

              if (aportes.isNotEmpty)
                const SizedBox(height: 18),

              Text(
                'Historial de aportes',
                style: tt.headlineMedium,
              ),

              const SizedBox(height: 12),

              if (aportes.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text(
                      'Aún no registras aportes',
                      style: tt.bodySmall,
                    ),
                  ),
                )
              else
                ...aportes.map(
                  (a) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: 10),
                    child: FinanzasCard(
                      child: Row(
                        children: [

                          Container(
                            padding:
                                const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cs.primary
                                  .withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.savings_rounded,
                              color: cs.primary,
                              size: 20,
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [

                                Text(
                                  DateFormat(
                                    'MMMM yyyy',
                                    'es',
                                  ).format(a.fecha),
                                  style: tt.bodyLarge
                                      ?.copyWith(
                                    fontWeight:
                                        FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),

                                const SizedBox(height: 2),

                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(a.fecha),
                                  style: tt.bodySmall
                                      ?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Text(
                            'S/ ${a.monto.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 130),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEvolucionChart(
    List<AporteAhorro> aportes,
    ColorScheme cs,
  ) {
    final ordenados = [...aportes]
      ..sort((a, b) => a.fecha.compareTo(b.fecha));

    final spots = <FlSpot>[];
    final fechas = <int, String>{};

    spots.add(const FlSpot(0, 0));
    fechas[0] = 'Inicio';

    double acumulado = 0;

    for (var i = 0; i < ordenados.length; i++) {
      acumulado += ordenados[i].monto;

      final idx = i + 1;

      spots.add(
        FlSpot(idx.toDouble(), acumulado),
      );

      fechas[idx] = DateFormat(
        'dd/MM',
      ).format(ordenados[i].fecha);
    }

    final meta =
        _metaActiva ?? (_metas.isNotEmpty ? _metas.first : null);

    final maxY = meta != null &&
            meta.montoObjetivo > acumulado
        ? meta.montoObjetivo * 1.1
        : acumulado * 1.2;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY > 0 ? maxY : 100,

        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval:
              maxY > 0 ? maxY / 4 : 25,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color:
                  cs.onSurface.withValues(alpha: 0.08),
              strokeWidth: 1,
            );
          },
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
                  padding:
                      const EdgeInsets.only(top: 6),
                  child: Text(
                    fechas[idx]!,
                    style: TextStyle(
                      fontSize: 10,
                      color: cs.onSurface
                          .withValues(alpha: 0.5),
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
                    color: cs.primary
                        .withValues(alpha: 0.3),
                    strokeWidth: 1.5,
                    dashArray: [6, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.primary
                            .withValues(alpha: 0.6),
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
            tooltipRoundedRadius: 14,
            tooltipPadding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            getTooltipItems: (spots) {
              return spots.map((spot) {
                return LineTooltipItem(
                  'S/ ${spot.y.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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
            barWidth: 4,

            dotData: FlDotData(
              show: true,
              getDotPainter:
                  (spot, pct, barData, idx) {
                return FlDotCirclePainter(
                  radius: idx == 0 ? 0 : 4.5,
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
                  cs.primary
                      .withValues(alpha: 0.28),
                  cs.primary
                      .withValues(alpha: 0.02),
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
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: metas.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final m = metas[i];

          final isActive = m.id == activa.id;

          final total = totales[m.id] ?? 0;

          final pct = m.montoObjetivo > 0
              ? (total / m.montoObjetivo * 100)
                  .toStringAsFixed(0)
              : '0';

          return GestureDetector(
            onTap: () => onTap(m),
            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: 250,
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? cs.primary
                    : Colors.white.withValues(
                        alpha: 0.04,
                      ),
                borderRadius:
                    BorderRadius.circular(16),
                border: Border.all(
                  color: isActive
                      ? Colors.transparent
                      : Colors.white.withValues(
                          alpha: 0.05,
                        ),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [

                  Text(
                    m.nombre,
                    style: TextStyle(
                      color: isActive
                          ? Colors.black
                          : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    '$pct% completado',
                    style: TextStyle(
                      color: isActive
                          ? Colors.black87
                          : Colors.grey.shade500,
                      fontSize: 11,
                    ),
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