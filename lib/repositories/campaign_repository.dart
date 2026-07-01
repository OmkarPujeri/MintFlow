import 'dart:convert';

import '../models/campaign.dart';
import '../models/insights.dart';
import 'local_storage.dart';

class CampaignRepository {
  CampaignRepository(this._storage);

  static const _campaignsKey = 'mintflow.company_dashboard.campaigns';

  final LocalStorage _storage;

  Future<List<Campaign>> listCampaigns() async {
    final raw = _storage.read(_campaignsKey);
    if (raw == null) {
      await _seedCampaigns();
      return listCampaigns();
    }
    final json = jsonDecode(raw) as List<dynamic>;
    return json
        .map((item) => Campaign.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Campaign> createCampaign(Campaign campaign) async {
    final campaigns = await listCampaigns();
    campaigns.insert(0, campaign);
    await _save(campaigns);
    return campaign;
  }

  Future<Campaign> updateCampaign(Campaign campaign) async {
    final campaigns = await listCampaigns();
    final index = campaigns.indexWhere((item) => item.id == campaign.id);
    if (index == -1) throw StateError('Campaign not found: ${campaign.id}');
    campaigns[index] = campaign;
    await _save(campaigns);
    return campaign;
  }

  Future<Campaign> updateCampaignStatus(
    String id,
    CampaignStatus status,
  ) async {
    final campaigns = await listCampaigns();
    final index = campaigns.indexWhere((campaign) => campaign.id == id);
    if (index == -1) throw StateError('Campaign not found: $id');
    final updated = campaigns[index].copyWith(status: status);
    campaigns[index] = updated;
    await _save(campaigns);
    return updated;
  }

  Future<void> deleteCampaign(String id) async {
    final campaigns = await listCampaigns();
    campaigns.removeWhere((campaign) => campaign.id == id);
    await _save(campaigns);
  }

  Future<Campaign> duplicateCampaign(String id) async {
    final campaigns = await listCampaigns();
    final source = campaigns.firstWhere(
      (campaign) => campaign.id == id,
      orElse: () => throw StateError('Campaign not found: $id'),
    );
    final now = DateTime.now();
    final copy = source.copyWith(
      id: 'campaign-${now.microsecondsSinceEpoch}',
      name: '${source.name} (copy)',
      status: CampaignStatus.draft,
      views: 0,
      completions: 0,
      createdAt: now,
    );
    campaigns.insert(0, copy);
    await _save(campaigns);
    return copy;
  }

  static const _viewerNames = [
    'Aarav S.',
    'Meera K.',
    'Rohan P.',
    'Diya M.',
    'Kabir N.',
    'Ananya R.',
    'Vivaan T.',
    'Ishita B.',
  ];

  Future<List<CampaignResponse>> listResponses(String? campaignId) async {
    final campaigns = await listCampaigns();
    final now = DateTime.now();
    final responses = <CampaignResponse>[];
    var globalIndex = 0;

    for (final campaign in campaigns) {
      if (campaign.completions == 0) continue;
      final interaction = campaign.interactions.first;
      // Two illustrative responses per campaign with real answer values.
      final samples = interaction.options.isNotEmpty
          ? interaction.options.take(2).toList()
          : ['Shorter intro, clearer pricing', 'Loved the product demo'];
      for (var i = 0; i < samples.length; i++) {
        responses.add(
          CampaignResponse(
            id: 'response-${campaign.id}-$i',
            campaignId: campaign.id,
            viewer: _viewerNames[globalIndex % _viewerNames.length],
            interactionType: interaction.type.label,
            answer: samples[i],
            completedAt: now.subtract(Duration(hours: globalIndex * 3 + i)),
          ),
        );
        globalIndex++;
      }
    }

    responses.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    if (campaignId == null) return responses;
    return responses.where((item) => item.campaignId == campaignId).toList();
  }

  Future<List<RewardTransaction>> listRewardTransactions(
    String? campaignId,
  ) async {
    final campaigns = await listCampaigns();
    final now = DateTime.now();
    final transactions = <RewardTransaction>[];
    var index = 0;
    for (final campaign in campaigns) {
      if (campaign.completions == 0) continue;
      final count = campaign.status == CampaignStatus.active ? 2 : 1;
      for (var i = 0; i < count; i++) {
        transactions.add(
          RewardTransaction(
            id: 'txn-${campaign.id}-$i',
            campaignId: campaign.id,
            viewer: _viewerNames[index % _viewerNames.length],
            amount: campaign.rewardPerCompletion,
            status: campaign.status == CampaignStatus.active ? 'Paid' : 'Queued',
            createdAt: now.subtract(Duration(hours: index * 2 + i)),
          ),
        );
        index++;
      }
    }
    transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (campaignId == null) return transactions;
    return transactions.where((item) => item.campaignId == campaignId).toList();
  }

  Future<void> _seedCampaigns() async {
    final now = DateTime.now();
    final campaigns = [
      Campaign(
        id: 'campaign-1',
        name: 'Summer sneaker launch',
        description: 'Introduce cushioned everyday sneakers to urban viewers.',
        youtubeUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        youtubeVideoId: 'dQw4w9WgXcQ',
        budget: 10000,
        rewardPerCompletion: 2,
        startDate: now,
        endDate: now.add(const Duration(days: 21)),
        status: CampaignStatus.active,
        interactions: [
          const CampaignInteraction(
            type: InteractionType.quiz,
            question: 'Which feature was highlighted in the sneaker video?',
            options: ['Cushioned sole', 'Leather bag', 'Smart watch'],
            correctAnswer: 'Cushioned sole',
          ),
        ],
        views: 920,
        completions: 620,
        createdAt: now.subtract(const Duration(days: 6)),
      ),
      Campaign(
        id: 'campaign-2',
        name: 'Energy drink taste test',
        description: 'Collect package preference for a new drink flavor.',
        youtubeUrl: 'https://youtu.be/M7lc1UVf-VE',
        youtubeVideoId: 'M7lc1UVf-VE',
        budget: 6000,
        rewardPerCompletion: 2,
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 14)),
        status: CampaignStatus.active,
        interactions: [
          const CampaignInteraction(
            type: InteractionType.poll,
            question: 'Which packaging would you pick first?',
            options: ['Mango', 'Berry', 'Lime'],
          ),
        ],
        views: 550,
        completions: 438,
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      Campaign(
        id: 'campaign-3',
        name: 'App onboarding feedback',
        description: 'Understand where users drop in a new app walkthrough.',
        youtubeUrl: 'https://www.youtube.com/embed/bHQqvYy5KYo',
        youtubeVideoId: 'bHQqvYy5KYo',
        budget: 3000,
        rewardPerCompletion: 3,
        startDate: now.add(const Duration(days: 2)),
        endDate: now.add(const Duration(days: 18)),
        status: CampaignStatus.draft,
        interactions: [
          const CampaignInteraction(
            type: InteractionType.feedback,
            question: 'What would make this onboarding easier to understand?',
            options: [],
          ),
        ],
        views: 240,
        completions: 190,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];
    await _save(campaigns);
  }

  Future<void> _save(List<Campaign> campaigns) async {
    _storage.write(
      _campaignsKey,
      jsonEncode(campaigns.map((campaign) => campaign.toJson()).toList()),
    );
  }
}
