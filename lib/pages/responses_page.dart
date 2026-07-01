import 'package:flutter/material.dart';

import '../formatters.dart';
import '../models/campaign.dart';
import '../models/insights.dart';
import '../state/dashboard_controller.dart';
import '../theme.dart';
import '../widgets/charts/donut_chart.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';

class ResponsesPage extends StatelessWidget {
  const ResponsesPage({super.key, required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final responses = controller.responses;

    String campaignName(String id) =>
        controller.campaignById(id)?.name ?? 'Unknown campaign';

    if (responses.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Responses',
            subtitle:
                'Review viewer answers from quizzes, surveys, polls, and feedback.',
          ),
          SizedBox(height: 40),
          EmptyState(
            icon: Icons.forum_outlined,
            title: 'No responses yet',
            message:
                'Once viewers complete campaign tasks, their answers will appear here.',
          ),
        ],
      );
    }

    // Count responses per interaction type for the donut.
    final typeCounts = <String, int>{};
    for (final r in responses) {
      typeCounts[r.interactionType] = (typeCounts[r.interactionType] ?? 0) + 1;
    }
    final slices = <DonutSlice>[
      for (var i = 0; i < InteractionType.values.length; i++)
        DonutSlice(
          label: InteractionType.values[i].label,
          value: typeCounts[InteractionType.values[i].label] ?? 0,
          color: AppColors.chart[i % AppColors.chart.length],
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Responses',
          subtitle:
              'Review viewer answers from quizzes, surveys, polls, and feedback.',
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 860;
            final summary = SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Response Mix',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 18),
                  DonutChart(slices: slices, centerLabel: 'Replies'),
                ],
              ),
            );
            final table = _ResponsesTable(
              responses: responses,
              campaignName: campaignName,
            );
            if (!wide) {
              return Column(
                children: [summary, const SizedBox(height: 18), table],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 300, child: summary),
                const SizedBox(width: 18),
                Expanded(child: table),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ResponsesTable extends StatelessWidget {
  const _ResponsesTable({required this.responses, required this.campaignName});

  final List<CampaignResponse> responses;
  final String Function(String id) campaignName;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 420,
          ),
          child: DataTable(
            columnSpacing: 26,
            horizontalMargin: 16,
            columns: const [
              DataColumn(label: Text('Viewer')),
              DataColumn(label: Text('Campaign')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Answer')),
              DataColumn(label: Text('Completed')),
            ],
            rows: [
              for (final response in responses) _row(response),
            ],
          ),
        ),
      ),
    );
  }

  DataRow _row(CampaignResponse response) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 13,
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
              const SizedBox(width: 10),
              Text(
                response.viewer,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        DataCell(Text(campaignName(response.campaignId))),
        DataCell(Text(response.interactionType)),
        DataCell(SizedBox(width: 260, child: Text(response.answer))),
        DataCell(Text(formatDate(response.completedAt))),
      ],
    );
  }
}
