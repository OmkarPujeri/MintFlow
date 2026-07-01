import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme.dart';

/// Consistent title + subtitle header used at the top of every section, with
/// an optional trailing action (e.g. a "New campaign" button).
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 14.5),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 16),
          trailing!,
        ],
      ],
    ).animate().fadeIn(duration: AppMotion.medium).moveY(
          begin: -8,
          end: 0,
          curve: AppMotion.curve,
        );
  }
}

/// Wraps page content in a staggered fade/slide-in reveal.
class RevealColumn extends StatelessWidget {
  const RevealColumn({super.key, required this.children, this.interval = 70});

  final List<Widget> children;
  final int interval;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++)
          children[i]
              .animate()
              .fadeIn(
                delay: (interval * i).ms,
                duration: AppMotion.medium,
              )
              .moveY(begin: 14, end: 0, curve: AppMotion.curve),
      ],
    );
  }
}
