import 'package:flutter/material.dart';

import '../theme.dart';

enum ToastKind { success, info, danger }

/// Themed snackbar helper for action feedback.
class AppToast {
  static void show(
    BuildContext context,
    String message, {
    ToastKind kind = ToastKind.success,
  }) {
    final (Color bg, IconData icon) = switch (kind) {
      ToastKind.success => (AppColors.mintDark, Icons.check_circle_outline),
      ToastKind.info => (AppColors.blue, Icons.info_outline),
      ToastKind.danger => (AppColors.danger, Icons.error_outline),
    };

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          backgroundColor: bg,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
