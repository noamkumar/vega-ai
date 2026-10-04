/// Failure base class and specific failure domains for VEGA AI.
abstract class Failure {
  final String message;
  final String? code;
  final Object? cause;

  const Failure(this.message, {this.code, this.cause});

  @override
  String toString() => '$runtimeType: $message (code: $code)';
}

/// Thrown when local or online AI processing fails.
class AIFailure extends Failure {
  final bool isOfflineModel;

  const AIFailure(
    super.message, {
    super.code,
    super.cause,
    this.isOfflineModel = false,
  });
}

/// Thrown when Speech-To-Text or Wake Word recognition fails.
class SpeechFailure extends Failure {
  const SpeechFailure(super.message, {super.code, super.cause});
}

/// Thrown when Audio synthesis (TTS) or earcon playback fails.
class AudioFailure extends Failure {
  const AudioFailure(super.message, {super.code, super.cause});
}

/// Thrown when an Android Automation or Platform Channel interaction fails.
class PlatformAutomationFailure extends Failure {
  final String actionId;

  const PlatformAutomationFailure(
    super.message, {
    required this.actionId,
    super.code,
    super.cause,
  });
}

/// Thrown when an action requires user permission or security confirmation.
class SecurityPermissionFailure extends Failure {
  final String requiredPermission;

  const SecurityPermissionFailure(
    super.message, {
    required this.requiredPermission,
    super.code,
  });
}

/// Thrown when local database or key-value storage operations fail.
class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.code, super.cause});
}

/// Thrown when network connectivity or cloud API transport fails.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code, super.cause});
}

