import 'package:flutter_test/flutter_test.dart';
import 'package:company_dashboard/models/campaign.dart';

void main() {
  test('campaign JSON round trip preserves reward economics', () {
    final now = DateTime(2026, 7, 1);
    final campaign = Campaign(
      id: 'campaign-test',
      name: 'Test campaign',
      description: 'A campaign used for model verification.',
      youtubeUrl: 'https://www.youtube.com/watch?v=M7lc1UVf-VE',
      youtubeVideoId: 'M7lc1UVf-VE',
      budget: 1000,
      rewardPerCompletion: 2,
      startDate: now,
      endDate: now.add(const Duration(days: 7)),
      status: CampaignStatus.active,
      interactions: const [
        CampaignInteraction(
          type: InteractionType.quiz,
          question: 'What was shown?',
          options: ['Product', 'Logo'],
          correctAnswer: 'Product',
        ),
      ],
      views: 100,
      completions: 80,
      createdAt: now,
    );

    final restored = Campaign.fromJson(campaign.toJson());

    expect(restored.name, 'Test campaign');
    expect(restored.youtubeVideoId, 'M7lc1UVf-VE');
    expect(restored.spent, 160);
    expect(restored.remainingBudget, 840);
    expect(restored.completionRate, 0.8);
  });

  test('extracts video IDs from common YouTube URL formats', () {
    expect(
      extractYouTubeVideoId('https://www.youtube.com/watch?v=M7lc1UVf-VE'),
      'M7lc1UVf-VE',
    );
    expect(extractYouTubeVideoId('https://youtu.be/M7lc1UVf-VE'), 'M7lc1UVf-VE');
    expect(
      extractYouTubeVideoId('https://www.youtube.com/embed/M7lc1UVf-VE'),
      'M7lc1UVf-VE',
    );
    expect(
      extractYouTubeVideoId('https://www.youtube.com/shorts/M7lc1UVf-VE'),
      'M7lc1UVf-VE',
    );
  });
}
