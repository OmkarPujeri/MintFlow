import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/campaign.dart';
import '../theme.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';

class InteractionsPage extends StatelessWidget {
  const InteractionsPage({super.key, required this.campaigns});

  final List<Campaign> campaigns;

  @override
  Widget build(BuildContext context) {
    final counts = {
      for (final type in InteractionType.values)
        type: campaigns
            .where((c) => c.interactions.any((item) => item.type == type))
            .length,
    };

    const cards = [
      _InteractionMeta(
        type: InteractionType.quiz,
        icon: Icons.quiz_outlined,
        color: AppColors.mint,
        description: 'Correct-answer tasks for attention verification.',
      ),
      _InteractionMeta(
        type: InteractionType.survey,
        icon: Icons.assignment_outlined,
        color: AppColors.blue,
        description: 'Structured consumer insight questions.',
      ),
      _InteractionMeta(
        type: InteractionType.poll,
        icon: Icons.poll_outlined,
        color: AppColors.amber,
        description: 'Fast preference selection after video viewing.',
      ),
      _InteractionMeta(
        type: InteractionType.feedback,
        icon: Icons.rate_review_outlined,
        color: Color(0xFF7D8BF0),
        description: 'Open text or rating response collection.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Interactions',
          subtitle:
              'Design the tasks viewers complete after watching a campaign video.',
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = (constraints.maxWidth / 260).floor().clamp(1, 4);
            final width =
                (constraints.maxWidth - (columns - 1) * 16) / columns;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (var i = 0; i < cards.length; i++)
                  SizedBox(
                    width: width,
                    child: _InteractionCard(
                      meta: cards[i],
                      count: counts[cards[i].type] ?? 0,
                    )
                        .animate()
                        .fadeIn(delay: (80 * i).ms, duration: AppMotion.medium)
                        .moveY(begin: 16, end: 0, curve: AppMotion.curve),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reward Rules',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              const Text(
                'How each task type qualifies a viewer for a reward.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 18),
              const _Rule(
                label: 'Quiz',
                text: 'Reward requires the correct answer.',
              ),
              const _Rule(
                label: 'Survey',
                text: 'Reward is granted after all questions are completed.',
              ),
              const _Rule(
                label: 'Poll',
                text: 'Reward is granted after one option is selected.',
              ),
              const _Rule(
                label: 'Feedback',
                text: 'Reward is granted after a non-empty response.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InteractionMeta {
  const _InteractionMeta({
    required this.type,
    required this.icon,
    required this.color,
    required this.description,
  });

  final InteractionType type;
  final IconData icon;
  final Color color;
  final String description;
}

class _InteractionCard extends StatelessWidget {
  const _InteractionCard({required this.meta, required this.count});

  final _InteractionMeta meta;
  final int count;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      hoverable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(meta.icon, color: meta.color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(meta.type.label, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            meta.description,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Text(
            '$count ${count == 1 ? 'campaign' : 'campaigns'}',
            style: TextStyle(color: meta.color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
