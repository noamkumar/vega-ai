import 'package:vega_ai/core/platform/platform_channels.dart';
import 'package:vega_ai/core/utils/logger.dart';

/// Contract for Text-to-Speech (TTS) voice generation.
abstract class TTSService {
  /// Whether speech is actively playing through speakers.
  bool get isSpeaking;

  /// Speaks the provided text and notifies when completed.
  Future<void> speak(String text, {Function()? onDone});

  /// Immediately interrupts speech output.
  Future<void> stop();

  /// Adjusts voice playback settings.
  Future<void> setVoiceParameters({double pitch = 1.0, double rate = 1.0, String? voiceName});

  void dispose();
}

/// Native Android TextToSpeech implementation with instant stop interruptibility.
class PlatformTTSService implements TTSService {
  static const _logger = VegaLogger('PlatformTTSService');
  bool _isSpeaking = false;
  Function()? _onDoneCallback;

  PlatformTTSService() {
    _setupMethodCallHandler();
  }

  void _setupMethodCallHandler() {
    PlatformChannels.tts.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onDone':
          _isSpeaking = false;
          _onDoneCallback?.call();
          break;
        case 'onError':
          _isSpeaking = false;
          _logger.warning('Native TTS error: ${call.arguments}');
          _onDoneCallback?.call();
          break;
      }
    });
  }

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Future<void> speak(String text, {Function()? onDone}) async {
    _isSpeaking = true;
    _onDoneCallback = onDone;
    try {
      await PlatformChannels.tts.invokeMethod(
        PlatformChannels.methodSpeak,
        {'text': text},
      );
    } catch (e) {
      _logger.warning('Native TTS invocation failed, falling back to simulated delay: $e');
      final durationMs = (text.length * 40).clamp(600, 2500);
      await Future.delayed(Duration(milliseconds: durationMs));
      _isSpeaking = false;
      onDone?.call();
    }
  }

  @override
  Future<void> stop() async {
    _isSpeaking = false;
    _onDoneCallback = null;
    try {
      await PlatformChannels.tts.invokeMethod(PlatformChannels.methodStopTTS);
    } catch (e) {
      _logger.warning('Failed to stop native TTS: $e');
    }
  }

  @override
  Future<void> setVoiceParameters({double pitch = 1.0, double rate = 1.0, String? voiceName}) async {
    try {
      await PlatformChannels.tts.invokeMethod(
        PlatformChannels.methodSetVoiceParameters,
        {'pitch': pitch, 'rate': rate, 'voiceName': voiceName},
      );
    } catch (e) {
      _logger.warning('Failed to set native voice parameters: $e');
    }
  }

  @override
  void dispose() {
    stop();
  }
}

/// Mock TTS service for testing and interface simulation.
class MockTTSService implements TTSService {
  bool _isSpeaking = false;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Future<void> speak(String text, {Function()? onDone}) async {
    _isSpeaking = true;
    final durationMs = (text.length * 40).clamp(800, 3000);
    await Future.delayed(Duration(milliseconds: durationMs));
    _isSpeaking = false;
    onDone?.call();
  }

  @override
  Future<void> stop() async {
    _isSpeaking = false;
  }

  @override
  Future<void> setVoiceParameters({double pitch = 1.0, double rate = 1.0, String? voiceName}) async {}

  @override
  void dispose() {}
}
