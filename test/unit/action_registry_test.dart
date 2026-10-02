import 'package:flutter_test/flutter_test.dart';
import 'package:vega_ai/core/models/command_intent.dart';
import 'package:vega_ai/features/automation/action_registry.dart';
import 'package:vega_ai/features/automation/models/app_action.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ActionRegistry Security & Execution Tests', () {
    late ActionRegistry registry;

    setUp(() {
      registry = ActionRegistry();
    });

    test('Loads pre-approved safe actions', () {
      final actions = registry.getAllActions();
      expect(actions.isNotEmpty, isTrue);

      final torchAction = registry.findAction('toggle_torch');
      expect(torchAction, isNotNull);
      expect(torchAction!.safetyLevel, equals(ActionSafetyLevel.safe));
    });

    test('Restricted actions are strictly blocked by safety policy', () async {
      const restrictedIntent = CommandIntent(
        id: 'test_1',
        category: IntentCategory.deviceControl,
        actionName: 'system_factory_reset',
        confidence: 1.0,
        isOfflineCapable: true,
      );

      final result = await registry.executeSafely(restrictedIntent);
      expect(result.isFailed, isTrue);
      expect(result.speechFeedback, contains('restricted'));
    });

    test('Sensitive actions require user confirmation', () async {
      const confirmIntent = CommandIntent(
        id: 'test_2',
        category: IntentCategory.communication,
        actionName: 'send_sms_message',
        confidence: 1.0,
        isOfflineCapable: true,
      );

      final result = await registry.executeSafely(confirmIntent);
      expect(result.status.name, equals('requiresUserConfirmation'));
    });

    test('Unregistered arbitrary action is rejected', () async {
      const unknownIntent = CommandIntent(
        id: 'test_3',
        category: IntentCategory.deviceControl,
        actionName: 'arbitrary_shell_command',
        confidence: 1.0,
        isOfflineCapable: true,
      );

      final result = await registry.executeSafely(unknownIntent);
      expect(result.isFailed, isTrue);
      expect(result.speechFeedback, contains('not registered'));
    });
  });
}
