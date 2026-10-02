/// Represents the runtime voice interaction state of VEGA AI.
enum AssistantStatus {
  /// Waiting for user initiation or wake-word detection.
  idle,

  /// Actively capturing voice input through microphone.
  listening,

  /// Evaluating speech transcript via local rule engine or Gemini API.
  processing,

  /// Synthesizing and delivering voice response (TTS) or executing feedback.
  speaking;

  bool get isIdle => this == AssistantStatus.idle;
  bool get isListening => this == AssistantStatus.listening;
  bool get isProcessing => this == AssistantStatus.processing;
  bool get isSpeaking => this == AssistantStatus.speaking;

  String get displayName {
    switch (this) {
      case AssistantStatus.idle:
        return 'Idle';
      case AssistantStatus.listening:
        return 'Listening';
      case AssistantStatus.processing:
        return 'Processing';
      case AssistantStatus.speaking:
        return 'Speaking';
    }
  }
}
