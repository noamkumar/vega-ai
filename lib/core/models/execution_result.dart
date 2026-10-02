import 'package:vega_ai/core/errors/failures.dart';

enum ExecutionStatus {
  success,
  failed,
  requiresUserConfirmation,
  unsupported,
}

/// Result returned after executing a [CommandIntent] via local hardware or AI.
class ExecutionResult {
  final ExecutionStatus status;
  final String speechFeedback;
  final String? displayTitle;
  final Map<String, dynamic> data;
  final Failure? failure;
  final DateTime executedAt;

  const ExecutionResult({
    required this.status,
    required this.speechFeedback,
    this.displayTitle,
    this.data = const {},
    this.failure,
    required this.executedAt,
  });

  factory ExecutionResult.success(String feedback, {Map<String, dynamic> data = const {}}) {
    return ExecutionResult(
      status: ExecutionStatus.success,
      speechFeedback: feedback,
      data: data,
      executedAt: DateTime.now(),
    );
  }

  factory ExecutionResult.failure(String feedback, {Failure? failure}) {
    return ExecutionResult(
      status: ExecutionStatus.failed,
      speechFeedback: feedback,
      failure: failure,
      executedAt: DateTime.now(),
    );
  }

  factory ExecutionResult.requiresConfirmation(String prompt, {Map<String, dynamic> data = const {}}) {
    return ExecutionResult(
      status: ExecutionStatus.requiresUserConfirmation,
      speechFeedback: prompt,
      data: data,
      executedAt: DateTime.now(),
    );
  }

  bool get isSuccess => status == ExecutionStatus.success;
  bool get isFailed => status == ExecutionStatus.failed;
}
