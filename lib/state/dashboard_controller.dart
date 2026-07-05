import 'package:flutter/foundation.dart';

import '../models/campaign.dart';
import '../models/company_admin.dart';
import '../models/insights.dart';
import '../repositories/analytics_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/campaign_repository.dart';
import '../repositories/api_client.dart';

/// Sort options for the campaigns table.
enum CampaignSort { newest, name, budget, completion }

/// Single reactive source of truth for the dashboard.
///
/// Wraps the repositories and exposes the loaded data plus UI state
/// (search / filters). Widgets rebuild via [ListenableBuilder]. All mutations
/// go through the repositories so the backend boundary stays intact.
class DashboardController extends ChangeNotifier {
  DashboardController({
    required CampaignRepository campaignRepository,
    required AnalyticsRepository analyticsRepository,
    required AuthRepository authRepository,
    required CompanyAdmin admin,
  })  : _campaigns = campaignRepository,
        _analytics = analyticsRepository,
        _auth = authRepository,
        _admin = admin;

  final CampaignRepository _campaigns;
  final AnalyticsRepository _analytics;
  final AuthRepository _auth;

  CompanyAdmin _admin;
  CompanyAdmin get admin => _admin;

  bool _loading = true;
  bool get isLoading => _loading;

  String? _error;
  String? get error => _error;
  bool get hasError => _error != null;

  List<Campaign> _allCampaigns = [];
  List<CampaignResponse> _responses = [];
  List<RewardTransaction> _transactions = [];
  List<DashboardMetric> _metrics = [];
  List<TimeSeriesPoint> _completionTrend = [];
  List<TimeSeriesPoint> _spendTrend = [];
  Map<InteractionType, int> _interactionMix = {};
  SpendSummary _spend = const SpendSummary(allocated: 0, spent: 0);

  String _search = '';
  CampaignStatus? _statusFilter;
  CampaignSort _sort = CampaignSort.newest;
  bool _sortAscending = false;

  // ---- Getters -------------------------------------------------------------

  List<Campaign> get campaigns => _allCampaigns;
  List<CampaignResponse> get responses => _responses;
  List<RewardTransaction> get transactions => _transactions;
  List<DashboardMetric> get metrics => _metrics;
  List<TimeSeriesPoint> get completionTrend => _completionTrend;
  List<TimeSeriesPoint> get spendTrend => _spendTrend;
  Map<InteractionType, int> get interactionMix => _interactionMix;
  SpendSummary get spend => _spend;
  String get search => _search;
  CampaignStatus? get statusFilter => _statusFilter;
  CampaignSort get sort => _sort;
  bool get sortAscending => _sortAscending;
  bool get isEmpty => _allCampaigns.isEmpty;

  /// Campaigns filtered by the active search query + status chip, then sorted.
  List<Campaign> get filteredCampaigns {
    final query = _search.trim().toLowerCase();
    final list = _allCampaigns.where((c) {
      final matchesStatus = _statusFilter == null || c.status == _statusFilter;
      final matchesQuery = query.isEmpty ||
          c.name.toLowerCase().contains(query) ||
          c.description.toLowerCase().contains(query);
      return matchesStatus && matchesQuery;
    }).toList();

    int compare(Campaign a, Campaign b) {
      switch (_sort) {
        case CampaignSort.newest:
          return a.createdAt.compareTo(b.createdAt);
        case CampaignSort.name:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case CampaignSort.budget:
          return a.budget.compareTo(b.budget);
        case CampaignSort.completion:
          return a.completionRate.compareTo(b.completionRate);
      }
    }

    list.sort((a, b) => _sortAscending ? compare(a, b) : -compare(a, b));
    return list;
  }

  // ---- Loading -------------------------------------------------------------

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _refreshData();
    } catch (e) {
      _error = _describe(e);
    }
    _loading = false;
    notifyListeners();
  }

  /// Retry after a failed load (used by the error state's retry button).
  Future<void> retry() => load();

  String _describe(Object error) {
    final message = error.toString();
    return message.isEmpty
        ? 'Something went wrong while loading your dashboard.'
        : 'Could not load dashboard data. $message';
  }

  Future<void> _refreshData() async {
    final campaigns = await _campaigns.listCampaigns();
    _allCampaigns = campaigns;
    _responses = await _campaigns.listResponses(null);
    _transactions = await _campaigns.listRewardTransactions(null);
    _metrics = await _analytics.getDashboardMetrics(campaigns);
    _completionTrend = await _analytics.getCompletionTrend(campaigns);
    _spendTrend = await _analytics.getSpendTrend(campaigns);
    _interactionMix = await _analytics.getInteractionMix(campaigns);
    _spend = await _analytics.getSpendSummary(campaigns);
  }

  // ---- Mutations -----------------------------------------------------------

  /// Runs a repository mutation, reloads derived data, and reports success.
  /// Returns `false` (instead of throwing) if the call fails so callers can
  /// surface an error toast without crashing the UI.
  Future<bool> _mutate(Future<void> Function() action) async {
    try {
      await action();
      await _refreshData();
      notifyListeners();
      return true;
    } catch (e) {
      if (e is ApiException && e.statusCode == 401) {
        _error = 'ApiException(401)';
        notifyListeners();
      }
      return false;
    }
  }

  Future<bool> createCampaign(Campaign campaign) =>
      _mutate(() => _campaigns.createCampaign(campaign));

  Future<bool> updateCampaign(Campaign campaign) =>
      _mutate(() => _campaigns.updateCampaign(campaign));

  Future<bool> updateStatus(String id, CampaignStatus status) =>
      _mutate(() => _campaigns.updateCampaignStatus(id, status));

  Future<bool> deleteCampaign(String id) =>
      _mutate(() => _campaigns.deleteCampaign(id));

  Future<bool> duplicateCampaign(String id) =>
      _mutate(() => _campaigns.duplicateCampaign(id));

  Future<bool> boostCampaign(String id) =>
      _mutate(() => _campaigns.boostCampaign(id));

  Future<bool> updateProfile(CompanyAdmin admin) async {
    try {
      _admin = await _auth.updateProfile(admin);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---- UI state ------------------------------------------------------------

  void setSearch(String value) {
    if (value == _search) return;
    _search = value;
    notifyListeners();
  }

  void setStatusFilter(CampaignStatus? status) {
    if (status == _statusFilter) return;
    _statusFilter = status;
    notifyListeners();
  }

  void setSort(CampaignSort sort, bool ascending) {
    _sort = sort;
    _sortAscending = ascending;
    notifyListeners();
  }

  Campaign? campaignById(String id) {
    for (final campaign in _allCampaigns) {
      if (campaign.id == id) return campaign;
    }
    return null;
  }
}
