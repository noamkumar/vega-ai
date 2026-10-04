import 'package:flutter/services.dart';

/// Centralized registry for Flutter <-> Android Kotlin platform channels.
abstract class PlatformChannels {
  // Method Channel Names
  static const String automationChannelName = 'com.vega.ai/automation';
  static const String hardwareChannelName = 'com.vega.ai/hardware';
  static const String wakeWordChannelName = 'com.vega.ai/wake_word';
  static const String speechChannelName = 'com.vega.ai/speech';
  static const String ttsChannelName = 'com.vega.ai/tts';

  // Method Channels
  static const MethodChannel automation = MethodChannel(automationChannelName);
  static const MethodChannel hardware = MethodChannel(hardwareChannelName);
  static const MethodChannel wakeWord = MethodChannel(wakeWordChannelName);
  static const MethodChannel speech = MethodChannel(speechChannelName);
  static const MethodChannel tts = MethodChannel(ttsChannelName);

  // Method Names - Automation
  static const String methodGetAvailableActions = 'getAvailableActions';
  static const String methodExecuteAction = 'executeAction';
  static const String methodCheckPermission = 'checkActionPermission';
  static const String methodLaunchApp = 'launchApp';
  static const String methodGetInstalledApps = 'getInstalledApps';
  static const String methodOpenCamera = 'openCamera';
  static const String methodOpenSettings = 'openSettings';
  static const String methodSetVolume = 'setVolume';
  static const String methodGetVolume = 'getVolume';
  static const String methodControlMedia = 'controlMedia';
  static const String methodPlayMusic = 'playMusic';
  static const String methodSetTimer = 'setTimer';
  static const String methodSetAlarm = 'setAlarm';

  // Method Names - Hardware
  static const String methodIsOfflineEngineReady = 'isOfflineEngineReady';
  static const String methodGetBatteryLevel = 'getBatteryLevel';
  static const String methodToggleTorch = 'toggleTorch';

  // Method Names - Speech
  static const String methodStartListening = 'startListening';
  static const String methodStopListening = 'stopListening';

  // Method Names - TTS
  static const String methodSpeak = 'speak';
  static const String methodStopTTS = 'stop';
  static const String methodSetVoiceParameters = 'setVoiceParameters';

  // Method Names - Wake Word
  static const String methodStartWakeWordListening = 'startWakeWordListening';
  static const String methodStopWakeWordListening = 'stopWakeWordListening';
}
