import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/models/gasto.dart';
import '../../shared/services/database_helper.dart';
import '../../shared/services/user_preferences.dart';
import 'widgets/add_gasto_fijo_modal.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  final _nameCtrl = TextEditingController();
  final _incomeCtrl = TextEditingController();
  final List<Gasto> _gastosFijos = [];
  int _currentPage = 0;
  bool _saving = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _incomeCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0 && _nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa tu nombre')),
      );
      return;
    }
    if (_currentPage == 1) {
      final income = double.tryParse(_incomeCtrl.text.trim());
      if (income == null || income <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa un ingreso válido')),
        );
        return;
      }
    }
    _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    _pageCtrl.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _openAddGastoFijo() async {
    final result = await showModalBottomSheet<Gasto>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddGastoFijoModal(),
    );
    if (result != null) {
      setState(() => _gastosFijos.add(result));
    }
  }

  void _removeGasto(int index) {
    setState(() => _gastosFijos.removeAt(index));
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final name = _nameCtrl.text.trim();
    final income = double.tryParse(_incomeCtrl.text.trim()) ?? 0;

    final prefs = UserPreferences();
    await prefs.setUserName(name);
    await prefs.setUserIncome(income);
    await prefs.setOnboardingDone(true);

    final db = DatabaseHelper();
    for (final g in _gastosFijos) {
      await db.insertGasto(g);
    }

    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= _currentPage
                            ? cs.primary
                            : cs.onSurface.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // PageView
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildNamePage(cs, tt),
                  _buildIncomePage(cs, tt),
                  _buildExpensesPage(cs, tt),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PAGE 1: Nombre ---
  Widget _buildNamePage(ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.waving_hand, size: 64, color: cs.primary),
          const SizedBox(height: 24),
          Text('¡Bienvenido a Finn!',
              style: tt.headlineLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Tu asistente de finanzas personales',
              style: tt.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 40),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: '¿Cómo te llamas?',
              hintText: 'Tu nombre',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _nextPage,
              child: const Text('Continuar'),
            ),
          ),
        ],
      ),
    );
  }

  // --- PAGE 2: Ingreso mensual ---
  Widget _buildIncomePage(ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 64, color: cs.primary),
          const SizedBox(height: 24),
          Text('¿Cuánto ganas al mes?',
              style: tt.headlineLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Ingresa tu ingreso mensual total',
              style: tt.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 40),
          TextField(
            controller: _incomeCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Ingreso mensual',
              hintText: 'Ej. 2500.00',
              prefixText: '\$ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _prevPage,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('Atrás'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _nextPage,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('Continuar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- PAGE 3: Gastos fijos ---
  Widget _buildExpensesPage(ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Center(
            child: Icon(Icons.receipt_long_outlined,
                size: 56, color: cs.primary),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('Gastos fijos mensuales',
                style: tt.headlineLarge, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text('Agrega los gastos que pagas cada mes (opcional)',
                style: tt.bodySmall, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 24),

          // Lista de gastos fijos
          Expanded(
            child: _gastosFijos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline,
                            size: 48,
                            color: cs.onSurface.withValues(alpha: 0.25)),
                        const SizedBox(height: 8),
                        Text('Aún no tienes gastos fijos',
                            style: tt.bodySmall),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _gastosFijos.length,
                    itemBuilder: (_, i) {
                      final g = _gastosFijos[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            child: Icon(Icons.payments_outlined,
                                color: cs.onPrimaryContainer),
                          ),
                          title: Text(g.nombre),
                          subtitle: Text(g.categoria),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('\$${g.monto.toStringAsFixed(2)}',
                                  style: tt.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _removeGasto(i),
                                child: Icon(Icons.close,
                                    size: 18,
                                    color: cs.error),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 8),
          // Botón agregar
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openAddGastoFijo,
              icon: const Icon(Icons.add),
              label: const Text('Agregar gasto fijo'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Botones de navegación
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _prevPage,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('Atrás'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _finish,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(_saving ? 'Guardando...' : 'Comenzar'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
