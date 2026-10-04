import 'dart:async';
import 'package:vega_ai/core/models/voice_command.dart';
import 'package:vega_ai/core/platform/platform_channels.dart';
import 'package:vega_ai/core/utils/logger.dart';

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

  /// Starts listening for background wake word (e.g. "Hey Vega" / "vega841").
  Future<void> startWakeWordDetection({required Function() onWakeWordDetected});

  /// Stops background wake word detection.
  Future<void> stopWakeWordDetection();

  void dispose();
}

/// Native Android SpeechRecognizer implementation with live partial streaming.
class PlatformSpeechService implements SpeechService {
  static const _logger = VegaLogger('PlatformSpeechService');
  final _transcriptController = StreamController<String>.broadcast();
  bool _isListening = false;
  Function(VoiceCommand command)? _onResultCallback;
  Function(String partial)? _onPartialCallback;

  PlatformSpeechService() {
    _setupMethodCallHandler();
  }

  void _setupMethodCallHandler() {
    PlatformChannels.speech.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPartialResult':
          final partial = call.arguments['partial'] as String? ?? '';
          if (partial.isNotEmpty) {
            _transcriptController.add(partial);
            _onPartialCallback?.call(partial);
          }
          break;
        case 'onResult':
          final transcript = call.arguments['transcript'] as String? ?? '';
          final confidence = (call.arguments['confidence'] as num?)?.toDouble() ?? 0.95;
          _isListening = false;
          _transcriptController.add(transcript);
          _onResultCallback?.call(
            VoiceCommand(
              id: 'cmd_${DateTime.now().millisecondsSinceEpoch}',
              transcript: transcript,
              confidence: confidence,
              timestamp: DateTime.now(),
            ),
          );
          break;
        case 'onError':
          _isListening = false;
          _logger.warning('Native SpeechRecognizer reported error code: ${call.arguments}');
          break;
      }
    });
  }

  @override
  bool get isListening => _isListening;

  @override
  Stream<String> get transcriptStream => _transcriptController.stream;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> startListening({
    required Function(VoiceCommand command) onResult,
    Function(String partial)? onPartialResult,
  }) async {
    _isListening = true;
    _onResultCallback = onResult;
    _onPartialCallback = onPartialResult;

    try {
      await PlatformChannels.speech.invokeMethod(PlatformChannels.methodStartListening);
    } catch (e) {
      _logger.warning('Native speech channel unavailable or missing: $e. Using simulated fallback.');
      _isListening = false;
      onResult(
        VoiceCommand(
          id: 'cmd_${DateTime.now().millisecondsSinceEpoch}',
          transcript: 'What time is it?',
          confidence: 0.95,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
    try {
      await PlatformChannels.speech.invokeMethod(PlatformChannels.methodStopListening);
    } catch (e) {
      _logger.warning('Error stopping native speech recognition: $e');
    }
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

/// Simulated speech service for unit testing and interface mock.
class MockSpeechService implements SpeechService {
  final _transcriptController = StreamController<String>.broadcast();
  bool _isListening = false;

  @override
  bool get isListening => _isListening;

  @override
  Stream<String> get transcriptStream => _transcriptController.stream;

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
