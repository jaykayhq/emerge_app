import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

enum ToastType { success, error, info }

class AppToast {
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
  }) {
    final theme = Theme.of(context);
    Color backgroundColor;
    IconData icon;

    switch (type) {
      case ToastType.success:
        backgroundColor = AppTheme.primary;
        icon = Icons.check_circle_outline;
        break;
      case ToastType.error:
        backgroundColor = theme.colorScheme.error;
        icon = Icons.error_outline;
        break;
      case ToastType.info:
        backgroundColor = AppTheme.secondary;
        icon = Icons.info_outline;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
