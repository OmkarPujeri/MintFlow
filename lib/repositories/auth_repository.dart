import 'dart:convert';

import '../models/company_admin.dart';
import 'api_client.dart';
import 'local_storage.dart';

class AuthRepository {
  AuthRepository(this._storage, this._api);

  static const _sessionKey = 'mintflow.company_admin.session';

  final LocalStorage _storage;
  final ApiClient _api;

  Future<CompanyAdmin?> currentAdmin() async {
    final session = _storage.read(_sessionKey);
    if (session == null) return null;
    return CompanyAdmin.fromJson(jsonDecode(session) as Map<String, dynamic>);
  }

  Future<CompanyAdmin> login(String email, String password) async {
    final response = await _api.post('/api/v1/auth/login', body: {
      'email': email.trim(),
      'password': password,
    });

    // Save JWT token for all future API calls
    _api.saveToken(response['access_token'] as String);

    final admin = CompanyAdmin(
      id: response['id'] as String,
      name: response['name'] as String? ?? 'Company Admin',
      email: response['email'] as String,
      companyName: response['companyName'] as String? ?? 'My Brand',
      brandBio: response['brandBio'] as String? ?? '',
      brandWebsite: response['brandWebsite'] as String? ?? '',
      brandLogoUrl: response['brandLogoUrl'] as String? ?? '',
    );
    _storage.write(_sessionKey, jsonEncode(admin.toJson()));
    return admin;
  }

  /// Google Sign-In — still demo for now.
  /// To go live: obtain Google ID token, POST to /api/v1/auth/google, 
  /// then call _api.saveToken() with the returned access_token.
  Future<CompanyAdmin> loginWithGoogle({
    String? name,
    String? email,
    String? companyName,
  }) async {
    final admin = CompanyAdmin(
      id: 'admin-google-demo',
      name: name ?? 'Google Company Admin',
      email: email ?? 'admin@gmail.com',
      companyName: companyName ?? 'MintFlow Demo Brand',
    );
    _storage.write(_sessionKey, jsonEncode(admin.toJson()));
    return admin;
  }

  Future<CompanyAdmin> updateProfile(CompanyAdmin admin) async {
    _storage.write(_sessionKey, jsonEncode(admin.toJson()));
    return admin;
  }

  Future<void> logout() async {
    try {
      await _api.post('/api/v1/auth/logout');
    } catch (_) {
      // Logout even if backend call fails
    }
    _api.clearToken();
    _storage.remove(_sessionKey);
  }
}
