import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/widgets/finanzas_card.dart';
import '../../core/widgets/finanzas_top_app_bar.dart';

class AhorrosScreen extends StatelessWidget {
  const AhorrosScreen({super.key});

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final tt = Theme.of(ctx).textTheme;
    const progreso = 0.1429;

    return Scaffold(
      appBar: const FinanzasTopAppBar(subtitle: 'Tus ahorros'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Meta activa
          FinanzasCard(
            color: cs.primary,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('META ACTIVA', style: tt.labelSmall?.copyWith(
                  color: Colors.white70, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text('Fondo fin de año', style: tt.headlineLarge?.copyWith(
                  color: Colors.white)),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('S/ 1,429', style: tt.displayMedium?.copyWith(
                    color: Colors.white, fontSize: 32)),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('de S/ 10,000',
                      style: const TextStyle(color: Colors.white70)),
                  Text('6 meses restantes',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ]),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progreso, minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(height: 8),
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
                  Text('Ahorrar S/ 1,429/mes para llegar a tu meta',
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // Botones acción
          Row(children: [
            Expanded(child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Registrar aporte'),
            )),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Editar'),
            ),
          ]),
          const SizedBox(height: 16),

          // Gráfico evolución
          FinanzasCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Evolución del ahorro', style: tt.headlineMedium),
              const SizedBox(height: 16),
              SizedBox(
                height: 150,
                child: LineChart(LineChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          const m = ['Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
                          final i = v.toInt();
                          return i >= 0 && i < m.length
                              ? Text(m[i], style: const TextStyle(fontSize: 10))
                              : const SizedBox();
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 1429), FlSpot(1, 2858), FlSpot(2, 4287),
                        FlSpot(3, 5716), FlSpot(4, 7145), FlSpot(5, 8574),
                        FlSpot(6, 10000),
                      ],
                      isCurved: true,
                      color: cs.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: cs.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                )),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // Historial aportes
          Text('Historial de aportes', style: tt.headlineMedium),
          const SizedBox(height: 8),
          ...[
            ('Junio 2026', 'S/ 1,429', '01/06/2026'),
          ].map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FinanzasCard(
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.savings, color: cs.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.$1, style: tt.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500, fontSize: 14)),
                    Text(a.$3, style: tt.bodySmall),
                  ],
                )),
                Text(a.$2, style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: cs.primary)),
              ]),
            ),
          )),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}
