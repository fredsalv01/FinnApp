import 'package:flutter/material.dart';

class FinanzasCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;

  const FinanzasCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D1B2A).withValues(alpha: 0.05),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
