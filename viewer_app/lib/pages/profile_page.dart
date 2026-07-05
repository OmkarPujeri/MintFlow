import 'package:flutter/material.dart';

import '../state/viewer_controller.dart';
import '../theme.dart';

/// Viewer profile: gamification stats from /me + logout. Wallet transactions
/// get their own tab in a later phase.
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
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 12),
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.mintSoft,
                child: const Icon(Icons.person, size: 38, color: AppColors.mintDark),
              ),
              const SizedBox(height: 12),
              Text(
                v?.email ?? '—',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _Stat(label: 'Mint Coins', value: '${v?.mintCoins ?? 0}', icon: Icons.toll),
                  const SizedBox(width: 12),
                  _Stat(label: 'Day Streak', value: '${v?.dailyStreak ?? 0}', icon: Icons.local_fire_department),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Stat(label: 'Raffle Tickets', value: '${v?.raffleTickets ?? 0}', icon: Icons.confirmation_number),
                  const SizedBox(width: 12),
                  _Stat(
                    label: 'Wallet (₹)',
                    value: (v?.walletBalanceInr ?? 0).toStringAsFixed(2),
                    icon: Icons.account_balance_wallet,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text('Earned today: ${v?.coinsEarnedToday ?? 0} coins',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: controller.logout,
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(AppRadii.card),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.mint, size: 22),
            const SizedBox(height: 10),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
