import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/finanzas_card.dart';
import '../../core/widgets/finanzas_top_app_bar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final tt = Theme.of(ctx).textTheme;

    return Scaffold(
      appBar: const FinanzasTopAppBar(subtitle: 'Junio 2026'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saludo
            Text('Hola 👋', style: tt.headlineLarge),
            Text('Aquí está tu resumen de Junio', style: tt.bodySmall),
            const SizedBox(height: 16),

            // Tarjeta disponible total
            _DisponibleCard(cs: cs, tt: tt),
            const SizedBox(height: 12),

            // Tarjeta ahorro
            _AhorroCard(cs: cs, tt: tt),
            const SizedBox(height: 12),

            // Gráfico donuts + accesos rápidos
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _DonutCard(cs: cs, tt: tt)),
                const SizedBox(width: 12),
                Expanded(child: _AccionesRapidasCard(cs: cs, tt: tt, ctx: ctx)),
              ],
            ),
            const SizedBox(height: 12),

            // Últimas transacciones
            _UltimasTransacciones(cs: cs, tt: tt),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta Disponible ──────────────────────────────────────────
class _DisponibleCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  const _DisponibleCard({required this.cs, required this.tt});

  @override
  Widget build(BuildContext ctx) {
    return FinanzasCard(
      color: cs.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DISPONIBLE TOTAL',
              style: tt.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 1)),
          const SizedBox(height: 4),
          Text('S/ 2,371',
              style: tt.displayMedium?.copyWith(color: Colors.white)),
          const SizedBox(height: 16),
          const Row(children: [
            _MiniStat(label: 'Ingresos', value: 'S/ 5,500',
                icon: Icons.arrow_downward, color: Color(0xFF10B981)),
            SizedBox(width: 24),
            _MiniStat(label: 'Gastos', value: 'S/ 1,700',
                icon: Icons.arrow_upward, color: Colors.redAccent),
            SizedBox(width: 24),
            _MiniStat(label: 'Ahorro', value: 'S/ 1,429',
                icon: Icons.savings_outlined, color: Colors.white70),
          ]),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MiniStat({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext ctx) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ]),
      Text(value,
          style: const TextStyle(fontSize: 14,
              fontWeight: FontWeight.w600, color: Colors.white)),
    ]);
  }
}

// ── Tarjeta Ahorro ───────────────────────────────────────────────
class _AhorroCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  const _AhorroCard({required this.cs, required this.tt});

  @override
  Widget build(BuildContext ctx) {
    const progreso = 0.1429;
    return FinanzasCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(Icons.savings, color: cs.primary, size: 18),
            const SizedBox(width: 8),
            Text('Meta de Ahorro', style: tt.headlineMedium),
          ]),
          Text('14%',
              style: tt.bodySmall?.copyWith(
                  color: cs.primary, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        Text('Fondo fin de año', style: tt.bodySmall),
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
          Text('S/ 1,429 ahorrados', style: tt.bodySmall),
          Text('Meta: S/ 10,000', style: tt.bodySmall),
        ]),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Icon(Icons.info_outline, size: 14, color: cs.primary),
            const SizedBox(width: 6),
            Flexible(child: Text('Ahorrar S/ 1,429 este mes para cumplir tu meta',
                style: tt.bodySmall?.copyWith(color: cs.primary))),
          ]),
        ),
      ]),
    );
  }
}

// ── Gráfico Donut ────────────────────────────────────────────────
class _DonutCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  const _DonutCard({required this.cs, required this.tt});

  @override
  Widget build(BuildContext ctx) {
    return FinanzasCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Gastos', style: tt.headlineMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: PieChart(PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 30,
            sections: [
              PieChartSectionData(value: 44, color: cs.primary,
                  radius: 20, showTitle: false),
              PieChartSectionData(value: 23, color: cs.primaryContainer,
                  radius: 20, showTitle: false),
              PieChartSectionData(value: 18, color: cs.secondary,
                  radius: 20, showTitle: false),
              PieChartSectionData(value: 15,
                  color: cs.secondary.withValues(alpha: 0.4),
                  radius: 20, showTitle: false),
            ],
          )),
        ),
        const SizedBox(height: 8),
        _Leyenda(color: cs.primary,            label: 'Vivienda  44%'),
        _Leyenda(color: cs.primaryContainer,   label: 'Aliment. 23%'),
        _Leyenda(color: cs.secondary,          label: 'Servicios 18%'),
        _Leyenda(color: cs.secondary.withValues(alpha: 0.4), label: 'Otros 15%'),
      ]),
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
        Container(width: 8, height: 8,
            decoration: BoxDecoration(color: color,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ]),
    );
  }
}

// ── Acciones Rápidas ─────────────────────────────────────────────
class _AccionesRapidasCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final BuildContext ctx;
  const _AccionesRapidasCard(
      {required this.cs, required this.tt, required this.ctx});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.add_card,       'Gasto',       '/gastos/agregar'),
      (Icons.savings,        'Ahorro',      '/ahorros/nueva-meta'),
      (Icons.analytics,      'Reportes',    '/reportes'),
      (Icons.auto_awesome,   'IA Tips',     '/recomendaciones'),
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
          children: items.map((e) => _AccionItem(
            icon: e.$1, label: e.$2,
            onTap: () => ctx.push(e.$3), cs: cs,
          )).toList(),
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
  const _AccionItem({required this.icon, required this.label,
      required this.onTap, required this.cs});

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
              style: TextStyle(fontSize: 11, color: cs.primary,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ── Últimas Transacciones ────────────────────────────────────────
class _UltimasTransacciones extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  const _UltimasTransacciones({required this.cs, required this.tt});

  @override
  Widget build(BuildContext ctx) {
    final items = [
      (Icons.home_outlined,        'Alquiler',      'Vivienda', '-S/ 1,500', false),
      (Icons.restaurant_outlined,  'Mercado',        'Alimentación', '-S/ 230', false),
      (Icons.wifi_outlined,        'Internet',       'Servicios', '-S/ 120', false),
      (Icons.arrow_downward,       'Sueldo Junio',   'Ingreso', '+S/ 5,500', true),
    ];
    return FinanzasCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Últimas transacciones', style: tt.headlineMedium),
          TextButton(onPressed: () => ctx.go('/gastos'),
              child: Text('Ver todo', style: TextStyle(color: cs.primary))),
        ]),
        ...items.map((e) => _TransaccionTile(
          icon: e.$1, nombre: e.$2, categoria: e.$3,
          monto: e.$4, esIngreso: e.$5, cs: cs, tt: tt,
        )),
      ]),
    );
  }
}

class _TransaccionTile extends StatelessWidget {
  final IconData icon;
  final String nombre, categoria, monto;
  final bool esIngreso;
  final ColorScheme cs;
  final TextTheme tt;
  const _TransaccionTile({required this.icon, required this.nombre,
      required this.categoria, required this.monto, required this.esIngreso,
      required this.cs, required this.tt});

  @override
  Widget build(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (esIngreso ? cs.primaryContainer : cs.primary)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              color: esIngreso ? cs.primaryContainer : cs.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nombre, style: tt.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500, fontSize: 14)),
            Text(categoria, style: tt.bodySmall),
          ],
        )),
        Text(monto, style: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: esIngreso ? cs.primaryContainer : cs.error,
        )),
      ]),
    );
  }
}
