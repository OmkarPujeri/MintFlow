import 'dart:convert';

import 'package:company_dashboard/models/campaign.dart';
import 'package:company_dashboard/models/company_admin.dart';
import 'package:company_dashboard/repositories/analytics_repository.dart';
import 'package:company_dashboard/repositories/api_client.dart';
import 'package:company_dashboard/repositories/auth_repository.dart';
import 'package:company_dashboard/repositories/campaign_repository.dart';
import 'package:company_dashboard/repositories/local_storage.dart';
import 'package:company_dashboard/state/dashboard_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Fake HTTP layer: serves a fixed campaign list on GET /campaigns/, and lets
/// the analytics/wallet endpoints fail (the repository swallows those to []).
/// Round-trips real Campaign objects through toJson so the fixture can't drift
/// from the parser.
class _FakeClient extends http.BaseClient {
  _FakeClient(this._campaigns);
  final List<Campaign> _campaigns;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final isCampaignList =
        request.method == 'GET' && request.url.path == '/api/v1/campaigns/';
    final body = isCampaignList
        ? jsonEncode(_campaigns.map((c) => c.toJson()).toList())
        : '{}';
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      isCampaignList ? 200 : 404,
      headers: {'content-type': 'application/json'},
    );
  }
}

Campaign _campaign(String id, String name, CampaignStatus status) {
  final now = DateTime(2026, 7, 1);
  return Campaign(
    id: id,
    name: name,
    description: 'A campaign.',
    youtubeUrl: 'https://youtu.be/M7lc1UVf-VE',
    youtubeVideoId: 'M7lc1UVf-VE',
    budget: 5000,
    rewardPerCompletion: 2,
    startDate: now,
    endDate: now.add(const Duration(days: 14)),
    status: status,
    interactions: const [],
    views: 0,
    completions: 0,
    createdAt: now,
  );
}

DashboardController _buildController(List<Campaign> campaigns) {
  final storage = LocalStorage();
  final api = ApiClient(storage, client: _FakeClient(campaigns));
  return DashboardController(
    campaignRepository: CampaignRepository(api),
    analyticsRepository: AnalyticsRepository(),
    authRepository: AuthRepository(storage, api),
    admin: const CompanyAdmin(
      id: 'admin-demo',
      name: 'Demo Admin',
      email: 'admin@mintflow.app',
      companyName: 'Demo Brand',
    ),
  );
}

void main() {
  final sample = [
    _campaign('c1', 'Sneaker launch', CampaignStatus.active),
    _campaign('c2', 'Coffee promo', CampaignStatus.draft),
  ];

  test('load() pulls campaigns from the API and computes metrics', () async {
    final controller = _buildController(sample);
    await controller.load();

    expect(controller.isLoading, false);
    expect(controller.hasError, false);
    expect(controller.campaigns, hasLength(2));
    expect(controller.metrics, hasLength(4));
  });

  test('status filter narrows the campaign list', () async {
    final controller = _buildController(sample);
    await controller.load();

    controller.setStatusFilter(CampaignStatus.draft);
    expect(
      controller.filteredCampaigns.every((c) => c.status == CampaignStatus.draft),
      true,
    );
    expect(controller.filteredCampaigns, hasLength(1));
  });

  test('search narrows the campaign list by name', () async {
    final controller = _buildController(sample);
    await controller.load();

    controller.setStatusFilter(null);
    controller.setSearch('sneaker');
    expect(controller.filteredCampaigns, hasLength(1));
    expect(controller.filteredCampaigns.single.name, 'Sneaker launch');
  });
}
