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

/// Mock TTS service for testing and interface simulation.
class MockTTSService implements TTSService {
  bool _isSpeaking = false;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Future<void> speak(String text, {Function()? onDone}) async {
    _isSpeaking = true;
    // Simulate speaking duration based on text length
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
