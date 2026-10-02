import 'package:flutter/foundation.dart';

/// Lightweight, safe logging utility for VEGA AI.
/// Ensures debug messages are stripped in release builds and no sensitive tokens are logged.
class VegaLogger {
  final String tag;

  const VegaLogger(this.tag);

  void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO][$tag] $message');
    }
  }

  void warning(String message) {
    if (kDebugMode) {
      debugPrint('[WARN][$tag] ⚠️ $message');
    }
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR][$tag] ❌ $message');
      if (error != null) debugPrint('Error details: $error');
      if (stackTrace != null) debugPrint('$stackTrace');
    }
  }
}
