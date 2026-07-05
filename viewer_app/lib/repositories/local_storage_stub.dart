class LocalStorage {
  final Map<String, String> _values = {};

  /// Parity with the io facade's async startup loader — nothing to load here.
  static Future<LocalStorage> create() async => LocalStorage();

  String? read(String key) => _values[key];

  void write(String key, String value) {
    _values[key] = value;
  }

  void remove(String key) {
    _values.remove(key);
  }
}
