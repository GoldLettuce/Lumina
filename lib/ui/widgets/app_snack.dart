import 'package:flutter/material.dart';

enum AppSnackKind { info, success, error }

void showAppSnack(
  BuildContext context, {
  required String message,
  AppSnackKind kind = AppSnackKind.info,
  Duration duration = const Duration(seconds: 2),
}) {
  final scheme = Theme.of(context).colorScheme;

  // Colores derivados del tema activo
  late final Color bg;
  late final Color fg;

  switch (kind) {
    case AppSnackKind.error:
      bg = scheme.surfaceContainerHighest;
      fg = scheme.onSurfaceVariant;
      break;
    case AppSnackKind.success:
      bg = scheme.secondaryContainer;
      fg = scheme.onSecondaryContainer;
      break;
    case AppSnackKind.info:
      bg = scheme.surfaceContainerHighest;
      fg = scheme.onSurface;
      break;
  }

  final snack = SnackBar(
    behavior: SnackBarBehavior.floating,
    duration: duration,
    elevation: 0,
    backgroundColor: bg,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    showCloseIcon: false,
    content: Text(message, style: TextStyle(color: fg)),
  );

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snack);
}
