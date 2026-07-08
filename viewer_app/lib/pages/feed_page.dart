import 'package:flutter/material.dart';

import '../models/campaign.dart';
import '../state/viewer_controller.dart';
import '../theme.dart';
import '../widgets/mint_coin.dart';

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
                color: AppColors.mintBright,
                backgroundColor: AppColors.panelAlt,
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
        icon: Icons.wifi_off_rounded,
        title: c.feedError!,
        subtitle: 'Pull to refresh, or try again.',
        actionLabel: 'Retry',
        onAction: c.loadFeed,
      );
    }
    final items = c.feedCampaigns;
    if (items.isEmpty) {
      return const _Message(
        icon: Icons.inbox_rounded,
        title: 'No campaigns right now',
        subtitle: 'New ways to earn appear here — check back soon.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
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
      padding: const EdgeInsets.fromLTRB(20, 6, 12, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Earn by watching',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mintBright,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3)),
              if (count > 0)
                Text('$count campaign${count == 1 ? '' : 's'} available',
                    style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const Spacer(),
          PopupMenuButton<FeedSort>(
            initialValue: controller.sort,
            onSelected: controller.setSort,
            position: PopupMenuPosition.under,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.panelAlt,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sort_rounded, size: 16, color: AppColors.mintBright),
                  const SizedBox(width: 6),
                  Text(controller.sort.label,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600)),
                  const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.muted),
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

/// Card with a subtle press-scale so tapping feels tactile.
class _CampaignCard extends StatefulWidget {
  const _CampaignCard({required this.campaign, required this.onTap});

  final Campaign campaign;
  final VoidCallback onTap;

  @override
  State<_CampaignCard> createState() => _CampaignCardState();
}

class _CampaignCardState extends State<_CampaignCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final campaign = widget.campaign;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.98 : 1,
        duration: AppMotion.fast,
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.only(top: 14),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.lineSoft),
            boxShadow: AppShadows.card,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(videoId: campaign.youtubeVideoId, boosted: campaign.isBoosted),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                            const SizedBox(height: 3),
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
                    const SizedBox(width: 14),
                    _Payout(coins: campaign.rewardPerCompletion),
                  ],
                ),
              ),
            ],
          ),
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
          // bottom scrim so the play cue and badges stay legible over any frame
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x88000000)],
                stops: [0.55, 1.0],
              ),
            ),
          ),
          // play affordance
          const Center(
            child: _PlayCue(),
          ),
          if (boosted)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.amberSoft,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(color: AppColors.amber.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 14, color: AppColors.amber),
                    SizedBox(width: 3),
                    Text('Boosted',
                        style: TextStyle(
                            color: AppColors.amber,
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayCue extends StatelessWidget {
  const _PlayCue();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.5),
      ),
      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
    );
  }
}

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.brandGradient),
    );
  }
}

class _Payout extends StatelessWidget {
  const _Payout({required this.coins});

  final double coins;

  @override
  Widget build(BuildContext context) {
    final value =
        coins % 1 == 0 ? coins.toInt().toString() : coins.toStringAsFixed(1);
    return Column(
      children: [
        MintCoin(size: 48, value: value),
        const SizedBox(height: 5),
        const Text('coins',
            style: TextStyle(
                color: AppColors.mintBright,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3)),
      ],
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
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
        Container(
          width: 84,
          height: 84,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.panel,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.line),
          ),
          child: Icon(icon, size: 38, color: AppColors.faint),
        ),
        const SizedBox(height: 18),
        Text(title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
        if (actionLabel != null) ...[
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ),
        ],
      ],
    );
  }
}
