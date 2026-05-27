import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/finanzas_card.dart';
import '../../core/widgets/finanzas_top_app_bar.dart';
import '../../shared/models/gasto.dart';
import '../../shared/models/meta_ahorro.dart';
import '../../shared/services/database_helper.dart';
import '../../shared/services/user_preferences.dart';
import '../../shared/services/data_refresh_notifier.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _nombre = '';
  double _ingresos = 0;
  List<Gasto> _gastos = [];
  List<MetaAhorro> _metas = [];
  double _totalAhorros = 0;
  bool _loading = true;

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
    final prefs = UserPreferences();
    final db = DatabaseHelper();
    final n = await prefs.getUserName();
    final i = await prefs.getUserIncome();
    final g = await db.getGastos();
    final m = await db.getMetas();
    final t = await db.getTotalAportes();
    if (!mounted) return;
    setState(() {
      _nombre = n ?? '';
      _ingresos = i ?? 0;
      _gastos = g;
      _metas = m;
      _totalAhorros = t;
      _loading = false;
    });
  }

  double get _totalGastos => _gastos.fold(0.0, (s, g) => s + g.monto);
  double get _disponible => _ingresos - _totalGastos;

  Map<String, double> get _gastosPorCategoria {
    final map = <String, double>{};
    for (final g in _gastos) {
      map[g.categoria] = (map[g.categoria] ?? 0) + g.monto;
    }
    return map;
  }

  String get _mesActual {
    final now = DateTime.now();
    return DateFormat('MMMM yyyy', 'es').format(now);
  }

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final tt = Theme.of(ctx).textTheme;

    if (_loading) {
      return Scaffold(
        appBar: FinanzasTopAppBar(subtitle: _mesActual),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: FinanzasTopAppBar(subtitle: _mesActual),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              _nombre.isNotEmpty ? 'Hola, $_nombre 👋' : 'Hola 👋',
              style: tt.headlineLarge,
            ),
            Text('Aquí está tu resumen del mes', style: tt.bodySmall),
            const SizedBox(height: 16),

            _DisponibleCard(
              cs: cs,
              tt: tt,
              ingresos: _ingresos,
              gastos: _totalGastos,
              disponible: _disponible,
              ahorros: _totalAhorros,
            ),
            const SizedBox(height: 12),

            if (_metas.isNotEmpty)
              _AhorroCard(
                cs: cs,
                tt: tt,
                meta: _metas.first,
                totalAhorrado: _totalAhorros,
              ),
            if (_metas.isNotEmpty) const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _DonutCard(
                    cs: cs,
                    tt: tt,
                    gastosPorCategoria: _gastosPorCategoria,
                    total: _totalGastos,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _AccionesRapidasCard(cs: cs, tt: tt, ctx: ctx)),
              ],
            ),
            const SizedBox(height: 12),

            _UltimasTransacciones(cs: cs, tt: tt, gastos: _gastos),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ── Disponible ──────────────────────────────────────────────────────────────
class _DisponibleCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final double ingresos, gastos, disponible, ahorros;
  const _DisponibleCard({
    required this.cs,
    required this.tt,
    required this.ingresos,
    required this.gastos,
    required this.disponible,
    required this.ahorros,
  });

  String _fmt(double v) => 'S/ ${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext ctx) {
    return FinanzasCard(
      color: cs.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DISPONIBLE TOTAL',
            style: tt.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(_fmt(disponible),
              style: tt.displayMedium?.copyWith(color: Colors.white)),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat(
                  label: 'Ingresos',
                  value: _fmt(ingresos),
                  icon: Icons.arrow_downward,
                  color: const Color(0xFF10B981)),
              const SizedBox(width: 24),
              _MiniStat(
                  label: 'Gastos',
                  value: _fmt(gastos),
                  icon: Icons.arrow_upward,
                  color: Colors.redAccent),
              const SizedBox(width: 24),
              _MiniStat(
                  label: 'Ahorro',
                  value: _fmt(ahorros),
                  icon: Icons.savings_outlined,
                  color: Colors.white70),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        Text(value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }
}

// ── Ahorro ──────────────────────────────────────────────────────────────────
class _AhorroCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final MetaAhorro meta;
  final double totalAhorrado;
  const _AhorroCard({
    required this.cs,
    required this.tt,
    required this.meta,
    required this.totalAhorrado,
  });

  @override
  Widget build(BuildContext ctx) {
    final progreso = meta.montoObjetivo > 0
        ? (totalAhorrado / meta.montoObjetivo).clamp(0.0, 1.0)
        : 0.0;
    final pct = (progreso * 100).toStringAsFixed(0);
    final faltante = (meta.montoObjetivo - totalAhorrado).clamp(0, double.infinity);
    final mesesRest = ((meta.fechaLimite.year - DateTime.now().year) * 12) +
        (meta.fechaLimite.month - DateTime.now().month);
    final mensualSugerido =
        mesesRest > 0 ? faltante / mesesRest : faltante.toDouble();

    return FinanzasCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(Icons.savings, color: cs.primary, size: 18),
            const SizedBox(width: 8),
            Text('Meta de Ahorro', style: tt.headlineMedium),
          ]),
          Text('$pct%',
              style: tt.bodySmall?.copyWith(
                  color: cs.primary, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        Text(meta.nombre, style: tt.bodySmall),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progreso,
            minHeight: 10,
            backgroundColor: cs.primaryContainer.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(cs.primary),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('S/ ${totalAhorrado.toStringAsFixed(0)} ahorrados',
              style: tt.bodySmall),
          Text('Meta: S/ ${meta.montoObjetivo.toStringAsFixed(0)}',
              style: tt.bodySmall),
        ]),
        const SizedBox(height: 8),
        if (mesesRest > 0 && faltante > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, size: 14, color: cs.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Ahorrar S/ ${mensualSugerido.toStringAsFixed(0)} este mes para cumplir tu meta',
                  style: tt.bodySmall?.copyWith(color: cs.primary),
                ),
              ),
            ]),
          ),
      ]),
    );
  }
}

