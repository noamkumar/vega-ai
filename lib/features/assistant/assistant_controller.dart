import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vega_ai/core/models/assistant_state.dart';
import 'package:vega_ai/core/models/command_intent.dart';
import 'package:vega_ai/core/models/execution_result.dart';
import 'package:vega_ai/core/models/voice_command.dart';
import 'package:vega_ai/core/utils/logger.dart';
import 'package:vega_ai/features/automation/action_registry.dart';
import 'package:vega_ai/services/ai/ai_router.dart';
import 'package:vega_ai/services/ai/local_model_manager.dart';
import 'package:vega_ai/services/ai/offline_ai_service.dart';
import 'package:vega_ai/services/ai/online_gemini_service.dart';
import 'package:vega_ai/services/connectivity/connectivity_service.dart';
import 'package:vega_ai/services/speech/speech_service.dart';
import 'package:vega_ai/services/storage/storage_service.dart';
import 'package:vega_ai/services/voice/tts_service.dart';

/// Central state manager for the VEGA AI voice assistant.
///
/// Coordinates speech capture, wake-word detection, offline model inference,
/// safe device automation, interruptible TTS responses, and connectivity.
class AssistantController extends ChangeNotifier {
  static const _logger = VegaLogger('AssistantController');

  final AIRouter _aiRouter;
  final SpeechService _speechService;
  final TTSService _ttsService;
  final ActionRegistry _actionRegistry;
  final ConnectivityService _connectivityService;
  final StorageService _storageService;
  final OnlineGeminiService? _onlineService;

  AssistantStatus _status = AssistantStatus.idle;
  bool _isOnline = true;
  String _activeTranscript = '';
  String _assistantResponse = 'Systems online. Tap the orb or say "Hey Vega" to activate.';
  CommandIntent? _lastIntent;
  CommandIntent? _pendingConfirmationIntent;

  StreamSubscription<bool>? _connectivitySubscription;
  int _activeInteractionId = 0;
  bool _isDisposed = false;

  /// Default constructor (takes optional injected services, falls back to mocks for unit tests).
  AssistantController({
    AIRouter? aiRouter,
    SpeechService? speechService,
    TTSService? ttsService,
    ActionRegistry? actionRegistry,
    ConnectivityService? connectivityService,
    StorageService? storageService,
    OnlineGeminiService? onlineService,
  })  : _connectivityService = connectivityService ?? DefaultConnectivityService(),
        _actionRegistry = actionRegistry ?? ActionRegistry(),
        _speechService = speechService ?? MockSpeechService(),
        _ttsService = ttsService ?? MockTTSService(),
        _storageService = storageService ?? JsonFileStorageService(),
        _onlineService = onlineService,
        _aiRouter = aiRouter ??
            AIRouter(
              offlineService: OfflineAIService(),
              onlineService: onlineService ?? OnlineGeminiService(),
              connectivityService: connectivityService ?? DefaultConnectivityService(),
            ) {
    _initConnectivityListener();
    _loadSettings();
  }

  /// Production factory for running on physical Android hardware.
  factory AssistantController.forDevice({
    StorageService? storageService,
    ActionRegistry? actionRegistry,
    ConnectivityService? connectivityService,
    LocalModelManager? modelManager,
  }) {
    final storage = storageService ?? JsonFileStorageService();
    final connectivity = connectivityService ?? DefaultConnectivityService();
    final localManager = modelManager ?? LocalModelManager();
    final online = OnlineGeminiService();
    final offline = OfflineAIService(modelManager: localManager);
    final router = AIRouter(
      offlineService: offline,
      onlineService: online,
      connectivityService: connectivity,
    );
    final speech = PlatformSpeechService();
    final tts = PlatformTTSService();
    return AssistantController(
      aiRouter: router,
      speechService: speech,
      ttsService: tts,
      actionRegistry: actionRegistry ?? ActionRegistry(),
      connectivityService: connectivity,
      storageService: storage,
      onlineService: online,
    );
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
  OnlineGeminiService? get onlineService => _onlineService;
  AIRouter get aiRouter => _aiRouter;

  void _initConnectivityListener() {
    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen((connected) {
      if (_isDisposed) return;
      _isOnline = connected;
      notifyListeners();
    });
  }

  Future<void> _loadSettings() async {
    try {
      final apiKey = await _storageService.getGeminiApiKey();
      if (apiKey != null && apiKey.isNotEmpty) {
        _onlineService?.updateApiKey(apiKey);
      }
      final model = await _storageService.getGeminiModel();
      _onlineService?.updateModelId(model);

      final offlineFirst = await _storageService.getOfflineFirst();
      _aiRouter.preferOfflineFirst = offlineFirst;

      final rate = await _storageService.getSpeechRate();
      final pitch = await _storageService.getSpeechPitch();
      await _ttsService.setVoiceParameters(rate: rate, pitch: pitch);
    } catch (e) {
      _logger.warning('Failed to load saved settings: $e');
    }
  }

  /// Manually toggles online/offline AI mode from UI pill.
  void toggleOnlineMode() {
    if (_isDisposed) return;
    _isOnline = !_isOnline;
    _connectivityService.setConnected(_isOnline);
    _logger.info('Toggled AI operating mode to: ${_isOnline ? "Online" : "Offline"}');
    notifyListeners();
  }

  /// Strips wake-word prefix ("Hey Vega", "Vega841", "Vega") from captured utterances.
  String _cleanWakeWord(String transcript) {
    var text = transcript.trim();
    final lower = text.toLowerCase();
    if (lower.startsWith('hey vega')) {
      text = text.substring(8).trim();
    } else if (lower.startsWith('vega841')) {
      text = text.substring(7).trim();
    } else if (lower.startsWith('vega')) {
      text = text.substring(4).trim();
    }
    text = text.replaceFirst(RegExp(r'^[,:\s]+'), '');
    return text.isEmpty ? transcript : text;
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

    // Guard 3: If speaking, interrupt speech to start listening
    if (_status.isSpeaking) {
      await _ttsService.stop();
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

    final cleanedTranscript = _cleanWakeWord(command.transcript);
    final effectiveCommand = command.copyWith(transcript: cleanedTranscript);

    _activeTranscript = cleanedTranscript;
    notifyListeners();

    try {
      // 1. Route intent through AI Router
      final intent = await _aiRouter.routeCommand(effectiveCommand);
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
      if (_isDisposed || _activeInteractionId != currentId) return;
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
    if (_isDisposed) return;
    _isDisposed = true;
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _speechService.dispose();
    _ttsService.dispose();
    super.dispose();
  }
}
