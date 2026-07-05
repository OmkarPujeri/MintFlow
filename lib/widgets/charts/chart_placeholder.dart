import 'package:flutter/material.dart';

import '../../theme.dart';

/// Lightweight "no data yet" state for charts whose values are all zero.
/// Keeps the card the same height so the layout doesn't jump.
class ChartPlaceholder extends StatelessWidget {
  const ChartPlaceholder({
    super.key,
    required this.icon,
    required this.message,
    this.height = 200,
  });

  final IconData icon;
  final String message;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: AppColors.faint),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
