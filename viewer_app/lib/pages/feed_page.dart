import 'package:flutter/material.dart';

import '../models/campaign.dart';
import '../state/viewer_controller.dart';
import '../theme.dart';

/// Discover: all active campaigns from every company, as a scrollable card
/// list, sortable by payout or newest. Tapping a campaign starts the watch
/// flow (built in Phase 3).
class FeedPage extends StatefulWidget {
  const FeedPage({super.key, required this.controller});

  final ViewerController controller;

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  @override
  void initState() {
    super.initState();
    // Load once when the tab first mounts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.feedCampaigns.isEmpty) widget.controller.loadFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        return Column(
          children: [
            _SortBar(controller: c),
            Expanded(
              child: RefreshIndicator(
                onRefresh: c.loadFeed,
                child: _body(context, c),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _body(BuildContext context, ViewerController c) {
    if (c.feedLoading && c.feedCampaigns.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (c.feedError != null && c.feedCampaigns.isEmpty) {
      return _Message(
        icon: Icons.wifi_off,
        title: c.feedError!,
        actionLabel: 'Retry',
        onAction: c.loadFeed,
      );
    }
    final items = c.feedCampaigns;
    if (items.isEmpty) {
      return const _Message(
        icon: Icons.inbox_outlined,
        title: 'No campaigns right now',
        subtitle: 'Check back soon — new campaigns appear here.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, i) => _CampaignCard(
        campaign: items[i],
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Watch flow arrives in Phase 3')),
        ),
      ),
    );
  }
}

class _SortBar extends StatelessWidget {
  const _SortBar({required this.controller});

  final ViewerController controller;

  @override
  Widget build(BuildContext context) {
    final count = controller.feedCampaigns.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 10, 6),
      child: Row(
        children: [
          if (count > 0)
            Text(
              '$count campaign${count == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const Spacer(),
          PopupMenuButton<FeedSort>(
            initialValue: controller.sort,
            onSelected: controller.setSort,
            position: PopupMenuPosition.under,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.line),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sort, size: 16, color: AppColors.mintDark),
                  const SizedBox(width: 6),
                  Text(controller.sort.label,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.ink)),
                  const Icon(Icons.arrow_drop_down, size: 20, color: AppColors.muted),
                ],
              ),
            ),
            itemBuilder: (context) => FeedSort.values
                .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({required this.campaign, required this.onTap});

  final Campaign campaign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumbnail(videoId: campaign.youtubeVideoId, boosted: campaign.isBoosted),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campaign.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (campaign.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            campaign.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _PayoutBadge(coins: campaign.rewardPerCompletion),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.videoId, required this.boosted});

  final String videoId;
  final bool boosted;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (videoId.isNotEmpty)
            Image.network(
              'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _ThumbFallback(),
            )
          else
            const _ThumbFallback(),
          if (boosted)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 13, color: AppColors.amber),
                    SizedBox(width: 4),
                    Text('Boosted',
                        style: TextStyle(color: Colors.white, fontSize: 11)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: const Center(
        child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 48),
      ),
    );
  }
}

class _PayoutBadge extends StatelessWidget {
  const _PayoutBadge({required this.coins});

  final double coins;

  @override
  Widget build(BuildContext context) {
    final value = coins % 1 == 0 ? coins.toInt().toString() : coins.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.mintSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: AppColors.mintDeep,
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
          const Text('coins',
              style: TextStyle(color: AppColors.mintDark, fontSize: 10.5)),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    // ListView so RefreshIndicator still works when the list is empty.
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Icon(icon, size: 52, color: AppColors.faint),
        const SizedBox(height: 12),
        Text(title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
        ],
        if (actionLabel != null) ...[
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ),
        ],
      ],
    );
  }
}
