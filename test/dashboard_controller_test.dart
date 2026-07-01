import 'package:company_dashboard/models/campaign.dart';
import 'package:company_dashboard/models/company_admin.dart';
import 'package:company_dashboard/repositories/analytics_repository.dart';
import 'package:company_dashboard/repositories/auth_repository.dart';
import 'package:company_dashboard/repositories/campaign_repository.dart';
import 'package:company_dashboard/repositories/local_storage.dart';
import 'package:company_dashboard/state/dashboard_controller.dart';
import 'package:flutter_test/flutter_test.dart';

DashboardController _buildController() {
  final storage = LocalStorage();
  return DashboardController(
    campaignRepository: CampaignRepository(storage),
    analyticsRepository: AnalyticsRepository(),
    authRepository: AuthRepository(storage),
    admin: const CompanyAdmin(
      id: 'admin-demo',
      name: 'Demo Admin',
      email: 'admin@mintflow.app',
      companyName: 'Demo Brand',
    ),
  );
}

Campaign _sampleCampaign(String id) {
  final now = DateTime(2026, 7, 1);
  return Campaign(
    id: id,
    name: 'New launch $id',
    description: 'A fresh campaign.',
    youtubeUrl: 'https://youtu.be/M7lc1UVf-VE',
    youtubeVideoId: 'M7lc1UVf-VE',
    budget: 5000,
    rewardPerCompletion: 2,
    startDate: now,
    endDate: now.add(const Duration(days: 14)),
    status: CampaignStatus.active,
    interactions: const [
      CampaignInteraction(
        type: InteractionType.poll,
        question: 'Which do you prefer?',
        options: ['A', 'B'],
      ),
    ],
    views: 0,
    completions: 0,
    createdAt: now,
  );
}

void main() {
  test('controller loads seeded campaigns and computes metrics', () async {
    final controller = _buildController();
    await controller.load();

    expect(controller.isLoading, false);
    expect(controller.campaigns, isNotEmpty);
    expect(controller.metrics.length, 4);
    expect(controller.completionTrend, isNotEmpty);
  });

  test('create then delete campaign updates the list', () async {
    final controller = _buildController();
    await controller.load();
    final initial = controller.campaigns.length;

    await controller.createCampaign(_sampleCampaign('campaign-new'));
    expect(controller.campaigns.length, initial + 1);

    await controller.deleteCampaign('campaign-new');
    expect(controller.campaigns.length, initial);
  });

  test('status filter and search narrow the campaign list', () async {
    final controller = _buildController();
    await controller.load();

    controller.setStatusFilter(CampaignStatus.draft);
    expect(
      controller.filteredCampaigns.every((c) => c.status == CampaignStatus.draft),
      true,
    );

    controller.setStatusFilter(null);
    controller.setSearch('sneaker');
    expect(
      controller.filteredCampaigns.every(
        (c) => c.name.toLowerCase().contains('sneaker'),
      ),
      true,
    );
  });

  test('duplicate creates a draft copy', () async {
    final controller = _buildController();
    await controller.load();
    final source = controller.campaigns.first;

    await controller.duplicateCampaign(source.id);
    final copy = controller.campaigns.firstWhere(
      (c) => c.name.contains('(copy)'),
    );
    expect(copy.status, CampaignStatus.draft);
    expect(copy.completions, 0);
  });
}
