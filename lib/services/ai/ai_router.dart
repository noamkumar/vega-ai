import 'package:vega_ai/core/models/command_intent.dart';
import 'package:vega_ai/core/models/voice_command.dart';
import 'package:vega_ai/core/utils/logger.dart';
import 'package:vega_ai/services/ai/offline_ai_service.dart';
import 'package:vega_ai/services/ai/online_gemini_service.dart';
import 'package:vega_ai/services/connectivity/connectivity_service.dart';

/// Intelligent AI Router responsible for arbitrating between offline local AI
/// and cloud Gemini AI based on network connectivity and intent complexity.
class AIRouter {
  static const _logger = VegaLogger('AIRouter');

  final OfflineAIService _offlineService;
  final OnlineGeminiService _onlineService;
  final ConnectivityService _connectivityService;

  bool _preferOfflineFirst;

  AIRouter({
    required OfflineAIService offlineService,
    required OnlineGeminiService onlineService,
    required ConnectivityService connectivityService,
    bool preferOfflineFirst = true,
  })  : _offlineService = offlineService,
        _onlineService = onlineService,
        _connectivityService = connectivityService,
        _preferOfflineFirst = preferOfflineFirst;

  bool get preferOfflineFirst => _preferOfflineFirst;
  set preferOfflineFirst(bool value) => _preferOfflineFirst = value;

  /// Analyzes a voice command and routes it to the optimal AI pipeline.
  Future<CommandIntent> routeCommand(VoiceCommand command) async {
    final isConnected = await _connectivityService.isConnected;

    // 1. If device is offline, route exclusively through offline engine
    if (!isConnected) {
      _logger.info('Device is offline. Routing directly to offline rule engine.');
      return _offlineService.parseIntent(command);
    }

    // 2. If user prefers offline-first, attempt local matching first
    if (_preferOfflineFirst) {
      final localIntent = await _offlineService.parseIntent(command);

      // If local intent matched a known action with high confidence, use it immediately
      if (localIntent.isOfflineCapable && localIntent.category != IntentCategory.unknown) {
        _logger.info('Intent resolved offline with confidence ${localIntent.confidence}');
        return localIntent;
      }
    }

    // 3. Fallback or conversational route to Online Gemini
    if (_onlineService.hasValidApiKey) {
      _logger.info('Routing to Gemini Online Cloud engine.');
      try {
        return await _onlineService.parseIntent(command);
      } catch (e) {
        _logger.warning('Online intent resolution failed, falling back to offline: $e');
        return _offlineService.parseIntent(command);
      }
    } else {
      _logger.info('Gemini API key not configured. Falling back to offline engine.');
      return _offlineService.parseIntent(command);
    }
  }

  /// Synthesizes the textual response using the appropriate backend.
  Future<String> resolveResponse(CommandIntent intent) async {
    final isConnected = await _connectivityService.isConnected;

    if (intent.isOfflineCapable || !isConnected || !_onlineService.hasValidApiKey) {
      return _offlineService.generateResponse(intent);
    }

    try {
      return await _onlineService.generateResponse(intent);
    } catch (e) {
      _logger.warning('Gemini response generation failed, using offline fallback: $e');
      return _offlineService.generateResponse(intent);
    }
  }
}
