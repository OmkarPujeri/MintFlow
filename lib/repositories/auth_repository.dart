import 'dart:convert';

import '../models/company_admin.dart';
import 'local_storage.dart';

class AuthRepository {
  AuthRepository(this._storage);

  static const _sessionKey = 'mintflow.company_admin.session';

  final LocalStorage _storage;

  Future<CompanyAdmin?> currentAdmin() async {
    final session = _storage.read(_sessionKey);
    if (session == null) return null;
    return CompanyAdmin.fromJson(jsonDecode(session) as Map<String, dynamic>);
  }

  Future<CompanyAdmin> login(String email, String password) async {
    final admin = CompanyAdmin(
      id: 'admin-demo',
      name: 'Demo Company Admin',
      email: email.trim().isEmpty ? 'admin@mintflow.app' : email.trim(),
      companyName: 'MintFlow Demo Brand',
    );
    _storage.write(_sessionKey, jsonEncode(admin.toJson()));
    return admin;
  }

  /// Sign in with Google.
  ///
  /// Currently creates a demo session so the flow is fully usable without
  /// OAuth credentials. To go live: use the `google_sign_in` package to obtain
  /// the Google ID token, POST it to `/auth/google` on the backend, and build
  /// the [CompanyAdmin] from the verified response instead of the values here.
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
    _storage.remove(_sessionKey);
  }
}
