import 'package:flutter/material.dart';

import '../theme.dart';
import 'count_up_text.dart';
import 'section_card.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.delta,
    this.positive = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final String delta;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final deltaColor = positive ? AppColors.mintDark : AppColors.amber;
    return SectionCard(
      hoverable: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.mint.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 18),
          CountUpText(
            value: value,
            style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 28) ??
                const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                positive ? Icons.trending_up : Icons.info_outline,
                size: 15,
                color: deltaColor,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  delta,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: deltaColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
