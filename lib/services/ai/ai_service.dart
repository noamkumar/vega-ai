import 'package:vega_ai/core/models/command_intent.dart';
import 'package:vega_ai/core/models/voice_command.dart';

/// Contract for AI reasoning engines (both local and cloud).
abstract class AIService {
  /// Unique identifier of the engine (e.g. 'gemini-1.5-flash', 'local-rule-engine', 'tiny-llama-q4').
  String get engineName;

  /// Whether this service operates completely offline without network access.
  bool get isOffline;

  /// Parses a raw voice command into an actionable [CommandIntent].
  Future<CommandIntent> parseIntent(VoiceCommand command);

  /// Generates a conversational or contextual response given an intent and conversational context.
  Future<String> generateResponse(CommandIntent intent, {String? conversationContext});

  /// Releases resources when assistant is terminated.
  Future<void> dispose();
}
