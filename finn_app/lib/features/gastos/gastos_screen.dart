import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/finanzas_card.dart';
import '../../core/widgets/finanzas_top_app_bar.dart';
import '../../shared/models/gasto.dart';
import '../../shared/services/database_helper.dart';
import '../../shared/services/data_refresh_notifier.dart';
import '../../shared/widgets/confirm_dialog.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});
  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Gasto> _gastos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
    DataRefreshNotifier().addListener(_load);
  }

  Future<void> _load() async {
    final gastos = await DatabaseHelper().getGastos();
    if (!mounted) return;
    setState(() {
      _gastos = gastos;
      _loading = false;
    });
  }

  Future<void> _deleteGasto(Gasto g) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Eliminar gasto',
      message: '¿Eliminar "${g.nombre}"? Esta acción no se puede deshacer.',
    );
    if (!ok || g.id == null) return;
    await DatabaseHelper().deleteGasto(g.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gasto eliminado')),
    );
    _load();
  }

  @override
  void dispose() {
    DataRefreshNotifier().removeListener(_load);
    _tab.dispose();
    super.dispose();
  }

  String get _mesActual {
    final now = DateTime.now();
    return DateFormat('MMMM yyyy', 'es').format(now);
  }

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final tt = Theme.of(ctx).textTheme;

    final fijos = _gastos.where((g) => g.esFijo).toList();
    final variables = _gastos.where((g) => !g.esFijo).toList();

    return Scaffold(
      appBar: FinanzasTopAppBar(subtitle: 'Tus gastos · $_mesActual'),
      body: Column(
        children: [
          TabBar(
            controller: _tab,
            labelColor: cs.primary,
            indicatorColor: cs.primary,
            tabs: [
              Tab(text: 'Todos (${_gastos.length})'),
              Tab(text: 'Fijos (${fijos.length})'),
              Tab(text: 'Variables (${variables.length})'),
            ],
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _ListaGastos(gastos: _gastos, cs: cs, tt: tt, onDelete: _deleteGasto, onRefresh: _load),
                  _ListaGastos(gastos: fijos, cs: cs, tt: tt, onDelete: _deleteGasto, onRefresh: _load),
                  _ListaGastos(gastos: variables, cs: cs, tt: tt, onDelete: _deleteGasto, onRefresh: _load),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ListaGastos extends StatelessWidget {
  final List<Gasto> gastos;
  final ColorScheme cs;
  final TextTheme tt;
  final Future<void> Function(Gasto) onDelete;
  final Future<void> Function() onRefresh;

  const _ListaGastos({
    required this.gastos,
    required this.cs,
    required this.tt,
    required this.onDelete,
    required this.onRefresh,
  });

  IconData _iconFor(String c) {
    switch (c) {
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
    if (gastos.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 64, color: cs.onSurface.withValues(alpha: 0.2)),
                    const SizedBox(height: 12),
                    Text('No hay gastos registrados', style: tt.bodySmall),
                    const SizedBox(height: 4),
                    Text('Usa el botón + para agregar uno', style: tt.bodySmall),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: gastos.length,
        itemBuilder: (_, i) {
          final g = gastos[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Dismissible(
              key: ValueKey('gasto_${g.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: cs.error.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (_) async {
                await onDelete(g);
                return false;
              },
              child: FinanzasCard(
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_iconFor(g.categoria),
                        color: cs.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.nombre,
                            style: tt.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500, fontSize: 14)),
                        Row(children: [
                          Text(g.categoria, style: tt.bodySmall),
                          const SizedBox(width: 6),
                          Text('· ${DateFormat('dd/MM').format(g.fecha)}',
                              style: tt.bodySmall),
                          if (g.esFijo) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('Fijo',
                                  style: TextStyle(
                                      fontSize: 10, color: cs.primary)),
                            ),
                          ],
                        ]),
                      ],
                    ),
                  ),
                  Text('S/ ${g.monto.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cs.error)),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}
