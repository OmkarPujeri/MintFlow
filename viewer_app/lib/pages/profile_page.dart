import 'package:flutter/material.dart';

import '../state/viewer_controller.dart';
import '../theme.dart';
import '../widgets/mint_coin.dart';

/// Viewer profile: the balance hero (Mint Coins) plus streak / tickets / wallet
/// and logout. Hierarchy is deliberate — coins are the product, so they get the
/// hero; everything else is a secondary chip.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.controller});

  final ViewerController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final v = controller.viewer;
        return RefreshIndicator(
          onRefresh: controller.refresh,
          color: AppColors.mintBright,
          backgroundColor: AppColors.panelAlt,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _Identity(email: v?.email ?? '—'),
              const SizedBox(height: 22),
              _BalanceHero(
                coins: v?.mintCoins ?? 0,
                walletInr: v?.walletBalanceInr ?? 0,
                earnedToday: v?.coinsEarnedToday ?? 0,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatChip(
                    icon: Icons.local_fire_department_rounded,
                    tint: AppColors.amber,
                    value: '${v?.dailyStreak ?? 0}',
                    label: 'Day streak',
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    icon: Icons.confirmation_number_rounded,
                    tint: AppColors.mintBright,
                    value: '${v?.raffleTickets ?? 0}',
                    label: 'Raffle tickets',
                  ),
                ],
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: controller.logout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(color: AppColors.line),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Log out'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.panelAlt,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.line),
          ),
          child: Text(initial,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.mintBright)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Signed in as',
                  style: Theme.of(context).textTheme.bodySmall),
              Text(email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}

/// The one bold thing on the screen: your Mint Coin balance, glowing.
class _BalanceHero extends StatelessWidget {
  const _BalanceHero({
    required this.coins,
    required this.walletInr,
    required this.earnedToday,
  });

  final int coins;
  final double walletInr;
  final int earnedToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF17271F), Color(0xFF11201A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.mint.withValues(alpha: 0.3)),
        boxShadow: AppShadows.glow(0.16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MintCoin(size: 58),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mint Coins',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.mintBright,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4)),
                    const SizedBox(height: 2),
                    CoinCountUp(
                      value: coins,
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge!
                          .copyWith(fontSize: 38),
                    ),
                  ],
                ),
              ),
              if (earnedToday > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.mintSoft,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text('+$earnedToday today',
                      style: const TextStyle(
                          color: AppColors.mintBright,
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: AppColors.line, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  size: 18, color: AppColors.muted),
              const SizedBox(width: 8),
              Text('Wallet value',
                  style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              Text('₹${walletInr.toStringAsFixed(2)}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.ink)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.tint,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color tint;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.lineSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: tint, size: 22),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
