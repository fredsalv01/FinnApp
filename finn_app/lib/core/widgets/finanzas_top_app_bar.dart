import 'package:flutter/material.dart';

class FinanzasTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? subtitle;
  const FinanzasTopAppBar({super.key, this.subtitle});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final tt = Theme.of(ctx).textTheme;
    return AppBar(
      backgroundColor: cs.surface,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: cs.primaryContainer.withValues(alpha: 0.3),
          child: Icon(Icons.person, color: cs.primary, size: 20),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FinanzasApp',
              style: tt.headlineMedium?.copyWith(color: cs.primary)),
          if (subtitle != null)
            Text(subtitle!, style: tt.bodySmall),
        ],
      ),
      actions: [
        IconButton(
          icon: Badge(
            backgroundColor: cs.error,
            child: Icon(Icons.notifications_outlined, color: cs.onSurface),
          ),
          onPressed: () {},
        ),
      ],
    );
  }
}
