import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../shared/models/gasto.dart';
import '../../shared/services/database_helper.dart';
import '../../shared/services/user_preferences.dart';
import '../../shared/services/notification_service.dart';
import '../../core/widgets/finanzas_card.dart';
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
    if (_currentPage == 2) {
      _finish();
      return;
    }

    _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _prevPage() {
    _pageCtrl.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _openAddGastoFijo() async {
    final result = await showModalBottomSheet<Gasto>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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

  Future<void> _requestPermissions() async {
    await NotificationService().requestPermissions();
    _nextPage();
  }

  Future<void> _finish() async {
    final name = _nameCtrl.text.trim();
    final incomeStr = _incomeCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa tu nombre')),
      );
      return;
    }

    final income = double.tryParse(incomeStr);
    if (income == null || income <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un ingreso mensual válido')),
      );
      return;
    }

    setState(() => _saving = true);

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
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildBenefitsPage(cs, tt),
                  _buildPermissionsPage(cs, tt),
                  _buildSetupPage(cs, tt),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _prevPage,
                      child: const Text('Atrás', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    const SizedBox(width: 60),
                  SmoothPageIndicator(
                    controller: _pageCtrl,
                    count: 3,
                    effect: ExpandingDotsEffect(
                      activeDotColor: cs.primary,
                      dotColor: Colors.white.withValues(alpha: 0.15),
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                      spacing: 6,
                    ),
                  ),
                  if (_currentPage < 2)
                    TextButton(
                      onPressed: _currentPage == 1 ? _requestPermissions : _nextPage,
                      child: Text(_currentPage == 1 ? 'Permitir' : 'Siguiente',
                          style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
                    )
                  else
                    const SizedBox(width: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PAGE 1: Beneficios ---
  Widget _buildBenefitsPage(ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome, size: 64, color: cs.primary),
          ),
          const SizedBox(height: 32),
          Text(
            'Toma el Control\nde tus Finanzas',
            textAlign: TextAlign.center,
            style: tt.displayMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Finn te ayuda a presupuestar, ahorrar inteligentemente y controlar tus gastos con una interfaz moderna y fluida.',
            textAlign: TextAlign.center,
            style: tt.bodyLarge?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 48),
          FinanzasCard(
            child: Row(
              children: [
                Icon(Icons.bolt, color: cs.secondary, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alertas inteligentes',
                          style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Te notificamos cuando gastas de más.', style: tt.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- PAGE 2: Permisos ---
  Widget _buildPermissionsPage(ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_active_outlined, size: 64, color: cs.secondary),
          ),
          const SizedBox(height: 32),
          Text(
            'Mantente al Día',
            textAlign: TextAlign.center,
            style: tt.displayMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Necesitamos tu permiso para enviarte recordatorios de pago de servicios y alertas de presupuestos.',
            textAlign: TextAlign.center,
            style: tt.bodyLarge?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: _requestPermissions,
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Activar Notificaciones',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _nextPage,
            child: const Text('Ahora no', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // --- PAGE 3: Setup Inicial ---
  Widget _buildSetupPage(ColorScheme cs, TextTheme tt) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        Text('Configuración', style: tt.labelSmall?.copyWith(color: cs.primary)),
        const SizedBox(height: 8),
        Text('Empecemos a planificar', style: tt.headlineLarge),
        const SizedBox(height: 24),
        TextField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Tu nombre',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _incomeCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Ingreso mensual total',
            prefixText: 'S/ ',
            prefixIcon: const Icon(Icons.wallet),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Gastos Fijos Iniciales', style: tt.headlineMedium),
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: cs.primary, size: 28),
              onPressed: _openAddGastoFijo,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_gastosFijos.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Center(
              child: Text(
                'Agrega alquiler, internet, etc. (Opcional)',
                style: tt.bodySmall?.copyWith(color: Colors.grey),
              ),
            ),
          )
        else
          ...List.generate(_gastosFijos.length, (i) {
            final g = _gastosFijos[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FinanzasCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(g.categoria, style: tt.bodySmall),
                        ],
                      ),
                    ),
                    Text('S/ ${g.monto.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                      onPressed: () => _removeGasto(i),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: _saving ? null : _finish,
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Text('Comenzar mi Aventura',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
