import 'package:shared_preferences/shared_preferences.dart';

/// Mobile (dart:io) storage: a synchronous facade over shared_preferences.
///
/// shared_preferences is async, but [ApiClient] and the repositories were
/// written against a synchronous read/write/remove contract. So we load every
/// persisted string once at startup into an in-memory map and write through on
/// each set. Call [create] before wiring ApiClient.
///
/// ponytail: intentionally NOT async on read/write — an async interface would
/// ripple into ApiClient and every repository for zero real gain (the values
/// are tiny: a JWT + a small session blob).
class LocalStorage {
  LocalStorage._(this._prefs, this._cache);

  final SharedPreferences _prefs;
  final Map<String, String> _cache;

  static Future<LocalStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    final cache = <String, String>{};
    for (final key in prefs.getKeys()) {
      final value = prefs.get(key);
      if (value is String) cache[key] = value;
    }
    return LocalStorage._(prefs, cache);
  }

  String? read(String key) => _cache[key];

  void write(String key, String value) {
    _cache[key] = value;
    _prefs.setString(key, value); // write-through; fire-and-forget is fine
  }

  void remove(String key) {
    _cache.remove(key);
    _prefs.remove(key);
  }
}
