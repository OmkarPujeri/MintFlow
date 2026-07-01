import '../models/campaign.dart';
import '../models/insights.dart';

/// Derives dashboard analytics from the current campaign set.
///
/// Everything here is computed from real campaign data so the numbers stay
/// consistent as the admin creates, edits, and pauses campaigns. When a real
/// backend arrives, these methods can be swapped for API calls without the UI
/// changing shape.
class AnalyticsRepository {
  Future<List<DashboardMetric>> getDashboardMetrics(
    List<Campaign> campaigns,
  ) async {
    final totalCampaigns = campaigns.length;
    final activeCampaigns =
        campaigns.where((c) => c.status == CampaignStatus.active).length;
    final rewardedViews =
        campaigns.fold<int>(0, (sum, c) => sum + c.completions);
    final totalSpend = campaigns.fold<double>(0, (sum, c) => sum + c.spent);
    final totalBudget = campaigns.fold<double>(0, (sum, c) => sum + c.budget);
    final totalViews = campaigns.fold<int>(0, (sum, c) => sum + c.views);
    final completionRate =
        totalViews == 0 ? 0 : (rewardedViews / totalViews * 100).round();
    final budgetUsed =
        totalBudget == 0 ? 0 : (totalSpend / totalBudget * 100).round();

    return [
      DashboardMetric(
        label: 'Total Campaigns',
        value: '$totalCampaigns',
        delta: '$activeCampaigns active now',
      ),
      DashboardMetric(
        label: 'Rewarded Views',
        value: _compact(rewardedViews),
        delta: '$totalViews total views',
      ),
      DashboardMetric(
        label: 'Total Spend',
        value: 'Rs. ${_compact(totalSpend.round())}',
        delta: '$budgetUsed% of budget used',
        positive: budgetUsed < 90,
      ),
      DashboardMetric(
        label: 'Completion Rate',
        value: '$completionRate%',
        delta: completionRate >= 60 ? 'Healthy engagement' : 'Needs a lift',
        positive: completionRate >= 60,
      ),
    ];
  }

  /// Daily rewarded-view trend for the last [days] days.
  ///
  /// Because the MVP has no event log yet, the curve is shaped
  /// deterministically from each campaign's completion total and age so it
  /// looks realistic and stays stable between rebuilds.
  Future<List<TimeSeriesPoint>> getCompletionTrend(
    List<Campaign> campaigns, {
    int days = 14,
  }) async {
    final today = DateTime.now();
    final totalCompletions =
        campaigns.fold<int>(0, (sum, c) => sum + c.completions);
    final base = totalCompletions == 0 ? 0.0 : totalCompletions / days;

    return List.generate(days, (i) {
      final date = today.subtract(Duration(days: days - 1 - i));
      // Gentle wave + upward drift, seeded by the day index (no randomness).
      final wave = 0.72 + 0.28 * _pseudo(i);
      final drift = 0.75 + (i / days) * 0.5;
      return TimeSeriesPoint(date: date, value: base * wave * drift);
    });
  }

  /// Count of campaigns per interaction type (for the donut chart).
  Future<Map<InteractionType, int>> getInteractionMix(
    List<Campaign> campaigns,
  ) async {
    final mix = {for (final type in InteractionType.values) type: 0};
    for (final campaign in campaigns) {
      for (final interaction in campaign.interactions) {
        mix[interaction.type] = (mix[interaction.type] ?? 0) + 1;
      }
    }
    return mix;
  }

  Future<SpendSummary> getSpendSummary(List<Campaign> campaigns) async {
    return SpendSummary(
      allocated: campaigns.fold<double>(0, (sum, c) => sum + c.budget),
      spent: campaigns.fold<double>(0, (sum, c) => sum + c.spent),
    );
  }

  /// Deterministic 0..1 pseudo value so charts are stable across rebuilds.
  double _pseudo(int seed) {
    final x = (seed * 928371 + 12345) % 1000;
    return x / 1000;
  }

  String _compact(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return '$value';
  }
}
