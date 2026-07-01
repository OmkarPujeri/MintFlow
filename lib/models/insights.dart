class CampaignResponse {
  const CampaignResponse({
    required this.id,
    required this.campaignId,
    required this.viewer,
    required this.interactionType,
    required this.answer,
    required this.completedAt,
  });

  final String id;
  final String campaignId;
  final String viewer;
  final String interactionType;
  final String answer;
  final DateTime completedAt;
}

class RewardTransaction {
  const RewardTransaction({
    required this.id,
    required this.campaignId,
    required this.viewer,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String campaignId;
  final String viewer;
  final double amount;
  final String status;
  final DateTime createdAt;
}

class DashboardMetric {
  const DashboardMetric({
    required this.label,
    required this.value,
    required this.delta,
    this.positive = true,
  });

  final String label;
  final String value;
  final String delta;

  /// Whether the delta represents an improvement (drives colour/arrow).
  final bool positive;
}

/// A single point in a time-series (used for the overview trend charts).
class TimeSeriesPoint {
  const TimeSeriesPoint({
    required this.date,
    required this.value,
  });

  final DateTime date;
  final double value;
}

/// Aggregated numbers describing spend across all campaigns.
class SpendSummary {
  const SpendSummary({
    required this.allocated,
    required this.spent,
  });

  final double allocated;
  final double spent;

  double get remaining => (allocated - spent).clamp(0, allocated).toDouble();
  double get progress => allocated == 0 ? 0 : (spent / allocated).clamp(0, 1);
}
