import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../formatters.dart';
import '../models/campaign.dart';
import '../models/insights.dart';
import '../state/dashboard_controller.dart';
import '../theme.dart';
import '../widgets/charts/donut_chart.dart';
import '../widgets/charts/mini_bar_chart.dart';
import '../widgets/charts/trend_area_chart.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_badge.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({
    super.key,
    required this.controller,
    required this.onCreate,
    required this.onViewCampaigns,
  });

  final DashboardController controller;
  final VoidCallback onCreate;
  final VoidCallback onViewCampaigns;

  static const _icons = [
    Icons.campaign_outlined,
    Icons.verified_outlined,
    Icons.payments_outlined,
    Icons.trending_up,
  ];

  @override
  Widget build(BuildContext context) {
    if (controller.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Hello, ${controller.admin.name == "Company Admin" ? controller.admin.companyName : controller.admin.name.split(" ").first}',
            subtitle: 'Track campaign progress, completions, and reward spend.',
          ),
          const SizedBox(height: 40),
          EmptyState(
            icon: Icons.rocket_launch_outlined,
            title: 'No campaigns yet',
            message:
                'Create your first campaign to start collecting verified attention and see analytics here.',
            actionLabel: 'Create campaign',
            onAction: onCreate,
          ),
        ],
      );
    }

    final metrics = controller.metrics;
    final campaigns = controller.campaigns;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Hello, ${controller.admin.name == "Company Admin" ? controller.admin.companyName : controller.admin.name.split(" ").first}',
          subtitle:
              'Track campaign progress, verified completion, and reward spend.',
          trailing: FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New campaign'),
          ),
        ),
        const SizedBox(height: 24),
        _MetricsGrid(metrics: metrics, icons: _icons),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 900;
            final trend = _TrendCard(points: controller.completionTrend);
            final mix = _MixCard(mix: controller.interactionMix);
            if (!wide) {
              return Column(
                children: [
                  trend,
                  const SizedBox(height: 18),
                  mix,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: trend),
                const SizedBox(width: 18),
                Expanded(flex: 2, child: mix),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 900;
            final performance = _PerformanceCard(
              campaigns: campaigns,
              onViewAll: onViewCampaigns,
            );
            final spend = _SpendBarCard(campaigns: campaigns);
            if (!wide) {
              return Column(
                children: [
                  performance,
                  const SizedBox(height: 18),
                  spend,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: performance),
                const SizedBox(width: 18),
                Expanded(flex: 2, child: spend),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.metrics, required this.icons});

  final List<DashboardMetric> metrics;
  final List<IconData> icons;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 250).floor().clamp(1, 4);
        final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (var i = 0; i < metrics.length; i++)
              SizedBox(
                width: width,
                child: StatCard(
                  icon: icons[i % icons.length],
                  label: metrics[i].label,
                  value: metrics[i].value,
                  delta: metrics[i].delta,
                  positive: metrics[i].positive,
                )
                    .animate()
                    .fadeIn(delay: (90 * i).ms, duration: AppMotion.medium)
                    .moveY(begin: 16, end: 0, curve: AppMotion.curve),
              ),
          ],
        );
      },
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.points});

  final List<TimeSeriesPoint> points;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Completion Trend',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const _LegendDot(label: 'Rewarded views'),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Verified completions over the last 14 days.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          TrendAreaChart(points: points),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
            color: AppColors.mint,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class _MixCard extends StatelessWidget {
  const _MixCard({required this.mix});

  final Map<InteractionType, int> mix;

  @override
  Widget build(BuildContext context) {
    final slices = <DonutSlice>[
      for (var i = 0; i < InteractionType.values.length; i++)
        DonutSlice(
          label: InteractionType.values[i].label,
          value: mix[InteractionType.values[i]] ?? 0,
          color: AppColors.chart[i % AppColors.chart.length],
        ),
    ];
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interaction Mix',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          const Text(
            'Task types across your campaigns.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Center(
              child: DonutChart(slices: slices, centerLabel: 'Tasks'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendBarCard extends StatelessWidget {
  const _SpendBarCard({required this.campaigns});

  final List<Campaign> campaigns;

  @override
  Widget build(BuildContext context) {
    final data = campaigns
        .take(6)
        .map((c) => BarDatum(label: c.name, value: c.spent))
        .toList();
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spend by Campaign',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          const Text(
            'Reward spend per active campaign.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          MiniBarChart(data: data),
        ],
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({required this.campaigns, required this.onViewAll});

  final List<Campaign> campaigns;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Campaign Performance',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(onPressed: onViewAll, child: const Text('View all')),
            ],
          ),
          const SizedBox(height: 12),
          for (final campaign in campaigns.take(4)) ...[
            _PerformanceRow(campaign: campaign),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${campaign.completions} completions • ${formatCurrency(campaign.spent)} spent',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            StatusBadge(status: campaign.status),
          ],
        ),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: campaign.completionRate.clamp(0, 1)),
          duration: AppMotion.slow,
          curve: AppMotion.curve,
          builder: (context, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              color: AppColors.mint,
              backgroundColor: AppColors.mintSoft,
            ),
          ),
        ),
      ],
    );
  }
}
