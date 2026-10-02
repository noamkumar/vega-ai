import 'package:flutter/services.dart';
import 'package:vega_ai/core/errors/failures.dart';
import 'package:vega_ai/core/models/command_intent.dart';
import 'package:vega_ai/core/models/execution_result.dart';
import 'package:vega_ai/core/platform/platform_channels.dart';
import 'package:vega_ai/core/utils/logger.dart';
import 'package:vega_ai/features/automation/models/app_action.dart';

/// Central safe registry for authorized Android device integrations.
///
/// Enforces strict validation, security policies, parameter checking,
/// and prevents arbitrary or unapproved command execution.
class ActionRegistry {
  static const _logger = VegaLogger('ActionRegistry');

  final Map<String, AppAction> _actions = {};

  ActionRegistry() {
    _registerDefaultApprovedActions();
  }

  void _registerDefaultApprovedActions() {
    // MVP Action 1: Torch / Flashlight control
    registerAction(
      const AppAction(
        id: 'toggle_torch',
        name: 'Flashlight Control',
        description: 'Toggle the device camera flashlight on or off.',
        category: ActionCategory.deviceHardware,
        safetyLevel: ActionSafetyLevel.safe,
      ),
    );

    // MVP Action 2: Battery diagnostics
    registerAction(
      const AppAction(
        id: 'get_battery_level',
        name: 'Battery Diagnostics',
        description: 'Query current battery percentage and charging level.',
        category: ActionCategory.systemInfo,
        safetyLevel: ActionSafetyLevel.safe,
      ),
    );

    // Security Verification Action: Blocked critical system operation
    registerAction(
      const AppAction(
        id: 'system_factory_reset',
        name: 'Factory Reset',
        description: 'Critical device security operation.',
        category: ActionCategory.deviceHardware,
        safetyLevel: ActionSafetyLevel.restricted,
        isEnabled: false,
      ),
    );
  }

  void registerAction(AppAction action) {
    _actions[action.id] = action;
  }

  List<AppAction> getAllActions() => _actions.values.toList();

  List<AppAction> getApprovedActions() =>
      _actions.values.where((a) => a.isEnabled && !a.safetyLevel.isRestricted).toList();

  AppAction? findAction(String id) => _actions[id];

  /// Validates an intent against the action registry for safety and executes via platform channels.
  Future<ExecutionResult> executeSafely(CommandIntent intent) async {
    final action = findAction(intent.actionName);

    // Security Check 1: Deny any intent not found in the whitelist
    if (action == null) {
      _logger.warning('Attempted to execute unapproved action: ${intent.actionName}');
      return ExecutionResult.failure(
        'Action "${intent.actionName}" is not registered in the safe action registry.',
        failure: PlatformAutomationFailure(
          'Action not recognized in registry',
          actionId: intent.actionName,
        ),
      );
    }

    // Security Check 2: Deny strictly restricted operations
    if (action.safetyLevel.isRestricted || !action.isEnabled) {
      _logger.warning('SECURITY POLICY: Execution of restricted action blocked: ${action.id}');
      return ExecutionResult.failure(
        'Action "${action.name}" is restricted by device security policy.',
        failure: PlatformAutomationFailure(
          'Restricted action blocked by policy',
          actionId: action.id,
        ),
      );
    }

    // Security Check 3: Flag sensitive actions that require user confirmation
    if (action.safetyLevel.requiresConfirmation) {
      _logger.info('Action requires confirmation: ${action.name}');
      return ExecutionResult.requiresConfirmation(
        'Are you sure you want to proceed with ${action.name}?',
        data: {'actionId': action.id, 'parameters': intent.parameters},
      );
    }

    // Execution via Android Platform Channels with full parameter validation
    try {
      _logger.info('Dispatching action "${action.id}" to platform channel');

      if (action.id == 'toggle_torch') {
        final rawState = intent.parameters['state'];
        if (rawState is! bool) {
          _logger.warning('Invalid parameter for toggle_torch: expected bool, got $rawState');
          return ExecutionResult.failure(
            'Flashlight command requires a boolean "state" parameter.',
            failure: PlatformAutomationFailure(
              'Missing or invalid boolean state parameter',
              actionId: action.id,
            ),
          );
        }

        final success = await PlatformChannels.hardware.invokeMethod<bool>(
          PlatformChannels.methodToggleTorch,
          {'enabled': rawState},
        );

        if (success == true) {
          return ExecutionResult.success(
            rawState ? 'Flashlight enabled, sir.' : 'Flashlight deactivated.',
            data: {'torch': rawState},
          );
        } else {
          return ExecutionResult.failure(
            'Failed to change flashlight state.',
            failure: PlatformAutomationFailure(
              'Platform returned false for toggleTorch',
              actionId: action.id,
            ),
          );
        }
      }

      if (action.id == 'get_battery_level') {
        final battery = await PlatformChannels.hardware.invokeMethod<int>(
          PlatformChannels.methodGetBatteryLevel,
        );

        if (battery != null && battery >= 0) {
          return ExecutionResult.success(
            'Current battery level is $battery%.',
            data: {'battery': battery},
          );
        } else {
          return ExecutionResult.failure(
            'Could not retrieve battery telemetry.',
            failure: PlatformAutomationFailure(
              'Battery level returned null or invalid value',
              actionId: action.id,
            ),
          );
        }
      }

      // If an action has no handler
      return ExecutionResult.failure(
        'No platform implementation found for ${action.name}.',
        failure: PlatformAutomationFailure(
          'Missing platform handler for action',
          actionId: action.id,
        ),
      );
    } on PlatformException catch (e, stack) {
      _logger.error('PlatformException executing "${action.id}": ${e.code} - ${e.message}', e, stack);
      if (e.code == 'PERMISSION_DENIED') {
        return ExecutionResult.failure(
          'Permission was denied for ${action.name}.',
          failure: SecurityPermissionFailure(
            e.message ?? 'Permission denied by Android system',
            requiredPermission: e.details?.toString() ?? 'unknown',
            code: e.code,
          ),
        );
      } else if (e.code == 'UNAVAILABLE' || e.code == 'HARDWARE_NOT_FOUND') {
        return ExecutionResult.failure(
          '${action.name} is not available on this device.',
          failure: PlatformAutomationFailure(
            e.message ?? 'Hardware unit not found',
            actionId: action.id,
            code: e.code,
          ),
        );
      } else if (e.code == 'UNSUPPORTED') {
        return ExecutionResult.failure(
          '${action.name} is not supported on this Android version.',
          failure: PlatformAutomationFailure(
            e.message ?? 'Operation unsupported on this OS',
            actionId: action.id,
            code: e.code,
          ),
        );
      }

      return ExecutionResult.failure(
        'Failed to execute ${action.name}: ${e.message ?? "Platform error"}',
        failure: PlatformAutomationFailure(
          e.message ?? 'Platform invocation failed',
          actionId: action.id,
          code: e.code,
          cause: e,
        ),
      );
    } on MissingPluginException catch (e, stack) {
      _logger.error('MissingPluginException executing "${action.id}"', e, stack);
      return ExecutionResult.failure(
        '${action.name} is not implemented in the current Android build.',
        failure: PlatformAutomationFailure(
          'Platform channel not registered in native engine',
          actionId: action.id,
          cause: e,
        ),
      );
    } catch (e, stack) {
      _logger.error('Unexpected error executing action "${action.id}"', e, stack);
      return ExecutionResult.failure(
        'An unexpected error occurred while executing ${action.name}.',
        failure: PlatformAutomationFailure(
          e.toString(),
          actionId: action.id,
          cause: e,
        ),
      );
    }
  }
}
