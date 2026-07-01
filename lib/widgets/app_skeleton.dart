import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme.dart';
import 'section_card.dart';

/// A shimmering placeholder block.
class Skeleton extends StatelessWidget {
  const Skeleton({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.lineSoft,
        borderRadius: BorderRadius.circular(radius),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1100.ms,
          color: Colors.white.withValues(alpha: 0.6),
        );
  }
}

/// Full-page skeleton shown while the dashboard loads.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Skeleton(width: 220, height: 26),
        const SizedBox(height: 10),
        const Skeleton(width: 340, height: 14),
        const SizedBox(height: 26),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = (constraints.maxWidth / 260).floor().clamp(1, 4);
            final width =
                (constraints.maxWidth - (columns - 1) * 16) / columns;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: List.generate(
                4,
                (_) => SizedBox(
                  width: width,
                  child: const SectionCard(
                    padding: EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Skeleton(width: 90, height: 12),
                        SizedBox(height: 18),
                        Skeleton(width: 70, height: 24),
                        SizedBox(height: 10),
                        Skeleton(width: 110, height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        const SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton(width: 160, height: 18),
              SizedBox(height: 20),
              Skeleton(height: 12),
              SizedBox(height: 14),
              Skeleton(height: 12),
              SizedBox(height: 14),
              Skeleton(width: 240, height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
