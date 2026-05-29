import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/finanzas_top_app_bar.dart';
import '../../core/widgets/finanzas_card.dart';
import '../../shared/services/notification_service.dart';

class NotificacionesScreen extends StatelessWidget {
  const NotificacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const FinanzasTopAppBar(subtitle: 'Notificaciones'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _SectionLabel('AUTOMÁTICAS', tt),
          const SizedBox(height: 10),
          FinanzasCard(
            child: Column(
              children: [
                _NotifRow(
                  icon: Icons.notifications_active_rounded,
                  color: cs.primary,
                  title: 'Recordatorio diario',
                  subtitle: 'Todos los días a las 6:00 pm',
                  trailing: _ActiveBadge(cs: cs),
                ),
                _Divider(),
                _NotifRow(
                  icon: Icons.calendar_month_rounded,
                  color: cs.secondary,
                  title: 'Resumen mensual',
                  subtitle: 'El día 28 de cada mes a las 8:00 pm',
                  trailing: _ActiveBadge(cs: cs),
                ),
                _Divider(),
                _NotifRow(
                  icon: Icons.cloud_outlined,
                  color: const Color(0xFF8B5CF6),
                  title: 'Alerta de cuenta Google',
                  subtitle: 'Si no tienes backup activo',
                  trailing: _ActiveBadge(cs: cs),
                ),
                _Divider(),
                _NotifRow(
                  icon: Icons.receipt_long_outlined,
                  color: const Color(0xFFF59E0B),
                  title: 'Sin gastos en el mes',
                  subtitle: 'Si llevas 5+ días sin anotar',
                  trailing: _ActiveBadge(cs: cs),
                ),
                _Divider(),
                _NotifRow(
                  icon: Icons.savings_outlined,
                  color: cs.error,
                  title: 'Meta próxima a vencer',
                  subtitle: 'Cuando queden 3 días o menos',
                  trailing: _ActiveBadge(cs: cs),
                ),
                _Divider(),
                _NotifRow(
                  icon: Icons.trending_up_rounded,
                  color: cs.error,
                  title: 'Alerta de gastos elevados',
                  subtitle: 'Si gastas 30% más que la semana pasada',
                  trailing: _ActiveBadge(cs: cs),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _SectionLabel('RECORDATORIOS DE PAGO', tt),
          const SizedBox(height: 10),
          FinanzasCard(
            onTap: () => context.push('/config/recordatorios'),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.alarm_rounded, color: cs.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Programar recordatorio',
                          style: tt.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text('Avisos puntuales para fechas de pago',
                          style: tt.bodySmall),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: cs.primary.withValues(alpha: 0.5), size: 20),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _SectionLabel('PRUEBA', tt),
          const SizedBox(height: 10),
          FinanzasCard(
            child: Column(
              children: [
                _TestRow(
                  icon: Icons.cloud_outlined,
                  color: const Color(0xFF8B5CF6),
                  title: 'Probar: sin cuenta Google',
                  cs: cs,
                  tt: tt,
                  onTap: () async {
                    await NotificationService().checkAndNotifyGoogleAccount();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notificación enviada (si no tienes sesión)'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                _Divider(),
                _TestRow(
                  icon: Icons.receipt_long_outlined,
                  color: const Color(0xFFF59E0B),
                  title: 'Probar: sin gastos este mes',
                  cs: cs,
                  tt: tt,
                  onTap: () async {
                    await NotificationService().checkAndNotifyNoGastosThisMonth();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notificación enviada (si no tienes gastos)'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final TextTheme tt;
  const _SectionLabel(this.label, this.tt);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: tt.labelSmall?.copyWith(
          color: Colors.white.withValues(alpha: 0.4),
          letterSpacing: 1.4,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _NotifRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final Widget trailing;
  const _NotifRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: tt.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: tt.bodySmall?.copyWith(fontSize: 12)),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  final ColorScheme cs;
  const _ActiveBadge({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'ON',
        style: TextStyle(
            color: cs.primary, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _TestRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final ColorScheme cs;
  final TextTheme tt;
  final VoidCallback onTap;
  const _TestRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.cs,
    required this.tt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title,
                style: tt.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          Icon(Icons.send_rounded, color: cs.primary.withValues(alpha: 0.5), size: 16),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
    );
  }
}
