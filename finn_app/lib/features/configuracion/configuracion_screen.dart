import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/finanzas_top_app_bar.dart';
import '../../app/theme_provider.dart';
import '../../shared/services/database_helper.dart';
import '../../shared/services/user_preferences.dart';
import '../../shared/services/data_refresh_notifier.dart';
import '../../shared/widgets/editar_perfil_modal.dart';
import '../../shared/widgets/confirm_dialog.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});
  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final bool _conectado = false;
  String _nombre = '';
  double _ingreso = 0;
  int _gastosFijosActivos = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    DataRefreshNotifier().addListener(_load);
  }

  @override
  void dispose() {
    DataRefreshNotifier().removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = UserPreferences();
    final db = DatabaseHelper();
    final n = await prefs.getUserName();
    final i = await prefs.getUserIncome();
    final gastos = await db.getGastos();
    if (!mounted) return;
    setState(() {
      _nombre = n ?? '';
      _ingreso = i ?? 0;
      _gastosFijosActivos = gastos.where((g) => g.esFijo).length;
      _loading = false;
    });
  }

  Future<void> _editarPerfil() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EditarPerfilModal(
        currentName: _nombre,
        currentIncome: _ingreso,
      ),
    );
    if (result == true) {
      DataRefreshNotifier().refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
    }
  }

  Future<void> _resetearApp() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Reiniciar app',
      message:
          'Se eliminarán todos tus datos (perfil, gastos, metas y aportes). ¿Continuar?',
      confirmText: 'Reiniciar',
    );
    if (!ok) return;
    await DatabaseHelper().clearAll();
    await UserPreferences().clearAll();
    if (!mounted) return;
    context.go('/onboarding');
  }

  @override
  Widget build(BuildContext ctx) {
    final themeProvider = Provider.of<ThemeProvider>(ctx);
    final cs = Theme.of(ctx).colorScheme;
    final tt = Theme.of(ctx).textTheme;

    if (_loading) {
      return const Scaffold(
        appBar: FinanzasTopAppBar(subtitle: 'Configuración'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const FinanzasTopAppBar(subtitle: 'Configuración'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SeccionTitulo('Perfil', tt),
          _ConfigTile(
            icon: Icons.person_outline,
            label: 'Nombre',
            value: _nombre.isEmpty ? 'Sin definir' : _nombre,
            cs: cs,
            onTap: _editarPerfil,
          ),
          _ConfigTile(
            icon: Icons.attach_money,
            label: 'Ingreso mensual',
            value: 'S/ ${_ingreso.toStringAsFixed(2)}',
            cs: cs,
            onTap: _editarPerfil,
          ),
          _ConfigTile(
            icon: Icons.monetization_on_outlined,
            label: 'Moneda',
            value: 'Soles (S/)',
            cs: cs,
          ),
          const Divider(height: 24),

          _SeccionTitulo('Apariencia', tt),
          SwitchListTile(
            secondary: Icon(Icons.dark_mode_outlined, color: cs.primary),
            title: const Text('Modo oscuro'),
            subtitle: const Text('Usar tema oscuro en la app'),
            value: themeProvider.isDarkMode,
            onChanged: (v) => themeProvider.toggleTheme(v),
            activeThumbColor: cs.primary,
          ),
          const Divider(height: 24),

          _SeccionTitulo('Google Sheets', tt),
          ListTile(
            leading: Icon(Icons.table_chart_outlined, color: cs.primary),
            title: const Text('Conectar Google Sheets'),
            subtitle: Text(_conectado
                ? 'Última sync: hoy 10:32am'
                : 'No conectado'),
            trailing: _conectado
                ? TextButton(
                    onPressed: () {},
                    child: Text('Sync',
                        style: TextStyle(color: cs.primary)))
                : FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Próximamente: conexión con Google Sheets')),
                      );
                    },
                    child: const Text('Conectar'),
                  ),
          ),
          const Divider(height: 24),

          _SeccionTitulo('Datos', tt),
          _ConfigTile(
            icon: Icons.repeat,
            label: 'Gastos fijos activos',
            value: '$_gastosFijosActivos activos',
            cs: cs,
            onTap: () => context.go('/gastos'),
          ),
          ListTile(
            leading: Icon(Icons.restart_alt, color: cs.error),
            title: Text('Reiniciar app',
                style: TextStyle(color: cs.error)),
            subtitle: const Text('Borra todos los datos y vuelve al inicio'),
            onTap: _resetearApp,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _SeccionTitulo extends StatelessWidget {
  final String titulo;
  final TextTheme tt;
  const _SeccionTitulo(this.titulo, this.tt);

  @override
  Widget build(BuildContext ctx) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(titulo, style: tt.headlineMedium),
      );
}

class _ConfigTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final ColorScheme cs;
  final VoidCallback? onTap;
  const _ConfigTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
    this.onTap,
  });

  @override
  Widget build(BuildContext ctx) => ListTile(
        leading: Icon(icon, color: cs.primary),
        title: Text(label),
        subtitle: Text(value),
        trailing: onTap != null
            ? const Icon(Icons.chevron_right, size: 18)
            : null,
        onTap: onTap,
      );
}
