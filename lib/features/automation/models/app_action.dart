/// Security level assigned to an automation action.
enum ActionSafetyLevel {
  /// Harmless read operations or standard non-destructive controls.
  safe,

  /// Actions that perform state changes, send messages, or modify data.
  /// Requires explicit user visual or vocal confirmation.
  needsConfirmation,

  /// Critical device operations (e.g., shell access, sensitive security settings)
  /// that are strictly blocked by VEGA AI.
  restricted;

  bool get isRestricted => this == ActionSafetyLevel.restricted;
  bool get requiresConfirmation => this == ActionSafetyLevel.needsConfirmation;
  bool get isSafe => this == ActionSafetyLevel.safe;
}

/// Category of the automation action.
enum ActionCategory {
  deviceHardware,
  mediaAudio,
  appShortcuts,
  systemInfo,
  communication,
}

/// Represents an approved, safe Android integration action.
class AppAction {
  final String id;
  final String name;
  final String description;
  final ActionCategory category;
  final ActionSafetyLevel safetyLevel;
  final List<String> requiredAndroidPermissions;
  final bool isEnabled;
  final String? appPackageName;

  const AppAction({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.safetyLevel,
    this.requiredAndroidPermissions = const [],
    this.isEnabled = true,
    this.appPackageName,
  });

  AppAction copyWith({
    String? id,
    String? name,
    String? description,
    ActionCategory? category,
    ActionSafetyLevel? safetyLevel,
    List<String>? requiredAndroidPermissions,
    bool? isEnabled,
    String? appPackageName,
  }) {
    return AppAction(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      safetyLevel: safetyLevel ?? this.safetyLevel,
      requiredAndroidPermissions:
          requiredAndroidPermissions ?? this.requiredAndroidPermissions,
      isEnabled: isEnabled ?? this.isEnabled,
      appPackageName: appPackageName ?? this.appPackageName,
    );
  }
}
