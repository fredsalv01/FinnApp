import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/finanzas_top_app_bar.dart';
import '../../app/theme_provider.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});
  @override State<ConfiguracionScreen> createState() =>
      _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  bool _conectado = false;

  @override
  Widget build(BuildContext ctx) {
    final themeProvider = Provider.of<ThemeProvider>(ctx);
    final cs = Theme.of(ctx).colorScheme;
    final tt = Theme.of(ctx).textTheme;
    return Scaffold(
      appBar: const FinanzasTopAppBar(subtitle: 'Configuración'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Perfil
          _SeccionTitulo('Perfil', tt),
          _ConfigTile(icon: Icons.person_outline, label: 'Nombre', value: 'Usuario', cs: cs),
          _ConfigTile(icon: Icons.attach_money, label: 'Ingreso mensual', value: 'S/ 5,500', cs: cs),
          _ConfigTile(icon: Icons.monetization_on_outlined, label: 'Moneda', value: 'Soles (S/)', cs: cs),
          const Divider(height: 24),

          // Apariencia
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

          // Google Sheets
          _SeccionTitulo('Google Sheets', tt),
          ListTile(
            leading: Icon(Icons.table_chart_outlined, color: cs.primary),
            title: const Text('Conectar Google Sheets'),
            subtitle: Text(_conectado
                ? 'Última sync: hoy 10:32am' : 'No conectado'),
            trailing: _conectado
                ? TextButton(onPressed: () {},
                    child: Text('Sync', style: TextStyle(color: cs.primary)))
                : FilledButton(
                    onPressed: () => setState(() => _conectado = true),
                    child: const Text('Conectar'),
                  ),
          ),
          const Divider(height: 24),

          // Categorías
          _SeccionTitulo('Categorías', tt),
          _ConfigTile(icon: Icons.category_outlined,
              label: 'Gestionar categorías',
              value: '8 categorías activas', cs: cs),
          _ConfigTile(icon: Icons.repeat,
              label: 'Gastos fijos activos',
              value: '3 activos', cs: cs),
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
  const _ConfigTile({required this.icon, required this.label,
      required this.value, required this.cs});

  @override
  Widget build(BuildContext ctx) => ListTile(
    leading: Icon(icon, color: cs.primary),
    title: Text(label),
    subtitle: Text(value),
    trailing: const Icon(Icons.chevron_right, size: 18),
    onTap: () {},
  );
}
