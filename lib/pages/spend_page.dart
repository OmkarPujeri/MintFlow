import 'package:flutter/material.dart';

import '../formatters.dart';
import '../models/insights.dart';
import '../state/dashboard_controller.dart';
import '../theme.dart';
import '../widgets/charts/trend_area_chart.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';

class SpendPage extends StatelessWidget {
  const SpendPage({super.key, required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final transactions = controller.transactions;
    final spend = controller.spend;

    if (controller.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Spend',
            subtitle: 'Track campaign budgets and reward transaction flow.',
          ),
          SizedBox(height: 40),
          EmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'No spend yet',
            message: 'Budget and reward transactions appear here once campaigns run.',
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Spend',
          subtitle: 'Track campaign budgets and reward transaction flow.',
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 900;
            final health = _BudgetHealthCard(spend: spend);
            final trend = _SpendTrendCard(points: controller.spendTrend);
            if (!wide) {
              return Column(
                children: [health, const SizedBox(height: 18), trend],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 360, child: health),
                const SizedBox(width: 18),
                Expanded(child: trend),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        _TransactionsCard(transactions: transactions),
      ],
    );
  }
}

class _BudgetHealthCard extends StatelessWidget {
  const _BudgetHealthCard({required this.spend});

  final SpendSummary spend;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget Health', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          _BudgetLine(label: 'Allocated', value: formatCurrency(spend.allocated)),
          _BudgetLine(label: 'Spent', value: formatCurrency(spend.spent)),
          _BudgetLine(
            label: 'Remaining',
            value: formatCurrency(spend.remaining),
            highlight: true,
          ),
          const SizedBox(height: 18),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: spend.progress),
            duration: AppMotion.slow,
            curve: AppMotion.curve,
            builder: (context, value, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 10,
                    color: value > 0.9 ? AppColors.amber : AppColors.mint,
                    backgroundColor: AppColors.mintSoft,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(value * 100).round()}% of total budget used',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendTrendCard extends StatelessWidget {
  const _SpendTrendCard({required this.points});

  final List<TimeSeriesPoint> points;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spend Trend', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text(
            'Reward payouts flowing out over the last 14 days.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          TrendAreaChart(points: points, height: 220),
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
            'Reward Transactions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No transactions yet.',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 420,
                ),
                child: DataTable(
                  columnSpacing: 30,
                  horizontalMargin: 0,
                  columns: const [
                    DataColumn(label: Text('Viewer')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Date')),
                  ],
                  rows: [
                    for (final transaction in transactions) _row(transaction),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  DataRow _row(RewardTransaction transaction) {
    final paid = transaction.status == 'Paid';
    return DataRow(
      cells: [
        DataCell(Text(transaction.viewer)),
        DataCell(
          Text(
            formatCurrency(transaction.amount),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: paid ? AppColors.mintSoft : AppColors.amberSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              transaction.status,
              style: TextStyle(
                color: paid ? AppColors.mintDark : AppColors.amber,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(Text(formatDate(transaction.createdAt))),
      ],
    );
  }
}

class _BudgetLine extends StatelessWidget {
  const _BudgetLine({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: highlight ? AppColors.mintDark : AppColors.ink,
              fontSize: highlight ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
