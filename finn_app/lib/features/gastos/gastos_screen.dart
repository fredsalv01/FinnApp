import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
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
    await Future.delayed(const Duration(milliseconds: 400)); // Shimmer delay
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
      appBar: FinanzasTopAppBar(
        subtitle: 'Tus gastos · $_mesActual',
        onAdd: () => ctx.push('/gastos/agregar'),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tab,
            labelColor: cs.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: cs.primary,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: 'Todos (${_gastos.length})'),
              Tab(text: 'Fijos (${fijos.length})'),
              Tab(text: 'Variables (${variables.length})'),
            ],
          ),
          if (_loading)
            Expanded(child: _buildShimmerLoader())
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

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.05),
      highlightColor: Colors.white.withValues(alpha: 0.1),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
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
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.receipt_long_outlined,
                          size: 64, color: cs.primary),
                    ),
                    const SizedBox(height: 24),
                    Text('Aún no registras gastos',
                        style: tt.headlineMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text('Lleva un control detallado de tus compras y salidas.',
                        style: tt.bodySmall?.copyWith(color: Colors.grey),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 50,
                      width: 200,
                      child: FilledButton.icon(
                        onPressed: () => ctx.push('/gastos/agregar'),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Gasto', style: TextStyle(fontWeight: FontWeight.bold)),
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
            padding: const EdgeInsets.only(bottom: 10),
            child: Dismissible(
              key: ValueKey('gasto_${g.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: cs.error.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(24),
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(_iconFor(g.categoria),
                        color: cs.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.nombre,
                            style: tt.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 2),
                        Row(children: [
                          Text(g.categoria, style: tt.bodySmall),
                          const SizedBox(width: 8),
                          Text('· ${DateFormat('dd/MM').format(g.fecha)}',
                              style: tt.bodySmall?.copyWith(color: Colors.grey)),
                          if (g.esFijo) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Fijo',
                                  style: TextStyle(
                                      fontSize: 10, color: cs.primary, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ]),
                      ],
                    ),
                  ),
                  Text('S/ ${g.monto.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
