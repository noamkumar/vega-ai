import 'package:vega_ai/core/models/assistant_state.dart';
import 'package:vega_ai/core/models/command_intent.dart';
import 'package:vega_ai/core/models/execution_result.dart';

/// Represents a past voice command or assistant interaction in the activity log.
class ActivityItem {
  final String id;
  final String commandText;
  final String responseText;
  final IntentCategory category;
  final bool isOffline;
  final ExecutionStatus status;
  final DateTime timestamp;

  const ActivityItem({
    required this.id,
    required this.commandText,
    required this.responseText,
    required this.category,
    required this.isOffline,
    required this.status,
    required this.timestamp,
  });

  String get timeFormatted {
    final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final ampm = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }
}
