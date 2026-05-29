import 'dart:ui';
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
import '../shared/models/gasto.dart';
import '../features/ahorros/crear_meta_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/configuracion/recordatorios_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/ingresos/agregar_ingreso_screen.dart';
import '../features/notificaciones/notificaciones_screen.dart';

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
    GoRoute(path: '/gastos/agregar',   builder: (c, s) => AgregarGastoScreen(gasto: s.extra as Gasto?)),
    GoRoute(path: '/ahorros/nueva-meta', builder: (c, s) => const CrearMetaScreen()),
    GoRoute(path: '/recomendaciones',  builder: (c, s) => const RecomendacionesIAScreen()),
    GoRoute(path: '/config/recordatorios', builder: (c, s) => const RecordatoriosScreen()),
    GoRoute(path: '/auth', builder: (c, s) => const AuthScreen()),
    GoRoute(path: '/ingresos/agregar', builder: (c, s) => const AgregarIngresoScreen()),
    GoRoute(path: '/notificaciones', builder: (c, s) => const NotificacionesScreen()),
  ],
);

// Shell con BottomNavBar flotante glassmorphism
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
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SalomonBottomBar(
                currentIndex: _idx,
                onTap: (i) {
                  setState(() => _idx = i);
                  ctx.go(_routes[i]);
                },
                selectedItemColor: cs.primary,
                unselectedItemColor: Colors.grey.withValues(alpha: 0.6),
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                itemPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                items: [
                  SalomonBottomBarItem(
                    icon: const Icon(Icons.dashboard_rounded),
                    title: const Text("Dashboard"),
                    selectedColor: cs.primary,
                  ),
                  SalomonBottomBarItem(
                    icon: const Icon(Icons.payments_rounded),
                    title: const Text("Gastos"),
                    selectedColor: cs.error,
                  ),
                  SalomonBottomBarItem(
                    icon: const Icon(Icons.savings_rounded),
                    title: const Text("Ahorros"),
                    selectedColor: cs.secondary,
                  ),
                  SalomonBottomBarItem(
                    icon: const Icon(Icons.bar_chart_rounded),
                    title: const Text("Reportes"),
                    selectedColor: cs.primary,
                  ),
                  SalomonBottomBarItem(
                    icon: const Icon(Icons.tune_rounded),
                    title: const Text("Config"),
                    selectedColor: Colors.purpleAccent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
