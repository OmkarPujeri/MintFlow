import 'package:flutter/material.dart';

import '../theme.dart';

/// The app's signature element: a minted green coin. A radial mint gradient
/// with a bevelled highlight and a soft outer glow — used as every payout badge
/// and as the balance hero. Optionally stamps a [value] on its face.
class MintCoin extends StatelessWidget {
  const MintCoin({super.key, this.size = 44, this.value, this.glow = true});

  final double size;

  /// If set, rendered centered on the coin face (e.g. the payout amount).
  final String? value;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.coinGradient,
        border: Border.all(color: AppColors.mintGlow.withValues(alpha: 0.55), width: size * 0.03),
        boxShadow: glow ? AppShadows.glow(0.34) : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // bevel highlight — a soft top-left sheen
          Positioned(
            top: size * 0.12,
            left: size * 0.14,
            child: Container(
              width: size * 0.4,
              height: size * 0.28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0.0)],
                ),
              ),
            ),
          ),
          if (value != null)
            Text(
              value!,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.42,
                letterSpacing: -0.5,
                shadows: const [Shadow(color: Color(0x55003D26), blurRadius: 4)],
              ),
            )
          else
            Icon(Icons.eco_rounded, color: Colors.white.withValues(alpha: 0.92), size: size * 0.5),
        ],
      ),
    );
  }
}

/// An integer that counts up when it first appears / changes — the small bit of
/// motion that makes a reward balance feel earned. Groups thousands with commas.
class CoinCountUp extends StatelessWidget {
  const CoinCountUp({super.key, required this.value, required this.style, this.duration});

  final int value;
  final TextStyle style;
  final Duration? duration;

  static String _grouped(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration ?? AppMotion.slow,
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text(_grouped(v.round()), style: style),
    );
  }
}
