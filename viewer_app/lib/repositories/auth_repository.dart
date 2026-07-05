import '../models/viewer.dart';
import 'api_client.dart';

/// Viewer auth against the FastAPI backend. Saves the app JWT via [ApiClient]
/// so every later request is authenticated. Gamification state (coins/streak)
/// is fetched separately via [me] since login only returns tokens.
class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  bool get isAuthenticated => _api.isAuthenticated;

  /// Register a viewer account, then log in so we hold a token.
  Future<void> register(String email, String password) async {
    await _api.post('/api/v1/auth/register', body: {
      'email': email.trim(),
      'password': password,
      'role': 'viewer',
    });
    await login(email, password);
  }

  Future<void> login(String email, String password) async {
    final response = await _api.post('/api/v1/auth/login', body: {
      'email': email.trim(),
      'password': password,
    });
    _api.saveToken(response['access_token'] as String);
  }

  /// Exchange a Google ID token (from google_sign_in) for our app JWT. The
  /// backend verifies the token and finds-or-creates the user.
  Future<void> loginWithGoogle(String googleIdToken) async {
    final response = await _api.post('/api/v1/auth/google', body: {
      'id_token': googleIdToken,
    });
    _api.saveToken(response['access_token'] as String);
  }

  /// Current viewer profile + gamification. Returns null if unauthenticated.
  Future<Viewer?> me() async {
    if (!_api.isAuthenticated) return null;
    final json = await _api.get('/api/v1/auth/me');
    return Viewer.fromJson(json as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _api.post('/api/v1/auth/logout');
    } catch (_) {
      // Log out locally even if the backend call fails.
    }
    _api.clearToken();
  }
}
