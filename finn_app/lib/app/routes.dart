import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/gastos/gastos_screen.dart';
import '../features/ahorros/ahorros_screen.dart';
import '../features/reportes/reportes_screen.dart';
import '../features/configuracion/configuracion_screen.dart';
import '../features/recomendaciones/recomendaciones_ia_screen.dart';
import '../features/gastos/agregar_gasto_screen.dart';
import '../features/ahorros/crear_meta_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/configuracion/recordatorios_screen.dart';

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
    ShellRoute(
      builder: (ctx, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/',          builder: (c, s) => const DashboardScreen()),
        GoRoute(path: '/gastos',    builder: (c, s) => const GastosScreen()),
        GoRoute(path: '/ahorros',   builder: (c, s) => const AhorrosScreen()),
        GoRoute(path: '/reportes',  builder: (c, s) => const ReportesScreen()),
        GoRoute(path: '/config',    builder: (c, s) => const ConfiguracionScreen()),
      ],
    ),
    GoRoute(path: '/gastos/agregar',   builder: (c, s) => const AgregarGastoScreen()),
    GoRoute(path: '/ahorros/nueva-meta', builder: (c, s) => const CrearMetaScreen()),
    GoRoute(path: '/recomendaciones',  builder: (c, s) => const RecomendacionesIAScreen()),
    GoRoute(path: '/config/recordatorios', builder: (c, s) => const RecordatoriosScreen()),
  ],
);

// Shell con BottomNavBar y FAB
class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});
  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _idx = 0;

  final _routes = ['/', '/gastos', '/ahorros', '/reportes', '/config'];

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1.0,
            ),
          ),
        ),
        child: SalomonBottomBar(
          currentIndex: _idx,
          onTap: (i) {
            setState(() => _idx = i);
            ctx.go(_routes[i]);
          },
          selectedItemColor: cs.primary,
          unselectedItemColor: Colors.grey,
          items: [
            SalomonBottomBarItem(
              icon: const Icon(Icons.dashboard_outlined),
              title: const Text("Dashboard"),
              selectedColor: cs.primary,
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.payments_outlined),
              title: const Text("Gastos"),
              selectedColor: cs.error,
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.savings_outlined),
              title: const Text("Ahorros"),
              selectedColor: cs.secondary,
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.analytics_outlined),
              title: const Text("Reportes"),
              selectedColor: cs.primary,
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.settings_outlined),
              title: const Text("Config"),
              selectedColor: Colors.purpleAccent,
            ),
          ],
        ),
      ),
    );
  }
}
