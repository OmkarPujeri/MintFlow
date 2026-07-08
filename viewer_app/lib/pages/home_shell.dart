import 'package:flutter/material.dart';

import '../state/viewer_controller.dart';
import '../theme.dart';
import '../widgets/mint_coin.dart';
import 'feed_page.dart';
import 'profile_page.dart';

/// Signed-in home: bottom nav across Discover / Wallet / Profile. A live coin
/// balance sits in the app bar so earnings are visible from any tab.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final ViewerController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _titles = ['Discover', 'Wallet', 'Profile'];

  @override
  Widget build(BuildContext context) {
    final pages = [
      FeedPage(controller: widget.controller),
      const _ComingSoon(title: 'Wallet', phase: 'Phase 6'),
      ProfilePage(controller: widget.controller),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index],
            style: Theme.of(context).textTheme.headlineMedium),
        toolbarHeight: 64,
        actions: [
          _BalanceChip(controller: widget.controller),
          const SizedBox(width: 16),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore_rounded),
              label: 'Discover'),
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Wallet'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile'),
        ],
      ),
    );
  }
}

/// Coin balance pill in the app bar — earnings visible from every tab.
class _BalanceChip extends StatelessWidget {
  const _BalanceChip({required this.controller});

  final ViewerController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final coins = controller.viewer?.mintCoins ?? 0;
        return Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
          decoration: BoxDecoration(
            color: AppColors.panelAlt,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MintCoin(size: 26, glow: false),
              const SizedBox(width: 8),
              CoinCountUp(
                value: coins,
                duration: AppMotion.medium,
                style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 15),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title, required this.phase});

  final String title;
  final String phase;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(opacity: 0.45, child: const MintCoin(size: 72)),
          const SizedBox(height: 20),
          Text('$title coming soon',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Cash out your Mint Coins here — arriving in $phase.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
