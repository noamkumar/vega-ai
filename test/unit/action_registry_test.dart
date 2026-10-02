import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vega_ai/core/models/command_intent.dart';
import 'package:vega_ai/core/models/execution_result.dart';
import 'package:vega_ai/core/platform/platform_channels.dart';
import 'package:vega_ai/features/automation/action_registry.dart';
import 'package:vega_ai/features/automation/models/app_action.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ActionRegistry Security & Execution Tests', () {
    late ActionRegistry registry;

    setUp(() {
      registry = ActionRegistry();
    });

    test('Loads pre-approved MVP actions', () {
      final actions = registry.getAllActions();
      expect(actions.isNotEmpty, isTrue);

      final torchAction = registry.findAction('toggle_torch');
      expect(torchAction, isNotNull);
      expect(torchAction!.safetyLevel, equals(ActionSafetyLevel.safe));

      final batteryAction = registry.findAction('get_battery_level');
      expect(batteryAction, isNotNull);
      expect(batteryAction!.safetyLevel, equals(ActionSafetyLevel.safe));
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
      expect(result.status, equals(ExecutionStatus.failed));
    });

    test('Unregistered arbitrary action is rejected', () async {
      const unknownIntent = CommandIntent(
        id: 'test_2',
        category: IntentCategory.deviceControl,
        actionName: 'arbitrary_shell_command',
        confidence: 1.0,
        isOfflineCapable: true,
      );

      final result = await registry.executeSafely(unknownIntent);
      expect(result.isFailed, isTrue);
      expect(result.speechFeedback, contains('not registered'));
      expect(result.status, equals(ExecutionStatus.failed));
    });

    test('Parameter validation: toggle_torch fails if state parameter is missing or non-boolean', () async {
      const invalidIntent = CommandIntent(
        id: 'test_3',
        category: IntentCategory.deviceControl,
        actionName: 'toggle_torch',
        parameters: {'state': 'invalid_string'}, // Not a boolean
        confidence: 1.0,
        isOfflineCapable: true,
      );

      final result = await registry.executeSafely(invalidIntent);
      expect(result.isFailed, isTrue);
      expect(result.speechFeedback, contains('boolean'));
      expect(result.status, equals(ExecutionStatus.failed));
    });

    test('Platform failure is never reported as success', () async {
      // Mock hardware channel to throw a PlatformException
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(PlatformChannels.hardware, (MethodCall methodCall) async {
        throw PlatformException(
          code: 'UNAVAILABLE',
          message: 'Camera flash hardware not available on device',
        );
      });

      const torchIntent = CommandIntent(
        id: 'test_4',
        category: IntentCategory.deviceControl,
        actionName: 'toggle_torch',
        parameters: {'state': true},
        confidence: 1.0,
        isOfflineCapable: true,
      );

      final result = await registry.executeSafely(torchIntent);
      expect(result.isFailed, isTrue);
      expect(result.status, equals(ExecutionStatus.failed));
      expect(result.speechFeedback, contains('not available'));

      // Clean up mock handler
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(PlatformChannels.hardware, null);
    });

    test('Actions requiring confirmation return requiresUserConfirmation status', () async {
      // Register custom sensitive action for testing confirmation pipeline
      registry.registerAction(
        const AppAction(
          id: 'test_sensitive_action',
          name: 'Sensitive Operation',
          description: 'Requires user confirmation',
          category: ActionCategory.deviceHardware,
          safetyLevel: ActionSafetyLevel.needsConfirmation,
        ),
      );

      const confirmIntent = CommandIntent(
        id: 'test_5',
        category: IntentCategory.deviceControl,
        actionName: 'test_sensitive_action',
        confidence: 1.0,
        isOfflineCapable: true,
      );

      final result = await registry.executeSafely(confirmIntent);
      expect(result.status, equals(ExecutionStatus.requiresUserConfirmation));
      expect(result.speechFeedback, contains('Are you sure'));
    });
  });
}
