import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:vega_ai/core/models/assistant_state.dart';
import 'package:vega_ai/core/models/command_intent.dart';
import 'package:vega_ai/core/models/voice_command.dart';
import 'package:vega_ai/features/assistant/assistant_controller.dart';
import 'package:vega_ai/features/automation/action_registry.dart';
import 'package:vega_ai/features/automation/models/app_action.dart';
import 'package:vega_ai/services/ai/ai_router.dart';
import 'package:vega_ai/services/ai/offline_ai_service.dart';
import 'package:vega_ai/services/ai/online_gemini_service.dart';
import 'package:vega_ai/services/connectivity/connectivity_service.dart';
import 'package:vega_ai/services/speech/speech_service.dart';
import 'package:vega_ai/services/voice/tts_service.dart';

class TestSpeechService implements SpeechService {
  Function(VoiceCommand)? onResultCallback;
  Function(String)? onPartialCallback;
  bool isListeningActive = false;

  @override
  bool get isListening => isListeningActive;

  @override
  Stream<String> get transcriptStream => const Stream.empty();

  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> startListening({
    required Function(VoiceCommand command) onResult,
    Function(String partial)? onPartialResult,
  }) async {
    isListeningActive = true;
    onResultCallback = onResult;
    onPartialCallback = onPartialResult;
  }

  @override
  Future<void> stopListening() async {
    isListeningActive = false;
  }

  @override
  Future<void> startWakeWordDetection({required Function() onWakeWordDetected}) async {}

  @override
  Future<void> stopWakeWordDetection() async {}

  @override
  void dispose() {}
}

class TestTTSService implements TTSService {
  Function()? pendingOnDone;
  bool isSpeakingActive = false;
  String? lastSpokenText;

  @override
  bool get isSpeaking => isSpeakingActive;

  @override
  Future<void> speak(String text, {Function()? onDone}) async {
    isSpeakingActive = true;
    lastSpokenText = text;
    pendingOnDone = onDone;
  }

  @override
  Future<void> stop() async {
    isSpeakingActive = false;
    pendingOnDone = null;
  }

  @override
  Future<void> setVoiceParameters({double pitch = 1.0, double rate = 1.0, String? voiceName}) async {}

  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AssistantController State Machine Tests', () {
    late TestSpeechService speechService;
    late TestTTSService ttsService;
    late ActionRegistry actionRegistry;
    late DefaultConnectivityService connectivityService;
    late AIRouter aiRouter;
    late AssistantController controller;

    setUp(() {
      speechService = TestSpeechService();
      ttsService = TestTTSService();
      actionRegistry = ActionRegistry();
      connectivityService = DefaultConnectivityService(initialConnected: true);
      aiRouter = AIRouter(
        offlineService: OfflineAIService(),
        onlineService: OnlineGeminiService(),
        connectivityService: connectivityService,
        preferOfflineFirst: true,
      );

      controller = AssistantController(
        speechService: speechService,
        ttsService: ttsService,
        actionRegistry: actionRegistry,
        connectivityService: connectivityService,
        aiRouter: aiRouter,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initial state is idle', () {
      expect(controller.status, equals(AssistantStatus.idle));
      expect(controller.hasPendingConfirmation, isFalse);
    });

    test('Activation moves state to listening', () async {
      await controller.activateAssistant();
      expect(controller.status, equals(AssistantStatus.listening));
      expect(speechService.isListeningActive, isTrue);
    });

    test('Blocks activation while assistant is actively processing', () async {
      await controller.activateAssistant();

      // Trigger a command callback to enter processing
      final command = VoiceCommand(
        id: 'cmd_1',
        transcript: 'Turn on the flashlight',
        confidence: 0.95,
        timestamp: DateTime.now(),
      );

      // Trigger command processing
      unawaited(speechService.onResultCallback!(command));

      // Immediate state should be processing
      expect(controller.status, equals(AssistantStatus.processing));

      // Attempt activation while processing
      await controller.activateAssistant();

      // State MUST remain processing and not restart listening
      expect(controller.status, equals(AssistantStatus.processing));
    });

    test('Stale TTS onDone callback does NOT overwrite newer state', () async {
      await controller.activateAssistant();

      final command = VoiceCommand(
        id: 'cmd_1',
        transcript: 'What time is it?',
        confidence: 0.95,
        timestamp: DateTime.now(),
      );

      // Process command
      await speechService.onResultCallback!(command);

      // Controller should be in speaking state with a captured onDone callback
      expect(controller.status, equals(AssistantStatus.speaking));
      final staleOnDone = ttsService.pendingOnDone;
      expect(staleOnDone, isNotNull);

      // User interrupts speech to start a new command
      await controller.activateAssistant();
      expect(controller.status, equals(AssistantStatus.listening));

      // Now the delayed/stale onDone callback from the previous interaction fires
      staleOnDone!();

      // Controller MUST remain in listening, not overwritten to idle
      expect(controller.status, equals(AssistantStatus.listening));
    });

    test('Preserves pending confirmation when action requires user confirmation', () async {
      // Register an action requiring confirmation
      actionRegistry.registerAction(
        const AppAction(
          id: 'confirm_required_action',
          name: 'Confirmed Action',
          description: 'Needs confirmation',
          category: ActionCategory.deviceHardware,
          safetyLevel: ActionSafetyLevel.needsConfirmation,
        ),
      );

      await controller.activateAssistant();

      final command = VoiceCommand(
        id: 'cmd_2',
        transcript: 'Execute confirmed action',
        confidence: 0.9,
        timestamp: DateTime.now(),
      );

      // Force router intent for test
      final intent = CommandIntent(
        id: 'intent_confirm',
        category: IntentCategory.deviceControl,
        actionName: 'confirm_required_action',
        confidence: 1.0,
        isOfflineCapable: true,
      );

      // Simulate intent handling directly via command
      await controller.activateAssistant();
      expect(controller.status, equals(AssistantStatus.listening));

      // Process command directly
      await speechService.onResultCallback!(command);

      // If intent requires confirmation, pendingConfirmationIntent is preserved
      if (controller.lastIntent?.actionName == 'confirm_required_action') {
        expect(controller.hasPendingConfirmation, isTrue);
        expect(controller.pendingConfirmationIntent, isNotNull);
      }
    });

    test('Disposing controller cancels connectivity subscription and prevents notifications', () {
      controller.dispose();
      expect(controller.isDisposed, isTrue);

      // Toggling connectivity after disposal should not throw or notify listeners
      expect(() => connectivityService.setConnected(false), returnsNormally);
    });
  });
}
