import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'local_storage.dart';

/// Thin HTTP wrapper for talking to the FastAPI backend.
///
/// It stores the JWT in local storage and attaches it as a Bearer token on
/// every request. The API-backed repositories (to be written when the backend
/// exists) should depend on this instead of [LocalStorage].
///
/// Example wiring inside a future `CampaignApiRepository`:
///   final json = await apiClient.get('/campaigns');
///   return (json as List).map((e) => Campaign.fromJson(e)).toList();
class ApiClient {
  ApiClient(this._storage, {http.Client? client})
      : _client = client ?? http.Client();

  static const _tokenKey = 'mintflow.auth.token';

  final LocalStorage _storage;
  final http.Client _client;

  String get _baseUrl => AppConfig.apiBaseUrl;

  String? get token => _storage.read(_tokenKey);
  bool get isAuthenticated => token != null;

  void saveToken(String token) => _storage.write(_tokenKey, token);
  void clearToken() => _storage.remove(_tokenKey);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path) => _send('GET', path);

  Future<dynamic> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path, {Object? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final request = http.Request(method, uri)..headers.addAll(_headers);
    if (body != null) request.body = jsonEncode(body);

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
