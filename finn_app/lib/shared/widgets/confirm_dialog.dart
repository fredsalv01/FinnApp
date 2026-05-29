import 'package:flutter/material.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Eliminar',
  String cancelText = 'Cancelar',
  bool destructive = true,
}) async {
  final cs = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (dialogCtx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, false),
          child: Text(cancelText),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: cs.error)
              : null,
          onPressed: () => Navigator.pop(dialogCtx, true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return result ?? false;
}
