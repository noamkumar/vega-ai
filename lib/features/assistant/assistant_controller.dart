import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vega_ai/core/models/assistant_state.dart';
import 'package:vega_ai/core/models/command_intent.dart';
import 'package:vega_ai/core/models/execution_result.dart';
import 'package:vega_ai/core/models/voice_command.dart';
import 'package:vega_ai/core/utils/logger.dart';
import 'package:vega_ai/features/automation/action_registry.dart';
import 'package:vega_ai/services/ai/ai_router.dart';
import 'package:vega_ai/services/ai/offline_ai_service.dart';
import 'package:vega_ai/services/ai/online_gemini_service.dart';
import 'package:vega_ai/services/connectivity/connectivity_service.dart';
import 'package:vega_ai/services/speech/speech_service.dart';
import 'package:vega_ai/services/voice/tts_service.dart';

/// Central state manager for the VEGA AI voice assistant.
///
/// Coordinates speech capture, AI intent classification, safe device automation,
/// TTS voice responses, and network connectivity status.
class AssistantController extends ChangeNotifier {
  static const _logger = VegaLogger('AssistantController');

  final AIRouter _aiRouter;
  final SpeechService _speechService;
  final TTSService _ttsService;
  final ActionRegistry _actionRegistry;
  final ConnectivityService _connectivityService;

  AssistantStatus _status = AssistantStatus.idle;
  bool _isOnline = true;
  String _activeTranscript = '';
  String _assistantResponse = 'Systems online. Tap the orb or say "Hey Vega" to activate.';
  CommandIntent? _lastIntent;
  CommandIntent? _pendingConfirmationIntent;

  StreamSubscription<bool>? _connectivitySubscription;
  int _activeInteractionId = 0;
  bool _isDisposed = false;