// ── Donut ──────────────────────────────────────────────────────────────────
class _DonutCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final Map<String, double> gastosPorCategoria;
  final double total;
  const _DonutCard({
    required this.cs,
    required this.tt,
    required this.gastosPorCategoria,
    required this.total,
  });

  @override
  Widget build(BuildContext ctx) {
    final colors = [
      cs.primary,
      cs.primaryContainer,
      cs.secondary,
      cs.secondary.withValues(alpha: 0.4),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
    ];
    final entries = gastosPorCategoria.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(4).toList();

    return FinanzasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gastos', style: tt.headlineMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: top.isEmpty
                ? Center(
                    child: Text('Sin datos',
                        style: tt.bodySmall),
                  )
                : PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: List.generate(top.length, (i) {
                        return PieChartSectionData(
                          value: top[i].value,
                          color: colors[i % colors.length],
                          radius: 20,
                          showTitle: false,
                        );
                      }),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          ...List.generate(top.length, (i) {
            final pct =
                total > 0 ? (top[i].value / total * 100).toStringAsFixed(0) : '0';
            return _Leyenda(
              color: colors[i % colors.length],
              label: '${top[i].key} $pct%',
            );
          }),
        ],
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  final Color color;
  final String label;
  const _Leyenda({required this.color, required this.label});

  @override
  Widget build(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),
      ]),
    );
  }
}

// ── Acciones ───────────────────────────────────────────────────────────────
class _AccionesRapidasCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final BuildContext ctx;
  const _AccionesRapidasCard(
      {required this.cs, required this.tt, required this.ctx});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.add_card, 'Gasto', '/gastos/agregar'),
      (Icons.savings, 'Ahorro', '/ahorros/nueva-meta'),
      (Icons.analytics, 'Reportes', '/reportes'),
      (Icons.auto_awesome, 'IA Tips', '/recomendaciones'),
    ];
    return FinanzasCard(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Acciones', style: tt.headlineMedium),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1,
          children: items
              .map((e) => _AccionItem(
                    icon: e.$1,
                    label: e.$2,
                    onTap: () => ctx.push(e.$3),
                    cs: cs,
                  ))
              .toList(),
        ),
      ]),
    );
  }
}

class _AccionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme cs;
  const _AccionItem(
      {required this.icon,
      required this.label,
      required this.onTap,
      required this.cs});

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: cs.primary, size: 22),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: cs.primary,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ── Últimas Transacciones ──────────────────────────────────────────────────
class _UltimasTransacciones extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final List<Gasto> gastos;
  const _UltimasTransacciones(
      {required this.cs, required this.tt, required this.gastos});

  IconData _iconFor(String categoria) {
    switch (categoria) {
      case 'Vivienda':
        return Icons.home_outlined;
      case 'Alimentación':
        return Icons.restaurant_outlined;
      case 'Servicios':
        return Icons.wifi_outlined;
      case 'Transporte':
        return Icons.directions_car_outlined;
      case 'Entretenimiento':
        return Icons.movie_outlined;
      case 'Suscripciones':
        return Icons.subscriptions_outlined;
      case 'Salud':
        return Icons.health_and_safety_outlined;
      case 'Educación':
        return Icons.school_outlined;
      case 'Ropa':
        return Icons.checkroom_outlined;
      default:
        return Icons.payments_outlined;
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final ultimos = gastos.take(5).toList();
    return FinanzasCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Últimas transacciones', style: tt.headlineMedium),
          TextButton(
              onPressed: () => ctx.go('/gastos'),
              child: Text('Ver todo', style: TextStyle(color: cs.primary))),
        ]),
        if (ultimos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('Aún no hay transacciones',
                  style: tt.bodySmall),
            ),
          )
        else
          ...ultimos.map((g) => _TransaccionTile(
                icon: _iconFor(g.categoria),
                nombre: g.nombre,
                categoria: g.categoria,
                monto: '-S/ ${g.monto.toStringAsFixed(0)}',
                cs: cs,
                tt: tt,
              )),
      ]),
    );
  }
}

class _TransaccionTile extends StatelessWidget {
  final IconData icon;
  final String nombre, categoria, monto;
  final ColorScheme cs;
  final TextTheme tt;
  const _TransaccionTile({
    required this.icon,
    required this.nombre,
    required this.categoria,
    required this.monto,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: cs.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nombre,
                  style: tt.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w500, fontSize: 14)),
              Text(categoria, style: tt.bodySmall),
            ],
          ),
        ),
        Text(monto,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.error,
            )),
      ]),
    );
  }
}
