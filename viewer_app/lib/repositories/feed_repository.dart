import '../models/campaign.dart';
import 'api_client.dart';

/// Viewer feed: active campaigns the viewer hasn't watched yet (backend already
/// excludes watched + orders boosted-first).
class FeedRepository {
  FeedRepository(this._api);

  final ApiClient _api;

  Future<List<Campaign>> list({int limit = 50, int offset = 0}) async {
    final json = await _api.get('/api/v1/feed/?limit=$limit&offset=$offset');
    return (json as List)
        .map((e) => Campaign.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