  AssistantController({
    AIRouter? aiRouter,
    SpeechService? speechService,
    TTSService? ttsService,
    ActionRegistry? actionRegistry,
    ConnectivityService? connectivityService,
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
  CommandIntent? get pendingConfirmationIntent => _pendingConfirmationIntent;
  bool get hasPendingConfirmation => _pendingConfirmationIntent != null;
  bool get isDisposed => _isDisposed;

  void _initConnectivityListener() {
    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen((connected) {
      if (_isDisposed) return;
      _isOnline = connected;
      notifyListeners();
    });
  }

  /// Manually toggles online/offline AI mode from UI pill.
  void toggleOnlineMode() {
    if (_isDisposed) return;
    _isOnline = !_isOnline;
    if (_connectivityService is DefaultConnectivityService) {
      (_connectivityService as DefaultConnectivityService).setConnected(_isOnline);
    }
    _logger.info('Toggled AI operating mode to: ${_isOnline ? "Online" : "Offline"}');
    notifyListeners();
  }

  /// Activates listening loop (invoked by orb tap or wake-word).
  Future<void> activateAssistant() async {
    if (_isDisposed) return;

    // Guard 1: Prevent re-entrancy while the assistant is processing a command
    if (_status.isProcessing) {
      _logger.warning('Assistant is actively processing. Ignoring activation request.');
      return;
    }

    // Guard 2: If currently listening, tap stops capture
    if (_status.isListening) {
      await stopListening();
      return;
    }

    // Guard 3: If speaking, tap interrupts speech and returns to idle
    if (_status.isSpeaking) {
      _activeInteractionId++;
      await _ttsService.stop();
      _setStatus(AssistantStatus.idle);
      return;
    }

    // Invalidate any past interactions and clear stale confirmation state
    _activeInteractionId++;
    _pendingConfirmationIntent = null;
    _setStatus(AssistantStatus.listening);
    _activeTranscript = 'Listening...';
    notifyListeners();

    try {
      await _speechService.startListening(
        onPartialResult: (partial) {
          if (_isDisposed || !_status.isListening) return;
          _activeTranscript = partial;
          notifyListeners();
        },
        onResult: (command) async {
          if (_isDisposed) return;
          await _handleCommand(command);
        },
      );
    } catch (e, stack) {
      _logger.error('Error during voice capture', e, stack);
      _activeTranscript = '';
      _assistantResponse = 'Voice recognition error. Please try again.';
      _setStatus(AssistantStatus.idle);
    }
  }

  /// Stops active speech listening and returns to idle.
  Future<void> stopListening() async {
    if (_isDisposed) return;
    _activeInteractionId++;
    try {
      await _speechService.stopListening();
    } catch (e, stack) {
      _logger.error('Error stopping speech service', e, stack);
    }
    _setStatus(AssistantStatus.idle);
  }

  /// Evaluates and executes the captured utterance.
  Future<void> _handleCommand(VoiceCommand command) async {
    if (_isDisposed) return;

    final currentId = ++_activeInteractionId;
    _setStatus(AssistantStatus.processing);
    _activeTranscript = command.transcript;
    notifyListeners();

    try {
      // 1. Route intent through AI Router
      final intent = await _aiRouter.routeCommand(command);
      if (_isDisposed || _activeInteractionId != currentId) return;
      _lastIntent = intent;

      // 2. Dispatch intent
      String responseText;
      if (intent.category == IntentCategory.deviceControl ||
          intent.category == IntentCategory.appLaunch) {
        final result = await _actionRegistry.executeSafely(intent);
        if (_isDisposed || _activeInteractionId != currentId) return;

        if (result.status == ExecutionStatus.requiresUserConfirmation) {
          _pendingConfirmationIntent = intent;
        } else {
          _pendingConfirmationIntent = null;
        }
        responseText = result.speechFeedback;
      } else {
        _pendingConfirmationIntent = null;
        responseText = await _aiRouter.resolveResponse(intent);
      }

      if (_isDisposed || _activeInteractionId != currentId) return;

      _assistantResponse = responseText;
      _setStatus(AssistantStatus.speaking);

      // 3. Speak response via TTS with interaction ID guard
      await _ttsService.speak(
        responseText,
        onDone: () {
          if (_isDisposed) return;
          // Protect against stale callbacks overwriting newer states
          if (_activeInteractionId == currentId && _status == AssistantStatus.speaking) {
            _setStatus(AssistantStatus.idle);
          }
        },
      );
    } catch (e, stack) {
      _logger.error('Error handling command', e, stack);
      if (_isDisposed || _activeInteractionId != currentId) return;
      _pendingConfirmationIntent = null;
      _assistantResponse = 'I encountered an issue processing that command.';
      _setStatus(AssistantStatus.idle);
    }
  }

  /// Confirms and executes a pending action that required user approval.
  Future<void> confirmPendingAction() async {
    final intent = _pendingConfirmationIntent;
    if (intent == null || _isDisposed) return;

    _pendingConfirmationIntent = null;
    final currentId = ++_activeInteractionId;
    _setStatus(AssistantStatus.processing);
    notifyListeners();

    try {
      final result = await _actionRegistry.executeSafely(intent);
      if (_isDisposed || _activeInteractionId != currentId) return;

      _assistantResponse = result.speechFeedback;
      _setStatus(AssistantStatus.speaking);

      await _ttsService.speak(
        result.speechFeedback,
        onDone: () {
          if (_isDisposed) return;
          if (_activeInteractionId == currentId && _status == AssistantStatus.speaking) {
            _setStatus(AssistantStatus.idle);
          }
        },
      );
    } catch (e, stack) {
      _logger.error('Error confirming pending action', e, stack);
      if (_isDisposed) return;
      _assistantResponse = 'Failed to execute the confirmed action.';
      _setStatus(AssistantStatus.idle);
    }
  }

  /// Cancels a pending action that required user approval.
  void cancelPendingAction() {
    if (_isDisposed) return;
    _activeInteractionId++;
    _pendingConfirmationIntent = null;
    _assistantResponse = 'Action cancelled.';
    _setStatus(AssistantStatus.idle);
  }

  void _setStatus(AssistantStatus newStatus) {
    if (_isDisposed) return;
    _status = newStatus;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _speechService.dispose();
    _ttsService.dispose();
    _connectivityService.dispose();
    super.dispose();
  }
}
