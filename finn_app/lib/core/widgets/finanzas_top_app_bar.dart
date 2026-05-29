import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FinanzasTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? subtitle;
  final VoidCallback? onAdd;

  const FinanzasTopAppBar({
    super.key,
    this.subtitle,
    this.onAdd,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final tt = Theme.of(ctx).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        leading: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 0, 8),
          child: Container(
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.account_circle_rounded,
                color: cs.primary, size: 28),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Finn',
              style: tt.headlineSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: tt.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          if (onAdd != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.add_rounded, color: cs.primary, size: 22),
                  onPressed: onAdd,
                  tooltip: 'Agregar',
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Badge(
                backgroundColor: cs.error,
                smallSize: 8,
                child: Icon(Icons.notifications_rounded,
                    color: Colors.white.withValues(alpha: 0.7), size: 22),
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
