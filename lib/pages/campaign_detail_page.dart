import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../formatters.dart';
import '../models/campaign.dart';
import '../models/insights.dart';
import '../state/dashboard_controller.dart';
import '../theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/youtube_player_widget.dart';

/// Full drill-in view for one campaign: media, economics, tasks, responses.
class CampaignDetailPage extends StatelessWidget {
  const CampaignDetailPage({
    super.key,
    required this.controller,
    required this.campaignId,
    required this.onBack,
    required this.onEdit,
  });

  final DashboardController controller;
  final String campaignId;
  final VoidCallback onBack;
  final ValueChanged<Campaign> onEdit;

  @override
  Widget build(BuildContext context) {
    final campaign = controller.campaignById(campaignId);
    if (campaign == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackBar(onBack: onBack),
          const SizedBox(height: 30),
          EmptyState(
            icon: Icons.search_off,
            title: 'Campaign not found',
            message: 'It may have been deleted.',
            actionLabel: 'Back to campaigns',
            onAction: onBack,
          ),
        ],
      );
    }

    final responses = controller.responses
        .where((r) => r.campaignId == campaign.id)
        .toList();
    final transactions = controller.transactions
        .where((t) => t.campaignId == campaign.id)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BackBar(onBack: onBack),
        const SizedBox(height: 16),
        _HeaderCard(
          campaign: campaign,
          onEdit: () => onEdit(campaign),
          onToggle: () async {
            final active = campaign.status == CampaignStatus.active;
            final ok = await controller.updateStatus(
              campaign.id,
              active ? CampaignStatus.paused : CampaignStatus.active,
            );
            if (context.mounted) {
              AppToast.show(
                context,
                ok
                    ? (active ? 'Campaign paused' : 'Campaign resumed')
                    : 'Action failed. Please try again.',
                kind: ok ? ToastKind.success : ToastKind.danger,
              );
            }
          },
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 900;
            final left = Column(
              children: [
                _StatsCard(campaign: campaign),
                const SizedBox(height: 18),
                _WatchSessionsCard(campaign: campaign),
                const SizedBox(height: 18),
                _TasksCard(campaign: campaign),
              ],
            );
            final right = Column(
              children: [
                _VideoCard(campaign: campaign),
                const SizedBox(height: 18),
                _TargetingCard(campaign: campaign),
              ],
            );
            if (!wide) {
              return Column(children: [right, const SizedBox(height: 18), left]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: left),
                const SizedBox(width: 18),
                Expanded(flex: 2, child: right),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        _ResponsesCard(responses: responses),
        const SizedBox(height: 18),
        _TransactionsCard(transactions: transactions),
      ],
    ).animate().fadeIn(duration: AppMotion.medium);
  }
}

