import 'package:flutter/material.dart';

import '../theme.dart';

/// The base surface used across the dashboard. Optionally reacts to hover
/// with a subtle lift so cards feel interactive on web.
class SectionCard extends StatefulWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.hoverable = false,
    this.onTap,
    this.accent = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool hoverable;
  final VoidCallback? onTap;
  final bool accent;

  @override
  State<SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<SectionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final lifted = widget.hoverable && _hovered;
    final card = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.curve,
      padding: widget.padding,
      transform: lifted
          ? (Matrix4.identity()..setTranslationRaw(0, -3, 0))
          : Matrix4.identity(),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(
          color: lifted ? AppColors.mint.withValues(alpha: 0.5) : AppColors.line,
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: lifted ? AppShadows.lifted : AppShadows.card,
      ),
      child: widget.child,
    );

    if (!widget.hoverable && widget.onTap == null) return card;

    return MouseRegion(
      cursor:
          widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(onTap: widget.onTap, child: card),
    );
  }
}
