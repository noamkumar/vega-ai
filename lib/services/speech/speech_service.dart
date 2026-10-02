import 'dart:async';
import 'package:vega_ai/core/models/voice_command.dart';

/// Contract for Speech Recognition (STT) and Wake Word detection.
abstract class SpeechService {
  /// Whether microphone is actively streaming audio.
  bool get isListening;

  /// Stream of recognized live transcripts.
  Stream<String> get transcriptStream;

  /// Initializes the speech engine (checking permissions, models, audio focus).
  Future<bool> initialize();

  /// Starts capturing speech.
  Future<void> startListening({
    required Function(VoiceCommand command) onResult,
    Function(String partial)? onPartialResult,
  });

  /// Stops speech capture.
  Future<void> stopListening();

  /// Starts listening for background wake word (e.g. "Hey Vega").
  Future<void> startWakeWordDetection({required Function() onWakeWordDetected});

  /// Stops background wake word detection.
  Future<void> stopWakeWordDetection();

  void dispose();
}

/// Simulated speech service for early interface development and mock testing.
class MockSpeechService implements SpeechService {
  final _transcriptController = StreamController<String>.broadcast();
  bool _isListening = false;

  @override
  bool get isListening => _isListening;

  @override
  Stream<String> get transcriptStream => _controller.stream;
  StreamController<String> get _controller => _transcriptController;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> startListening({
    required Function(VoiceCommand command) onResult,
    Function(String partial)? onPartialResult,
  }) async {
    _isListening = true;
    onPartialResult?.call('Hey Vega...');
    await Future.delayed(const Duration(milliseconds: 600));
    onPartialResult?.call('Turn on the flashlight');

    await Future.delayed(const Duration(milliseconds: 600));
    _isListening = false;
    onResult(
      VoiceCommand(
        id: 'cmd_${DateTime.now().millisecondsSinceEpoch}',
        transcript: 'Turn on the flashlight',
        confidence: 0.95,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
  }

  @override
  Future<void> startWakeWordDetection({required Function() onWakeWordDetected}) async {}

  @override
  Future<void> stopWakeWordDetection() async {}

  @override
  void dispose() {
    _transcriptController.close();
  }
}
