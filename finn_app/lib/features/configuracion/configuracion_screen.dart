import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/config/app_config.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/widgets/finanzas_card.dart';
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
    await Future.delayed(const Duration(milliseconds: 350));
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
      useRootNavigator: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
        SnackBar(
          backgroundColor: const Color(0xFF1E1E1E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: const Text('Perfil actualizado'),
        ),
      );
    }
  }

  Future<void> _resetearApp() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Reiniciar app',
      message: 'Se eliminarán todos tus datos (perfil, gastos, metas y aportes). ¿Continuar?',
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
      return Scaffold(
        appBar: const FinanzasTopAppBar(subtitle: 'Configuración'),
        body: Shimmer.fromColors(
          baseColor: Colors.white.withValues(alpha: 0.05),
          highlightColor: Colors.white.withValues(alpha: 0.12),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _shimmerBox(height: 20, width: 80),
              const SizedBox(height: 12),
              _shimmerBox(height: 160),
              const SizedBox(height: 20),
              _shimmerBox(height: 20, width: 100),
              const SizedBox(height: 12),
              _shimmerBox(height: 80),
              const SizedBox(height: 20),
              _shimmerBox(height: 20, width: 120),
              const SizedBox(height: 12),
              _shimmerBox(height: 80),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const FinanzasTopAppBar(subtitle: 'Configuración'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: [

          // ── Cuenta ───────────────────────────────────────────
          _SectionHeader(label: 'Cuenta', tt: tt),
          const SizedBox(height: 10),
          _AccountCard(cs: cs, tt: tt),

          const SizedBox(height: 24),

          // ── Perfil ───────────────────────────────────────────
          _SectionHeader(label: 'Perfil', tt: tt),
          const SizedBox(height: 10),
          FinanzasCard(
            onTap: _editarPerfil,
            child: Column(
              children: [
                _SettingRow(
                  icon: Icons.person_rounded,
                  iconColor: cs.secondary,
                  label: 'Nombre',
                  value: _nombre.isEmpty ? 'Sin definir' : _nombre,
                  cs: cs,
                  showArrow: true,
                ),
                _Divider(),
                _SettingRow(
                  icon: Icons.attach_money_rounded,
                  iconColor: cs.primary,
                  label: 'Ingreso mensual',
                  value: 'S/ ${_ingreso.toStringAsFixed(2)}',
                  cs: cs,
                  showArrow: true,
                ),
                _Divider(),
                _SettingRow(
                  icon: Icons.monetization_on_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  label: 'Moneda',
                  value: 'Soles (S/)',
                  cs: cs,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Notificaciones ───────────────────────────────────
          _SectionHeader(label: 'Notificaciones', tt: tt),
          const SizedBox(height: 10),
          FinanzasCard(
            onTap: () => context.push('/config/recordatorios'),
            child: _SettingRow(
              icon: Icons.notifications_active_rounded,
              iconColor: cs.primary,
              label: 'Recordatorios de pago',
              value: 'Programar avisos de pago',
              cs: cs,
              showArrow: true,
            ),
          ),

          const SizedBox(height: 24),

          // ── Apariencia ───────────────────────────────────────
          _SectionHeader(label: 'Apariencia', tt: tt),
          const SizedBox(height: 10),
          FinanzasCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.dark_mode_rounded,
                      color: Color(0xFF8B5CF6), size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Modo oscuro',
                          style: tt.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text('Usar tema oscuro en la app', style: tt.bodySmall),
                    ],
                  ),
                ),
                Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (v) => themeProvider.toggleTheme(v),
                  activeThumbColor: cs.primary,
                  activeTrackColor: cs.primary.withValues(alpha: 0.3),
                  inactiveThumbColor: Colors.grey.shade600,
                  inactiveTrackColor: Colors.grey.shade800,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Datos ─────────────────────────────────────────────
          _SectionHeader(label: 'Datos', tt: tt),
          const SizedBox(height: 10),
          FinanzasCard(
            child: Column(
              children: [
                _SettingRow(
                  icon: Icons.repeat_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  label: 'Gastos fijos activos',
                  value: '$_gastosFijosActivos activos',
                  cs: cs,
                  showArrow: true,
                  onTap: () => context.go('/gastos'),
                ),
                _Divider(),
                InkWell(
                  onTap: _resetearApp,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: cs.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.restart_alt_rounded,
                            color: cs.error, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reiniciar app',
                                style: tt.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: cs.error)),
                            const SizedBox(height: 2),
                            Text('Borra todos los datos y vuelve al inicio',
                                style: tt.bodySmall),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: cs.error.withValues(alpha: 0.6), size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Google Sheets ─────────────────────────────────────
          _SectionHeader(label: 'Integraciones', tt: tt),
          const SizedBox(height: 10),
          FinanzasCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.table_chart_rounded,
                      color: cs.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Google Sheets',
                        style: tt.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _conectado ? 'Conectado · Sync hoy' : 'No conectado',
                        style: tt.bodySmall?.copyWith(
                          color: _conectado ? cs.primary : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                _conectado
                    ? TextButton(
                        onPressed: () {},
                        child: Text('Sync',
                            style: TextStyle(color: cs.primary)))
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF1E1E1E),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                content: const Text(
                                    'Próximamente: conexión con Google Sheets'),
                              ),
                            );
                          },
                          child: Text(
                            'Conectar',
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Version
          Center(
            child: Text(
              'Finn v1.0.0',
              style: tt.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox({required double height, double? width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ── Account Card ──────────────────────────────────────────────────────────────

class _AccountCard extends StatefulWidget {
  final ColorScheme cs;
  final TextTheme tt;
  const _AccountCard({required this.cs, required this.tt});

  @override
  State<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<_AccountCard> {
  bool _syncing = false;

  Future<void> _handleSignOut() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Cerrar sesión',
      message: 'Tus datos locales se conservan. ¿Confirmar?',
      confirmText: 'Cerrar sesión',
    );
    if (!ok) return;
    try {
      await AuthService().signOut();
    } catch (_) {}
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _handleSyncNow() async {
    setState(() => _syncing = true);
    await SyncService().uploadAll();
    await SyncService().pullAll();
    if (!mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E1E1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: const Text('Sincronización completa'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final cs = widget.cs;
    final tt = widget.tt;
    final isConfigured = AppConfig.supabaseUrl.isNotEmpty;

    if (!isConfigured) {
      return FinanzasCard(
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.cloud_off_rounded,
                color: Colors.grey, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Cloud no configurado',
              style: tt.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
        ]),
      );
    }

    if (auth.isSignedIn) {
      return FinanzasCard(
        child: Column(children: [
          Row(children: [
            ClipOval(
              child: auth.avatarUrl != null
                  ? Image.network(
                      auth.avatarUrl!,
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _defaultAvatar(cs),
                    )
                  : _defaultAvatar(cs),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auth.userName ?? 'Usuario',
                    style: tt.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(auth.userEmail ?? '',
                      style: tt.bodySmall?.copyWith(
                          color: cs.primary.withValues(alpha: 0.8))),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Conectado',
                style: TextStyle(
                    color: cs.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: _syncing ? null : _handleSyncNow,
                  icon: _syncing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.sync_rounded, size: 16),
                  label:
                      Text(_syncing ? 'Sincronizando...' : 'Sync ahora'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.primary,
                    side: BorderSide(
                        color: cs.primary.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 40,
              child: OutlinedButton.icon(
                onPressed: _handleSignOut,
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: const Text('Salir'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.error,
                  side: BorderSide(
                      color: cs.error.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ]),
        ]),
      );
    }

    // Not signed in
    return FinanzasCard(
      onTap: () => context.push('/auth').then((_) => setState(() {})),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.cloud_upload_rounded,
              color: cs.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Conectar cuenta Google',
                  style: tt.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 2),
              Text('Backup automático en la nube', style: tt.bodySmall),
            ],
          ),
        ),
        Icon(Icons.chevron_right_rounded,
            color: cs.primary.withValues(alpha: 0.5), size: 20),
      ]),
    );
  }

  Widget _defaultAvatar(ColorScheme cs) {
    return Container(
      width: 42,
      height: 42,
      color: cs.primary.withValues(alpha: 0.15),
      child: Icon(Icons.account_circle_rounded, color: cs.primary, size: 28),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final TextTheme tt;
  const _SectionHeader({required this.label, required this.tt});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: tt.labelSmall?.copyWith(
          color: Colors.white.withValues(alpha: 0.4),
          letterSpacing: 1.4,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        height: 1,
        color: Colors.white.withValues(alpha: 0.05),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label, value;
  final ColorScheme cs;
  final bool showArrow;
  final VoidCallback? onTap;
  const _SettingRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.cs,
    this.showArrow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: tt.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(value, style: tt.bodySmall),
              ],
            ),
          ),
          if (showArrow)
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.3), size: 20),
        ],
      ),
    );
  }
}
