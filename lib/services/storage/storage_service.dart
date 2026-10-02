/// Contract for persistent storage (settings, preferences, and activity history).
abstract class StorageService {
  Future<void> init();

  Future<void> setString(String key, String value);
  String? getString(String key, {String? defaultValue});

  Future<void> setBool(String key, bool value);
  bool getBool(String key, {bool defaultValue = false});

  Future<void> setDouble(String key, double value);
  double getDouble(String key, {double defaultValue = 0.0});

  Future<void> remove(String key);
  Future<void> clear();
}

/// In-memory storage implementation for initial bootstrapping.
class InMemoryStorageService implements StorageService {
  final Map<String, dynamic> _store = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> setString(String key, String value) async => _store[key] = value;

  @override
  String? getString(String key, {String? defaultValue}) =>
      _store[key] as String? ?? defaultValue;

  @override
  Future<void> setBool(String key, bool value) async => _store[key] = value;

  @override
  bool getBool(String key, {bool defaultValue = false}) =>
      _store[key] as bool? ?? defaultValue;

  @override
  Future<void> setDouble(String key, double value) async => _store[key] = value;

  @override
  double getDouble(String key, {double defaultValue = 0.0}) =>
      (_store[key] as num?)?.toDouble() ?? defaultValue;

  @override
  Future<void> remove(String key) async => _store.remove(key);

  @override
  Future<void> clear() async => _store.clear();
}
