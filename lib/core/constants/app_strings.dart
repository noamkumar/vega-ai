/// Global UI strings and prompt templates for VEGA AI.
abstract class AppStrings {
  static const String appName = 'VEGA AI';
  static const String appTagline = 'JARVIS-inspired Voice Assistant';

  // Assistant Status Labels
  static const String statusIdle = 'Awaiting command';
  static const String statusListening = 'Listening...';
  static const String statusProcessing = 'Processing intent...';
  static const String statusSpeaking = 'Responding...';

  // Status Badges
  static const String badgeIdle = 'IDLE';
  static const String badgeListening = 'LISTENING';
  static const String badgeProcessing = 'PROCESSING';
  static const String badgeSpeaking = 'SPEAKING';

  // Connectivity
  static const String modeOnline = 'Cloud (Gemini)';
  static const String modeOffline = 'Local (Offline AI)';
  static const String offlineBadge = 'OFFLINE';
  static const String onlineBadge = 'ONLINE';

  // Action Bar Labels
  static const String shortcutsTitle = 'System Controls';
  static const String actionSettings = 'Settings';
  static const String actionApprovedApps = 'Approved Apps';
  static const String actionHistory = 'Activity History';

  // Guidance Prompts
  static const String defaultPrompt = 'Tap the orb or say "Hey Vega" to activate';
  static const String promptListening = 'VEGA is listening...';
  static const String promptProcessing = 'Evaluating command via hybrid engine...';

  // Error Messages
  static const String errorGeneral = 'An unexpected error occurred.';
  static const String errorSpeechInit = 'Failed to initialize speech recognition engine.';
  static const String errorOfflineRouting = 'Offline model could not resolve intent.';
}
