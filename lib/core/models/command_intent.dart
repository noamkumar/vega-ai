/// Broad category of intent recognized by VEGA AI.
enum IntentCategory {
  /// Direct device automation (e.g. toggle flashlight, adjust brightness).
  deviceControl,

  /// App interaction (e.g. open camera, launch whatsapp).
  appLaunch,

  /// Information queries that can be answered offline (e.g. time, battery, date).
  offlineQuery,

  /// Complex conversational, knowledge, or generative reasoning requiring Gemini API.
  conversationalAI,

  /// Unrecognized or ambiguous input.
  unknown,
}

/// Structured intent extracted from a [VoiceCommand].
class CommandIntent {
  final String id;
  final IntentCategory category;
  final String actionName;
  final Map<String, dynamic> parameters;
  final double confidence;
  final bool isOfflineCapable;
  final bool requiresConfirmation;

  const CommandIntent({
    required this.id,
    required this.category,
    required this.actionName,
    this.parameters = const {},
    required this.confidence,
    required this.isOfflineCapable,
    this.requiresConfirmation = false,
  });

  factory CommandIntent.unknown(String rawQuery) {
    return CommandIntent(
      id: 'unknown_${DateTime.now().millisecondsSinceEpoch}',
      category: IntentCategory.unknown,
      actionName: 'none',
      parameters: {'raw': rawQuery},
      confidence: 0.0,
      isOfflineCapable: true,
      requiresConfirmation: false,
    );
  }

  @override
  String toString() =>
      'CommandIntent(category: $category, action: $actionName, offline: $isOfflineCapable)';
}
