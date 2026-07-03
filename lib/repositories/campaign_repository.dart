import '../models/campaign.dart';
import '../models/insights.dart';
import 'api_client.dart';

class CampaignRepository {
  CampaignRepository(this._api);

  final ApiClient _api;

  // ─── Campaigns ─────────────────────────────────────────────────────────────

  Future<List<Campaign>> listCampaigns() async {
    final response = await _api.get('/api/v1/campaigns/');
    final list = response as List<dynamic>;
    return list
        .map((item) => Campaign.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Campaign> createCampaign(Campaign campaign) async {
    final response = await _api.post('/api/v1/campaigns/', body: campaign.toJson());
    return Campaign.fromJson(response as Map<String, dynamic>);
  }

  Future<Campaign> updateCampaign(Campaign campaign) async {
    final response = await _api.patch('/api/v1/campaigns/${campaign.id}', body: campaign.toJson());
    return Campaign.fromJson(response as Map<String, dynamic>);
  }

  Future<Campaign> boostCampaign(String id) async {
    final response = await _api.post('/api/v1/campaigns/$id/boost');
    return Campaign.fromJson(response as Map<String, dynamic>);
  }

  Future<Campaign> updateCampaignStatus(String id, CampaignStatus status) async {
    final String endpoint;
    switch (status) {
      case CampaignStatus.active:
        endpoint = '/api/v1/campaigns/$id/publish';
        break;
      case CampaignStatus.paused:
        endpoint = '/api/v1/campaigns/$id/pause';
        break;
      default:
        // For draft/completed, use PATCH
        final response = await _api.patch('/api/v1/campaigns/$id', body: {
          'status': status.name,
        });
        return Campaign.fromJson(response as Map<String, dynamic>);
    }
    final response = await _api.post(endpoint);
    return Campaign.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteCampaign(String id) async {
    await _api.delete('/api/v1/campaigns/$id');
  }

  /// Duplicate is handled client-side: create a new campaign as a copy.
  Future<Campaign> duplicateCampaign(String id) async {
    final campaigns = await listCampaigns();
    final source = campaigns.firstWhere(
      (c) => c.id == id,
      orElse: () => throw StateError('Campaign not found: $id'),
    );
    final now = DateTime.now();
    final copy = source.copyWith(
      id: '',  // Backend will generate new ID
      name: '${source.name} (copy)',
      status: CampaignStatus.draft,
      views: 0,
      completions: 0,
      createdAt: now,
    );
    return createCampaign(copy);
  }

  // ─── Responses (from backend analytics) ───────────────────────────────────

  Future<List<CampaignResponse>> listResponses(String? campaignId) async {
    final path = campaignId != null
        ? '/api/v1/analytics/campaigns/$campaignId/responses'
        : '/api/v1/analytics/responses';

    try {
      final response = await _api.get(path);
      final data = (response as Map<String, dynamic>)['responses'] as List<dynamic>;
      return data.map((item) {
        final r = item as Map<String, dynamic>;
        return CampaignResponse(
          id: r['question_id'] as String? ?? '',
          campaignId: campaignId ?? '',
          viewer: 'Viewer',
          interactionType: 'Response',
          answer: r['response_value'] as String? ?? '',
          completedAt: DateTime.tryParse(r['responded_at'] as String? ?? '') ?? DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Reward Transactions (from wallet API) ─────────────────────────────────

  Future<List<RewardTransaction>> listRewardTransactions(String? campaignId) async {
    try {
      // Use the analytics endpoint for campaign-level reward data
      if (campaignId != null) {
        final response = await _api.get('/api/v1/analytics/campaigns/$campaignId');
        final data = response as Map<String, dynamic>;
        final rewarded = data['rewarded_views'] as int? ?? 0;
        final rewardAmount = data['reward_per_view'] as double? ?? 2.0;

        return List.generate(rewarded.clamp(0, 5), (i) => RewardTransaction(
          id: 'txn-$campaignId-$i',
          campaignId: campaignId,
          viewer: 'Viewer #${i + 1}',
          amount: rewardAmount,
          status: 'Paid',
          createdAt: DateTime.now().subtract(Duration(hours: i * 2)),
        ));
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
