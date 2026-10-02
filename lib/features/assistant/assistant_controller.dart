import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vega_ai/core/models/assistant_state.dart';
import 'package:vega_ai/core/models/command_intent.dart';
import 'package:vega_ai/core/models/voice_command.dart';
import 'package:vega_ai/core/utils/logger.dart';
import 'package:vega_ai/features/automation/action_registry.dart';
import 'package:vega_ai/services/ai/ai_router.dart';
import 'package:vega_ai/services/ai/offline_ai_service.dart';
import 'package:vega_ai/services/ai/online_gemini_service.dart';
import 'package:vega_ai/services/connectivity/connectivity_service.dart';
import 'package:vega_ai/services/speech/speech_service.dart';
import 'package:vega_ai/services/voice/tts_service.dart';

/// Central state manager for VEGA AI voice assistant.
class AssistantController extends ChangeNotifier {
  static const _logger = VegaLogger('AssistantController');

  final AIRouter _aiRouter;
  final SpeechService _speechService;
  final TTSService _ttsService;
  final ActionRegistry _actionRegistry;
  final DefaultConnectivityService _connectivityService;

  AssistantStatus _status = AssistantStatus.idle;
  bool _isOnline = true;
  String _activeTranscript = '';
  String _assistantResponse = 'Systems online. Tap the orb or say "Hey Vega" to activate.';
  CommandIntent? _lastIntent;

  AssistantController({
    AIRouter? aiRouter,
    SpeechService? speechService,
    TTSService? ttsService,
    ActionRegistry? actionRegistry,
    DefaultConnectivityService? connectivityService,
  })  : _connectivityService = connectivityService ?? DefaultConnectivityService(),
        _actionRegistry = actionRegistry ?? ActionRegistry(),
        _speechService = speechService ?? MockSpeechService(),
        _ttsService = ttsService ?? MockTTSService(),
        _aiRouter = aiRouter ??
            AIRouter(
              offlineService: OfflineAIService(),
              onlineService: OnlineGeminiService(),
              connectivityService: connectivityService ?? DefaultConnectivityService(),
            ) {
    _initConnectivityListener();
  }

  // Getters
  AssistantStatus get status => _status;
  bool get isOnline => _isOnline;
  String get activeTranscript => _activeTranscript;
  String get assistantResponse => _assistantResponse;
  CommandIntent? get lastIntent => _lastIntent;

  void _initConnectivityListener() {
    _connectivityService.onConnectivityChanged.listen((connected) {
      _isOnline = connected;
      notifyListeners();
    });
  }

  /// Manually toggles online/offline AI mode from UI pill.
  void toggleOnlineMode() {
    _isOnline = !_isOnline;
    _connectivityService.setConnected(_isOnline);
    _logger.info('Toggled AI operating mode to: ${_isOnline ? "Online" : "Offline"}');
    notifyListeners();
  }

  /// Activates listening loop (invoked by orb tap or wake-word).
  Future<void> activateAssistant() async {
    if (_status.isListening) {
      await stopListening();
      return;
    }

    if (_status.isSpeaking) {
      await _ttsService.stop();
      _setStatus(AssistantStatus.idle);
      return;
    }

    _setStatus(AssistantStatus.listening);
    _activeTranscript = 'Listening...';
    notifyListeners();

    try {
      await _speechService.startListening(
        onPartialResult: (partial) {
          _activeTranscript = partial;
          notifyListeners();
        },
        onResult: (command) async {
          await _handleCommand(command);
        },
      );
    } catch (e, stack) {
      _logger.error('Error during voice capture', e, stack);
      _setStatus(AssistantStatus.idle);
      _assistantResponse = 'Voice recognition error. Please try again.';
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    await _speechService.stopListening();
    _setStatus(AssistantStatus.idle);
    notifyListeners();
  }

  /// Evaluates and executes the captured utterance.
  Future<void> _handleCommand(VoiceCommand command) async {
    _setStatus(AssistantStatus.processing);
    _activeTranscript = command.transcript;
    notifyListeners();

    try {
      // 1. Route intent through AI Router
      final intent = await _aiRouter.routeCommand(command);
      _lastIntent = intent;

      // 2. If it's a device action, dispatch to safe registry
      String responseText;
      if (intent.category == IntentCategory.deviceControl ||
          intent.category == IntentCategory.appLaunch) {
        final result = await _actionRegistry.executeSafely(intent);
        responseText = result.speechFeedback;
      } else {
        responseText = await _aiRouter.resolveResponse(intent);
      }

      _assistantResponse = responseText;
      _setStatus(AssistantStatus.speaking);
      notifyListeners();

      // 3. Speak the feedback via TTS
      await _ttsService.speak(
        responseText,
        onDone: () {
          _setStatus(AssistantStatus.idle);
          notifyListeners();
        },
      );
    } catch (e, stack) {
      _logger.error('Error handling command', e, stack);
      _assistantResponse = 'I encountered an issue processing that command.';
      _setStatus(AssistantStatus.idle);
      notifyListeners();
    }
  }

  void _setStatus(AssistantStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  @override
  void dispose() {
    _speechService.dispose();
    _ttsService.dispose();
    _connectivityService.dispose();
    super.dispose();
  }
}
