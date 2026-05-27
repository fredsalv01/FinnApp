import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/gastos/gastos_screen.dart';
import '../features/ahorros/ahorros_screen.dart';
import '../features/reportes/reportes_screen.dart';
import '../features/configuracion/configuracion_screen.dart';
import '../features/recomendaciones/recomendaciones_ia_screen.dart';
import '../features/gastos/agregar_gasto_screen.dart';
import '../features/ahorros/crear_meta_screen.dart';
import '../features/splash/splash_screen.dart';

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
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
    return Scaffold(
      body: widget.child,
      floatingActionButton: _idx < 3
          ? FloatingActionButton(
              onPressed: () => _idx == 1
                  ? ctx.push('/gastos/agregar')
                  : _idx == 2
                      ? ctx.push('/ahorros/nueva-meta')
                      : null,
              child: const Icon(Icons.add),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) {
          setState(() => _idx = i);
          ctx.go(_routes[i]);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined),     activeIcon: Icon(Icons.dashboard),     label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.payments_outlined),      activeIcon: Icon(Icons.payments),      label: 'Gastos'),
          BottomNavigationBarItem(icon: Icon(Icons.savings_outlined),       activeIcon: Icon(Icons.savings),       label: 'Ahorros'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined),     activeIcon: Icon(Icons.analytics),     label: 'Reportes'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined),      activeIcon: Icon(Icons.settings),      label: 'Config'),
        ],
      ),
    );
  }
}
