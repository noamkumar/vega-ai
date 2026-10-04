/// Represents an utterance captured from speech recognition.
class VoiceCommand {
  final String id;
  final String transcript;
  final double confidence;
  final DateTime timestamp;
  final String language;
  final bool isWakeWordTriggered;

  const VoiceCommand({
    required this.id,
    required this.transcript,
    required this.confidence,
    required this.timestamp,
    this.language = 'en-US',
    this.isWakeWordTriggered = false,
  });

  factory VoiceCommand.fromUtterance(String text, {double confidence = 0.95}) {
    return VoiceCommand(
      id: 'cmd_${DateTime.now().millisecondsSinceEpoch}',
      transcript: text,
      confidence: confidence,
      timestamp: DateTime.now(),
    );
  }

  VoiceCommand copyWith({
    String? id,
    String? transcript,
    double? confidence,
    DateTime? timestamp,
    String? language,
    bool? isWakeWordTriggered,
  }) {
    return VoiceCommand(
      id: id ?? this.id,
      transcript: transcript ?? this.transcript,
      confidence: confidence ?? this.confidence,
      timestamp: timestamp ?? this.timestamp,
      language: language ?? this.language,
      isWakeWordTriggered: isWakeWordTriggered ?? this.isWakeWordTriggered,
    );
  }

  @override
  String toString() =>
      'VoiceCommand(id: $id, transcript: "$transcript", confidence: $confidence, wakeWord: $isWakeWordTriggered)';
}
