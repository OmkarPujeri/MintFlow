import 'package:flutter/material.dart';

import '../theme.dart';

/// Animates a numeric value counting up from zero on first build.
///
/// Accepts a raw string like `"Rs. 1.2k"`, `"78%"` or `"12"`, extracts the
/// leading number, animates it, and rebuilds the original prefix/suffix around
/// the tweened value so formatting is preserved.
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  final String value;
  final TextStyle style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    // Match a real number (must start with a digit) so prefixes like "Rs."
    // are not accidentally parsed via their dot.
    final match = RegExp(r'\d+(?:\.\d+)?').firstMatch(value);
    if (match == null) {
      return Text(value, style: style);
    }
    final matched = match.group(0)!;
    final number = double.tryParse(matched) ?? 0;
    final prefix = value.substring(0, match.start);
    final suffix = value.substring(match.end);
    final decimals = matched.contains('.') ? 1 : 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: number),
      duration: duration,
      curve: AppMotion.curve,
      builder: (context, animated, _) {
        return Text(
          '$prefix${animated.toStringAsFixed(decimals)}$suffix',
          style: style,
        );
      },
    );
  }
}
