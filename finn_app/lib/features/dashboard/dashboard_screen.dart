import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/widgets/finanzas_card.dart';
import '../../core/widgets/finanzas_top_app_bar.dart';
import '../../shared/models/gasto.dart';
import '../../shared/models/ingreso_extra.dart';
import '../../shared/models/meta_ahorro.dart';
import '../../shared/services/database_helper.dart';
import '../../shared/services/user_preferences.dart';
import '../../shared/services/data_refresh_notifier.dart';
import '../../shared/services/notification_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _nombre = '';
  double _ingresos = 0;
  List<Gasto> _gastos = [];
  List<IngresoExtra> _ingresosExtras = [];
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
    final extras = await db.getIngresosExtras();
    final m = await db.getMetas();
    final t = await db.getTotalAportes();

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() {
      _nombre = n ?? '';
      _ingresos = i ?? 0;
      _gastos = g;
      _ingresosExtras = extras;
      _metas = m;
      _totalAhorros = t;
      _loading = false;
    });

    final notif = NotificationService();
    notif.checkMetasProximas();
    notif.checkAndNotifyGoogleAccount();
    notif.checkAndNotifyNoGastosThisMonth();
  }

  double get _totalGastos => _gastos.fold(0.0, (s, g) => s + g.monto);
  double get _totalIngresosExtras => _ingresosExtras.fold(0.0, (s, e) => s + e.monto);
  double get _disponible => _ingresos + _totalIngresosExtras - _totalGastos - _totalAhorros;

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
      return const _DashboardShimmer();
    }

    return Scaffold(
      appBar: FinanzasTopAppBar(
        subtitle: _mesActual,
        onAdd: () => ctx.push('/gastos/agregar'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              _nombre.isNotEmpty ? 'Hola, $_nombre 👋' : 'Hola 👋',
              style: tt.headlineLarge,
            ),
            const SizedBox(height: 4),
            Text('Tu balance fintech está actualizado', style: tt.bodySmall),
            const SizedBox(height: 20),

            _DisponibleCard(
              cs: cs,
              tt: tt,
              ingresos: _ingresos + _totalIngresosExtras,
              gastos: _totalGastos,
              disponible: _disponible,
              ahorros: _totalAhorros,
            ),
            const SizedBox(height: 16),

            if (_metas.isNotEmpty) ...[
              _AhorroCard(
                cs: cs,
                tt: tt,
                meta: _metas.first,
                totalAhorrado: _totalAhorros,
              ),
              const SizedBox(height: 16),
            ],

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
            const SizedBox(height: 16),

            _UltimasTransacciones(
                cs: cs, tt: tt, gastos: _gastos, extras: _ingresosExtras),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}

// --- SHIMMER LOADER SKELETON ---
class _DashboardShimmer extends StatelessWidget {
  const _DashboardShimmer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FinanzasTopAppBar(subtitle: 'Cargando...'),
      body: Shimmer.fromColors(
        baseColor: Colors.white.withValues(alpha: 0.05),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              height: 28,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 16,
              width: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
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

  String _fmt(double v) => 'S/ ${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.15),
            cs.secondary.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DISPONIBLE TOTAL',
                style: tt.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF00C896),
                  shape: BoxShape.circle,
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(_fmt(disponible),
              style: tt.displayMedium?.copyWith(color: Colors.white)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniStat(
                  label: 'Ingresos',
                  value: _fmt(ingresos),
                  icon: Icons.south_west,
                  color: cs.primary),
              _MiniStat(
                  label: 'Gastos',
                  value: _fmt(gastos),
                  icon: Icons.north_east,
                  color: cs.error),
              _MiniStat(
                  label: 'Ahorros',
                  value: _fmt(ahorros),
                  icon: Icons.savings_outlined,
                  color: cs.secondary),
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
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
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
            Icon(Icons.savings_outlined, color: cs.secondary, size: 20),
            const SizedBox(width: 8),
            Text('Meta de Ahorro', style: tt.headlineMedium),
          ]),
          Text('$pct%',
              style: tt.bodySmall?.copyWith(
                  color: cs.secondary, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
        Text(meta.nombre, style: tt.bodySmall),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progreso,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation(cs.secondary),
          ),
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('S/ ${totalAhorrado.toStringAsFixed(0)} ahorrados',
              style: tt.bodySmall),
          Text('Meta: S/ ${meta.montoObjetivo.toStringAsFixed(0)}',
              style: tt.bodySmall?.copyWith(color: Colors.grey)),
        ]),
        if (mesesRest > 0 && faltante > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, size: 14, color: cs.secondary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Ahorra S/ ${mensualSugerido.toStringAsFixed(0)}/mes para cumplir tu meta',
                  style: tt.bodySmall?.copyWith(color: cs.secondary),
                ),
              ),
            ]),
          ),
        ],
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
      cs.secondary,
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
    ];
    final entries = gastosPorCategoria.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(3).toList();

    return FinanzasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gastos', style: tt.headlineMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: top.isEmpty
                ? Center(
                    child: Text('Sin datos',
                        style: tt.bodySmall),
                  )
                : PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 24,
                      sections: List.generate(top.length, (i) {
                        return PieChartSectionData(
                          value: top[i].value,
                          color: colors[i % colors.length],
                          radius: 16,
                          showTitle: false,
                        );
                      }),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          ...List.generate(top.length, (i) {
            final pct =
                total > 0 ? (top[i].value / total * 100).toStringAsFixed(0) : '0';
            return _Leyenda(
              color: colors[i % colors.length],
              label: '${top[i].key} ($pct%)',
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
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
      (Icons.trending_up_rounded, 'Ingreso', '/ingresos/agregar'),
      (Icons.analytics, 'Reportes', '/reportes'),
      (Icons.auto_awesome, 'IA Tips', '/recomendaciones'),
      (Icons.notifications_active_rounded, 'Alertas', '/notificaciones'),
    ];
    return FinanzasCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Acciones', style: tt.headlineMedium),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.0,
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
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: cs.primary, size: 24),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: cs.primary,
                  fontWeight: FontWeight.bold)),
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
  final List<IngresoExtra> extras;
  const _UltimasTransacciones(
      {required this.cs, required this.tt, required this.gastos, required this.extras});

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
    // Combinar gastos e ingresos extras, ordenar por fecha desc, tomar 5
    final combined = [
      ...gastos.map((g) => (fecha: g.fecha, widget: _TransaccionTile(
            icon: _iconFor(g.categoria),
            nombre: g.nombre,
            categoria: g.categoria,
            monto: '-S/ ${g.monto.toStringAsFixed(2)}',
            montoColor: cs.error,
            cs: cs,
            tt: tt,
          ))),
      ...extras.map((e) => (fecha: e.fecha, widget: _TransaccionTile(
            icon: _iconForIngreso(e.categoria),
            nombre: e.descripcion,
            categoria: e.categoria,
            monto: '+S/ ${e.monto.toStringAsFixed(2)}',
            montoColor: cs.primary,
            cs: cs,
            tt: tt,
          ))),
    ]..sort((a, b) => b.fecha.compareTo(a.fecha));

    final ultimos = combined.take(5).map((e) => e.widget).toList();

    return FinanzasCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Transacciones', style: tt.headlineMedium),
          TextButton(
              onPressed: () => ctx.go('/gastos'),
              child: Text('Ver todo', style: TextStyle(color: cs.primary))),
        ]),
        const SizedBox(height: 4),
        if (ultimos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.payment, size: 40, color: Colors.white.withValues(alpha: 0.1)),
                  const SizedBox(height: 8),
                  Text('Aún no hay transacciones', style: tt.bodySmall),
                ],
              ),
            ),
          )
        else
          ...ultimos,
      ]),
    );
  }

  IconData _iconForIngreso(String categoria) {
    switch (categoria) {
      case 'Freelance': return Icons.computer_outlined;
      case 'Bonificación': return Icons.star_outline_rounded;
      case 'Regalo': return Icons.card_giftcard_outlined;
      case 'Venta': return Icons.storefront_outlined;
      case 'Devolución': return Icons.undo_rounded;
      case 'Inversión': return Icons.trending_up_rounded;
      default: return Icons.add_circle_outline;
    }
  }
}

class _TransaccionTile extends StatelessWidget {
  final IconData icon;
  final String nombre, categoria, monto;
  final Color montoColor;
  final ColorScheme cs;
  final TextTheme tt;
  const _TransaccionTile({
    required this.icon,
    required this.nombre,
    required this.categoria,
    required this.monto,
    required this.montoColor,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: montoColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: montoColor, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nombre,
                  style: tt.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(categoria, style: tt.bodySmall),
            ],
          ),
        ),
        Text(monto,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: montoColor,
            )),
      ]),
    );
  }
}