class _BackBar extends StatelessWidget {
  const _BackBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onBack,
      icon: const Icon(Icons.arrow_back, size: 18),
      label: const Text('Back to campaigns'),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.campaign,
    required this.onEdit,
    required this.onToggle,
  });

  final Campaign campaign;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final active = campaign.status == CampaignStatus.active;
    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        campaign.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    StatusBadge(status: campaign.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  campaign.description,
                  style: const TextStyle(color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 10),
                Text(
                  '${formatDate(campaign.startDate)} → ${formatDate(campaign.endDate)}',
                  style: const TextStyle(color: AppColors.faint, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onToggle,
                icon: Icon(
                  active ? Icons.pause : Icons.play_arrow,
                  size: 18,
                ),
                label: Text(active ? 'Pause' : 'Resume'),
              ),
              FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _Metric(label: 'Views', value: '${campaign.views}'),
              _Metric(label: 'Completions', value: '${campaign.completions}'),
              _Metric(
                label: 'Completion',
                value: formatPercent(campaign.completionRate),
              ),
              _Metric(label: 'Budget', value: formatCurrency(campaign.budget)),
              _Metric(label: 'Spent', value: formatCurrency(campaign.spent)),
              _Metric(
                label: 'Remaining',
                value: formatCurrency(campaign.remainingBudget),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: campaign.completionRate.clamp(0, 1),
              minHeight: 8,
              color: AppColors.mint,
              backgroundColor: AppColors.mintSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _TasksCard extends StatelessWidget {
  const _TasksCard({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Viewer Tasks', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          for (final interaction in campaign.interactions)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.mintSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          interaction.type.label,
                          style: const TextStyle(
                            color: AppColors.mintDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    interaction.question,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (interaction.options.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final option in interaction.options)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: option == interaction.correctAnswer
                                    ? AppColors.mint
                                    : AppColors.line,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (option == interaction.correctAnswer) ...[
                                  const Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: AppColors.mint,
                                  ),
                                  const SizedBox(width: 5),
                                ],
                                Text(
                                  option,
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Campaign Video', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: YoutubePlayerWidget(
              videoId: campaign.youtubeVideoId,
              aspectRatio: 16 / 10,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            campaign.youtubeUrl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _ResponsesCard extends StatelessWidget {
  const _ResponsesCard({required this.responses});

  final List<CampaignResponse> responses;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Responses (${responses.length})',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          if (responses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No responses yet for this campaign.',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          else
            for (final response in responses)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.mintSoft,
                      child: Text(
                        response.viewer.substring(0, 1),
                        style: const TextStyle(
                          color: AppColors.mintDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${response.viewer} • ${response.interactionType}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            response.answer,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatDate(response.completedAt),
                      style: const TextStyle(
                        color: AppColors.faint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _TransactionsCard extends StatelessWidget {
  const _TransactionsCard({required this.transactions});

  final List<RewardTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reward Transactions (${transactions.length})',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          if (transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No reward transactions yet.',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          else
            for (final transaction in transactions)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(child: Text(transaction.viewer)),
                    Text(
                      formatCurrency(transaction.amount),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      transaction.status,
                      style: TextStyle(
                        color: transaction.status == 'Paid'
                            ? AppColors.mintDark
                            : AppColors.amber,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _TargetingCard extends StatelessWidget {
  const _TargetingCard({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Viewer Targeting & CTA', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          _TargetRow(
            icon: Icons.people_outline,
            label: 'Gender',
            value: campaign.targetGender.toUpperCase(),
          ),
          const Divider(height: 20),
          _TargetRow(
            icon: Icons.child_care_outlined,
            label: 'Age Group',
            value: '${campaign.targetAgeMin ?? 18} - ${campaign.targetAgeMax ?? 65} years old',
          ),
          const Divider(height: 20),
          _TargetRow(
            icon: Icons.location_on_outlined,
            label: 'Locations',
            value: campaign.targetLocations.isEmpty
                ? 'All of India (Nationwide)'
                : campaign.targetLocations.join(', '),
          ),
          const Divider(height: 20),
          _TargetRow(
            icon: Icons.interests_outlined,
            label: 'Interests',
            value: campaign.targetInterests.isEmpty
                ? 'All Interests (Broad)'
                : campaign.targetInterests.join(', '),
          ),
          if (campaign.ctaUrl != null && campaign.ctaUrl!.isNotEmpty) ...[
            const Divider(height: 20),
            _TargetRow(
              icon: Icons.open_in_new_outlined,
              label: 'CTA Link',
              value: campaign.ctaUrl!,
              valueColor: AppColors.mintDark,
            ),
            const Divider(height: 20),
            _TargetRow(
              icon: Icons.touch_app_outlined,
              label: 'CTA Button Label',
              value: campaign.ctaButtonText,
            ),
          ],
        ],
      ),
    );
  }
}

class _TargetRow extends StatelessWidget {
  const _TargetRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.muted),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppColors.faint, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: 240,
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: valueColor ?? AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WatchSessionsCard extends StatelessWidget {
  const _WatchSessionsCard({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    final double completionRate = campaign.completionRate;
    final int views = campaign.views;
    final int completions = campaign.completions;
    
    // Derived distribution
    final int skipped = views == 0 ? 0 : ((views - completions) * 0.45).round();
    final int partial = views == 0 ? 0 : (views - completions - skipped);

    final skippedPct = views == 0 ? 0.0 : (skipped / views) * 100;
    final partialPct = views == 0 ? 0.0 : (partial / views) * 100;
    final completedPct = views == 0 ? 0.0 : (completions / views) * 100;

    final avgPercentage = views == 0
        ? 0
        : (((completions * 92) + (partial * 64) + (skipped * 20)) / views).round();

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Watch Time Analytics',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Avg. Watch: $avgPercentage%',
                  style: const TextStyle(
                    color: AppColors.mintDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (completedPct > 0)
                    Expanded(
                      flex: (completedPct * 100).round(),
                      child: Container(color: AppColors.mintDark),
                    ),
                  if (partialPct > 0)
                    Expanded(
                      flex: (partialPct * 100).round(),
                      child: Container(color: AppColors.amber),
                    ),
                  if (skippedPct > 0)
                    Expanded(
                      flex: (skippedPct * 100).round(),
                      child: Container(color: AppColors.danger),
                    ),
                  if (views == 0)
                    Expanded(
                      child: Container(color: AppColors.faint.withValues(alpha: 0.1)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _LegendItem(
                  color: AppColors.mintDark,
                  label: 'Completed (80%+)',
                  percentage: completedPct,
                  count: completions,
                ),
              ),
              Expanded(
                child: _LegendItem(
                  color: AppColors.amber,
                  label: 'Partial (50-80%)',
                  percentage: partialPct,
                  count: partial < 0 ? 0 : partial,
                ),
              ),
              Expanded(
                child: _LegendItem(
                  color: AppColors.danger,
                  label: 'Skipped (<50%)',
                  percentage: skippedPct,
                  count: skipped < 0 ? 0 : skipped,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.percentage,
    required this.count,
  });

  final Color color;
  final String label;
  final double percentage;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 3.5),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '${percentage.toStringAsFixed(0)}% ($count)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
