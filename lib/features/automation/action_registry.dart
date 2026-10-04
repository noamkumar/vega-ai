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
    // Action 1: Torch / Flashlight control
    registerAction(
      const AppAction(
        id: 'toggle_torch',
        name: 'Flashlight Control',
        description: 'Toggle the device camera flashlight on or off.',
        category: ActionCategory.deviceHardware,
        safetyLevel: ActionSafetyLevel.safe,
      ),
    );

    // Action 2: Battery diagnostics
    registerAction(
      const AppAction(
        id: 'get_battery_level',
        name: 'Battery Diagnostics',
        description: 'Query current battery percentage and charging level.',
        category: ActionCategory.systemInfo,
        safetyLevel: ActionSafetyLevel.safe,
      ),
    );

    // Action 3: App Launching
    registerAction(
      const AppAction(
        id: 'launch_app',
        name: 'Launch Application',
        description: 'Launch an installed Android application by name or package.',
        category: ActionCategory.appShortcuts,
        safetyLevel: ActionSafetyLevel.safe,
      ),
    );

    // Action 4: Camera Launch
    registerAction(
      const AppAction(
        id: 'open_camera',
        name: 'Camera Launch',
        description: 'Launch the native camera application.',
        category: ActionCategory.deviceHardware,
        safetyLevel: ActionSafetyLevel.safe,
      ),
    );

    // Action 5: System Settings
    registerAction(
      const AppAction(
        id: 'open_settings',
        name: 'System Settings',
        description: 'Open device settings (Wi-Fi, Bluetooth, Sound, Display).',
        category: ActionCategory.systemInfo,
        safetyLevel: ActionSafetyLevel.safe,
      ),
    );

    // Action 6: Volume Control
    registerAction(
      const AppAction(
        id: 'set_volume',
        name: 'Volume Adjustment',
        description: 'Adjust device audio stream volume level.',
        category: ActionCategory.mediaAudio,
        safetyLevel: ActionSafetyLevel.safe,
      ),
    );

    // Action 7: Volume Level Query
    registerAction(
      const AppAction(
        id: 'get_volume',
        name: 'Volume Diagnostics',
        description: 'Query current volume level.',
        category: ActionCategory.systemInfo,
        safetyLevel: ActionSafetyLevel.safe,
      ),
    );

    // Action 8: Music Playback & Search
    registerAction(
      const AppAction(
        id: 'play_music',
        name: 'Music Playback',
        description: 'Search and play songs via Spotify, YouTube, or default media player.',
        category: ActionCategory.mediaAudio,
        safetyLevel: ActionSafetyLevel.safe,
      ),
    );

    // Action 9: Media Session Control
    registerAction(
      const AppAction(
        id: 'control_media',
        name: 'Media Session Control',
        description: 'Control media playback (play, pause, next, previous).',
        category: ActionCategory.mediaAudio,
        safetyLevel: ActionSafetyLevel.safe,
      ),
    );

    // Action 10: Countdown Timer
    registerAction(
      const AppAction(
        id: 'set_timer',
        name: 'Countdown Timer',
        description: 'Set a clock countdown timer.',
        category: ActionCategory.systemInfo,
        safetyLevel: ActionSafetyLevel.safe,
      ),
    );

    // Action 11: Clock Alarm
    registerAction(
      const AppAction(
        id: 'set_alarm',
        name: 'Clock Alarm',
        description: 'Set a system clock alarm.',
        category: ActionCategory.systemInfo,
        safetyLevel: ActionSafetyLevel.safe,
      ),
    );

    // Action 12: Communication / Messaging (Requires User Confirmation)
    registerAction(
      const AppAction(
        id: 'send_message',
        name: 'Send Message',
        description: 'Send SMS or chat message to a contact.',
        category: ActionCategory.communication,
        safetyLevel: ActionSafetyLevel.needsConfirmation,
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

      if (action.id == 'launch_app') {
        final pkg = intent.parameters['packageName'] as String?;
        final appName = intent.parameters['appName'] as String? ?? pkg ?? 'the requested application';
        final success = await PlatformChannels.automation.invokeMethod<bool>(
          PlatformChannels.methodLaunchApp,
          {'packageName': pkg, 'appName': appName},
        );

        if (success == true) {
          return ExecutionResult.success(
            'Opening $appName, sir.',
            data: {'appName': appName, 'packageName': pkg},
          );
        } else {
          return ExecutionResult.failure(
            'Could not open $appName.',
            failure: PlatformAutomationFailure('App launch failed', actionId: action.id),
          );
        }
      }

      if (action.id == 'open_camera') {
        final success = await PlatformChannels.automation.invokeMethod<bool>(
          PlatformChannels.methodOpenCamera,
        );

        if (success == true) {
          return ExecutionResult.success(
            'Camera activated, sir.',
            data: {'camera': true},
          );
        } else {
          return ExecutionResult.failure(
            'Failed to launch camera.',
            failure: PlatformAutomationFailure('Camera launch failed', actionId: action.id),
          );
        }
      }

      if (action.id == 'open_settings') {
        final type = intent.parameters['type'] as String? ?? 'general';
        final success = await PlatformChannels.automation.invokeMethod<bool>(
          PlatformChannels.methodOpenSettings,
          {'type': type},
        );

        if (success == true) {
          return ExecutionResult.success(
            'Opening $type settings, sir.',
            data: {'settings': type},
          );
        } else {
          return ExecutionResult.failure(
            'Failed to open settings.',
            failure: PlatformAutomationFailure('Settings launch failed', actionId: action.id),
          );
        }
      }

      if (action.id == 'set_volume') {
        final mode = intent.parameters['mode'] as String? ?? 'increase';
        final level = intent.parameters['level'] as int?;
        final success = await PlatformChannels.automation.invokeMethod<bool>(
          PlatformChannels.methodSetVolume,
          {'mode': mode, 'level': level},
        );

        if (success == true) {
          return ExecutionResult.success(
            'Audio volume adjusted, sir.',
            data: {'volumeMode': mode, 'level': level},
          );
        } else {
          return ExecutionResult.failure(
            'Failed to adjust audio volume.',
            failure: PlatformAutomationFailure('Volume adjustment failed', actionId: action.id),
          );
        }
      }

      if (action.id == 'get_volume') {
        final volumeData = await PlatformChannels.automation.invokeMethod<Map>(
          PlatformChannels.methodGetVolume,
        );

        if (volumeData != null) {
          final current = volumeData['current'];
          final max = volumeData['max'];
          return ExecutionResult.success(
            'Current audio volume is $current out of $max, sir.',
            data: {'currentVolume': current, 'maxVolume': max},
          );
        } else {
          return ExecutionResult.failure(
            'Could not retrieve volume status.',
            failure: PlatformAutomationFailure('Volume query returned null', actionId: action.id),
          );
        }
      }

      if (action.id == 'play_music') {
        final query = intent.parameters['query'] as String?;
        final app = intent.parameters['app'] as String?;
        final res = await PlatformChannels.automation.invokeMethod<Map>(
          PlatformChannels.methodPlayMusic,
          {'query': query, 'app': app},
        );

        final appName = res?['app'] as String? ?? 'media player';
        final confirmed = res?['confirmed'] == true;
        if (confirmed) {
          final feedback = query != null && query.isNotEmpty
              ? 'Playing "$query" on $appName, sir.'
              : 'Resuming music playback on $appName, sir.';
          return ExecutionResult.success(
            feedback,
            data: {'query': query, 'app': appName},
          );
        } else {
          return ExecutionResult.failure(
            'Could not initiate music playback.',
            failure: PlatformAutomationFailure('Playback not confirmed', actionId: action.id),
          );
        }
      }

      if (action.id == 'control_media') {
        final actionCmd = intent.parameters['action'] as String? ?? 'play_pause';
        final success = await PlatformChannels.automation.invokeMethod<bool>(
          PlatformChannels.methodControlMedia,
          {'action': actionCmd},
        );

        if (success == true) {
          return ExecutionResult.success(
            'Media command acknowledged, sir.',
            data: {'action': actionCmd},
          );
        } else {
          return ExecutionResult.failure(
            'Failed to dispatch media control.',
            failure: PlatformAutomationFailure('Media control returned false', actionId: action.id),
          );
        }
      }

      if (action.id == 'set_timer') {
        final seconds = (intent.parameters['seconds'] as num?)?.toInt() ?? 60;
        final message = intent.parameters['message'] as String? ?? 'VEGA Timer';
        final success = await PlatformChannels.automation.invokeMethod<bool>(
          PlatformChannels.methodSetTimer,
          {'seconds': seconds, 'message': message},
        );

        if (success == true) {
          return ExecutionResult.success(
            'Timer set for $seconds seconds, sir.',
            data: {'seconds': seconds, 'message': message},
          );
        } else {
          return ExecutionResult.failure(
            'Could not set timer.',
            failure: PlatformAutomationFailure('Timer launch failed', actionId: action.id),
          );
        }
      }

      if (action.id == 'set_alarm') {
        final hour = (intent.parameters['hour'] as num?)?.toInt() ?? 7;
        final minute = (intent.parameters['minute'] as num?)?.toInt() ?? 0;
        final message = intent.parameters['message'] as String? ?? 'VEGA Alarm';
        final success = await PlatformChannels.automation.invokeMethod<bool>(
          PlatformChannels.methodSetAlarm,
          {'hour': hour, 'minute': minute, 'message': message},
        );

        if (success == true) {
          final display = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
          return ExecutionResult.success(
            'Alarm set for $display, sir.',
            data: {'alarm': display, 'message': message},
          );
        } else {
          return ExecutionResult.failure(
            'Could not set alarm.',
            failure: PlatformAutomationFailure('Alarm launch failed', actionId: action.id),
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
      } else if (e.code == 'APP_NOT_FOUND') {
        return ExecutionResult.failure(
          'Requested application is not installed on your phone.',
          failure: PlatformAutomationFailure(
            e.message ?? 'App not found',
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
