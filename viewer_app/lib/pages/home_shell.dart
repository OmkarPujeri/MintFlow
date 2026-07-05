import 'package:flutter/material.dart';

import '../state/viewer_controller.dart';
import '../theme.dart';
import 'profile_page.dart';

/// Signed-in home: bottom nav across Feed / Wallet / Profile. Feed and Wallet
/// are placeholders until Phases 2 and 6 build them out.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final ViewerController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _titles = ['Feed', 'Wallet', 'Profile'];

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _ComingSoon(title: 'Feed', icon: Icons.play_circle_outline, phase: 'Phase 2'),
      const _ComingSoon(title: 'Wallet', icon: Icons.account_balance_wallet_outlined, phase: 'Phase 6'),
      ProfilePage(controller: widget.controller),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        backgroundColor: AppColors.panel,
        elevation: 0,
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.play_circle_outline), selectedIcon: Icon(Icons.play_circle), label: 'Feed'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title, required this.icon, required this.phase});

  final String title;
  final IconData icon;
  final String phase;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.faint),
          const SizedBox(height: 12),
          Text('$title coming soon', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Built in $phase', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
