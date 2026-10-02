/// Global configuration parameters and defaults for VEGA AI.
class AppConfig {
  final String appName;
  final String appVersion;
  final bool enableOfflineFirstByDefault;
  final String defaultWakeWord;

  const AppConfig({
    this.appName = 'VEGA AI',
    this.appVersion = '1.0.0',
    this.enableOfflineFirstByDefault = true,
    this.defaultWakeWord = 'Hey Vega',
  });
}
