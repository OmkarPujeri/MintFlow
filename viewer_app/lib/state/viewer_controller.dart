import 'package:flutter/foundation.dart';

import '../models/viewer.dart';
import '../repositories/api_client.dart';
import '../repositories/auth_repository.dart';

/// Single reactive source of truth for the viewer app. Widgets rebuild via
/// [ListenableBuilder]. Feed and watch-session state get added in later phases.
class ViewerController extends ChangeNotifier {
  ViewerController(this._auth);

  final AuthRepository _auth;

  Viewer? _viewer;
  Viewer? get viewer => _viewer;

  bool get isAuthenticated => _auth.isAuthenticated && _viewer != null;

  bool _busy = false;
  bool get isBusy => _busy;

  String? _error;
  String? get error => _error;

  /// On startup: if we already hold a token, try to load the profile. A stale
  /// or revoked token just leaves the user logged out.
  Future<void> bootstrap() async {
    if (!_auth.isAuthenticated) return;
    try {
      _viewer = await _auth.me();
    } catch (_) {
      await _auth.logout();
      _viewer = null;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) =>
      _run(() => _auth.login(email, password));

  Future<bool> register(String email, String password) =>
      _run(() => _auth.register(email, password));

  Future<bool> loginWithGoogle(String idToken) =>
      _run(() => _auth.loginWithGoogle(idToken));

  Future<void> refresh() async {
    try {
      _viewer = await _auth.me();
      notifyListeners();
    } catch (_) {
      // keep the last known profile on a transient refresh failure
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    _viewer = null;
    notifyListeners();
  }

  /// Runs an auth action, then loads the profile on success. Returns false and
  /// exposes a message via [error] on failure so the UI can show it.
  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      _viewer = await _auth.me();
      _busy = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _describe(e);
      _busy = false;
      notifyListeners();
      return false;
    }
  }

  String _describe(Object e) {
    if (e is ApiException) {
      if (e.statusCode == 401) return 'Invalid email or password.';
      if (e.statusCode == 409) return 'That email is already registered.';
      if (e.statusCode == 422) {
        return 'Password must be 8+ characters with a letter and a number.';
      }
      return 'Something went wrong (${e.statusCode}). Please try again.';
    }
    return 'Could not reach the server. Check your connection.';
  }
}
