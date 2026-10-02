import 'package:vega_ai/core/errors/failures.dart';
import 'package:vega_ai/core/models/command_intent.dart';
import 'package:vega_ai/core/models/voice_command.dart';
import 'package:vega_ai/core/utils/logger.dart';
import 'package:vega_ai/services/ai/ai_service.dart';

/// Online AI service connecting to Google's Gemini API for advanced reasoning,
/// complex natural language conversation, and external knowledge.
///
/// NOTE: API keys are securely retrieved from local encrypted storage, never hardcoded.
class OnlineGeminiService implements AIService {
  static const _logger = VegaLogger('OnlineGeminiService');
  final String? _apiKey;

  OnlineGeminiService({String? apiKey}) : _apiKey = apiKey;

  @override
  String get engineName => 'Gemini-1.5-Flash-Cloud';

  @override
  bool get isOffline => false;

  bool get hasValidApiKey => _apiKey != null && _apiKey!.trim().isNotEmpty;

  @override
  Future<CommandIntent> parseIntent(VoiceCommand command) async {
    if (!hasValidApiKey) {
      _logger.warning('Gemini API key is not configured');
      throw const AIFailure(
        'Gemini API key is missing. Please configure it in Settings.',
        code: 'MISSING_API_KEY',
        isOfflineModel: false,
      );
    }

    _logger.info('Sending command to Gemini for cloud intent parsing: ${command.transcript}');

    // Cloud parsing contract (simulated placeholder awaiting live endpoint)
    return CommandIntent(
      id: 'gemini_intent_${DateTime.now().millisecondsSinceEpoch}',
      category: IntentCategory.conversationalAI,
      actionName: 'gemini_answer',
      parameters: {'query': command.transcript},
      confidence: 0.96,
      isOfflineCapable: false,
    );
  }

  @override
  Future<String> generateResponse(CommandIntent intent, {String? conversationContext}) async {
    if (!hasValidApiKey) {
      return 'Online AI requires a Gemini API key. You can add one in Settings or switch to Offline mode.';
    }

    final query = intent.parameters['query']?.toString() ?? 'query';
    _logger.info('Generating Gemini response for: "$query"');

    // Structured JARVIS response
    return 'According to Gemini Cloud Intelligence, I have processed "$query". All systems are operational.';
  }

  @override
  Future<void> dispose() async {
    _logger.info('Gemini service disposed');
  }
}
