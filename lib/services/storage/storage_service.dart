import 'dart:convert';
import 'dart:io';

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

/// Persistent JSON file-backed storage service.
class JsonFileStorageService implements StorageService {
  final String _filePath;
  Map<String, dynamic> _store = {};

  JsonFileStorageService({String? filePath})
      : _filePath = filePath ?? '${Directory.systemTemp.path}/vega_settings.json';

  @override
  Future<void> init() async {
    try {
      final file = File(_filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          _store = jsonDecode(content) as Map<String, dynamic>;
        }
      }
    } catch (_) {
      _store = {};
    }
  }

  Future<void> _flush() async {
    try {
      final file = File(_filePath);
      await file.writeAsString(jsonEncode(_store), flush: true);
    } catch (_) {}
  }

  @override
  Future<void> setString(String key, String value) async {
    _store[key] = value;
    await _flush();
  }

  @override
  String? getString(String key, {String? defaultValue}) {
    return _store[key] as String? ?? defaultValue;
  }

  @override
  Future<void> setBool(String key, bool value) async {
    _store[key] = value;
    await _flush();
  }

  @override
  bool getBool(String key, {bool defaultValue = false}) {
    return _store[key] as bool? ?? defaultValue;
  }

  @override
  Future<void> setDouble(String key, double value) async {
    _store[key] = value;
    await _flush();
  }

  @override
  double getDouble(String key, {double defaultValue = 0.0}) {
    return (_store[key] as num?)?.toDouble() ?? defaultValue;
  }

  @override
  Future<void> remove(String key) async {
    _store.remove(key);
    await _flush();
  }

  @override
  Future<void> clear() async {
    _store.clear();
    await _flush();
  }
}

/// In-memory storage implementation for initial bootstrapping and tests.
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

/// Convenience extension providing strongly typed getters and setters for assistant settings.
extension StorageSettingsExtension on StorageService {
  Future<String?> getGeminiApiKey() async => getString('gemini_api_key');
  Future<void> saveGeminiApiKey(String key) => setString('gemini_api_key', key);

  Future<String> getGeminiModel() async =>
      getString('gemini_model', defaultValue: 'gemini-1.5-flash') ?? 'gemini-1.5-flash';
  Future<void> saveGeminiModel(String model) => setString('gemini_model', model);

  Future<bool> getOfflineFirst() async => getBool('offline_first', defaultValue: true);
  Future<void> saveOfflineFirst(bool val) => setBool('offline_first', val);

  Future<bool> getWakeWordEnabled() async => getBool('wake_word_enabled', defaultValue: true);
  Future<void> saveWakeWordEnabled(bool val) => setBool('wake_word_enabled', val);

  Future<double> getWakeWordSensitivity() async => getDouble('wake_word_sensitivity', defaultValue: 0.75);
  Future<void> saveWakeWordSensitivity(double val) => setDouble('wake_word_sensitivity', val);

  Future<double> getSpeechRate() async => getDouble('speech_rate', defaultValue: 1.0);
  Future<void> saveSpeechRate(double val) => setDouble('speech_rate', val);

  Future<double> getSpeechPitch() async => getDouble('speech_pitch', defaultValue: 1.0);
  Future<void> saveSpeechPitch(double val) => setDouble('speech_pitch', val);
}

