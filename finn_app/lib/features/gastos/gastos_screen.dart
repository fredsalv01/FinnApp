import 'package:flutter/material.dart';
import '../../core/widgets/finanzas_card.dart';
import '../../core/widgets/finanzas_top_app_bar.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});
  @override State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final tt = Theme.of(ctx).textTheme;
    return Scaffold(
      appBar: FinanzasTopAppBar(subtitle: 'Tus gastos · Junio 2026'),
      body: Column(children: [
        TabBar(
          controller: _tab,
          labelColor: cs.primary,
          indicatorColor: cs.primary,
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Fijos'),
            Tab(text: 'Variables'),
          ],
        ),
        Expanded(child: TabBarView(controller: _tab, children: [
          _ListaGastos(tipo: 'todos', cs: cs, tt: tt),
          _ListaGastos(tipo: 'fijos', cs: cs, tt: tt),
          _ListaGastos(tipo: 'variables', cs: cs, tt: tt),
        ])),
      ]),
    );
  }
}

class _ListaGastos extends StatelessWidget {
  final String tipo;
  final ColorScheme cs;
  final TextTheme tt;
  const _ListaGastos({required this.tipo, required this.cs, required this.tt});

  @override
  Widget build(BuildContext ctx) {
    final gastosFijos = [
      ('Alquiler', 'Vivienda', 'S/ 1,500', Icons.home_outlined, true),
      ('Internet', 'Servicios', 'S/ 120', Icons.wifi_outlined, true),
      ('Netflix', 'Entretenim.', 'S/ 45', Icons.tv_outlined, true),
    ];
    final gastosVar = [
      ('Mercado', 'Alimentación', 'S/ 230', Icons.shopping_cart_outlined, false),
      ('Taxi', 'Transporte', 'S/ 35', Icons.directions_car_outlined, false),
    ];
    final todos = [...gastosFijos, ...gastosVar];
    final lista = tipo == 'fijos' ? gastosFijos
        : tipo == 'variables' ? gastosVar : todos;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: lista.map((g) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FinanzasCard(
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(g.$4, color: cs.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g.$1, style: tt.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500, fontSize: 14)),
                Row(children: [
                  Text(g.$2, style: tt.bodySmall),
                  if (g.$5) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Fijo',
                          style: TextStyle(fontSize: 10, color: cs.primary)),
                    ),
                  ],
                ]),
              ],
            )),
            Text(g.$3, style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600,
                color: cs.error)),
          ]),
        ),
      )).toList(),
    );
  }
}
