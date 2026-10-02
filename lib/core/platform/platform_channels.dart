import 'package:flutter/services.dart';

/// Centralized registry for Flutter <-> Android Kotlin platform channels.
abstract class PlatformChannels {
  // Method Channel Names
  static const String automationChannelName = 'com.vega.ai/automation';
  static const String hardwareChannelName = 'com.vega.ai/hardware';
  static const String wakeWordChannelName = 'com.vega.ai/wake_word';

  // Method Channels
  static const MethodChannel automation = MethodChannel(automationChannelName);
  static const MethodChannel hardware = MethodChannel(hardwareChannelName);
  static const MethodChannel wakeWord = MethodChannel(wakeWordChannelName);

  // Method Names - Automation
  static const String methodGetAvailableActions = 'getAvailableActions';
  static const String methodExecuteAction = 'executeAction';
  static const String methodCheckPermission = 'checkActionPermission';

  // Method Names - Hardware
  static const String methodIsOfflineEngineReady = 'isOfflineEngineReady';
  static const String methodGetBatteryLevel = 'getBatteryLevel';
  static const String methodToggleTorch = 'toggleTorch';

  // Method Names - Wake Word
  static const String methodStartWakeWordListening = 'startWakeWordListening';
  static const String methodStopWakeWordListening = 'stopWakeWordListening';
}
