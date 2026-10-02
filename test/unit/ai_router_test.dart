import 'package:flutter_test/flutter_test.dart';
import 'package:vega_ai/core/models/command_intent.dart';
import 'package:vega_ai/core/models/voice_command.dart';
import 'package:vega_ai/services/ai/ai_router.dart';
import 'package:vega_ai/services/ai/offline_ai_service.dart';
import 'package:vega_ai/services/ai/online_gemini_service.dart';
import 'package:vega_ai/services/connectivity/connectivity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AIRouter Routing Tests', () {
    late AIRouter router;
    late DefaultConnectivityService connectivity;
    late OfflineAIService offlineAI;
    late OnlineGeminiService onlineAI;

    setUp(() {
      connectivity = DefaultConnectivityService(initialConnected: true);
      offlineAI = OfflineAIService();
      onlineAI = OnlineGeminiService(); // without api key initially
      router = AIRouter(
        offlineService: offlineAI,
        onlineService: onlineAI,
        connectivityService: connectivity,
        preferOfflineFirst: true,
      );
    });

    test('Local commands resolve offline without network dependency', () async {
      final command = VoiceCommand(
        id: 'cmd_1',
        transcript: 'Turn on the flashlight',
        confidence: 0.95,
        timestamp: DateTime.now(),
      );

      final intent = await router.routeCommand(command);
      expect(intent.actionName, equals('toggle_torch'));
      expect(intent.isOfflineCapable, isTrue);
    });

    test('When offline, queries are handled strictly by offline engine', () async {
      connectivity.setConnected(false);

      final command = VoiceCommand(
        id: 'cmd_2',
        transcript: 'What is the current time?',
        confidence: 0.95,
        timestamp: DateTime.now(),
      );

      final intent = await router.routeCommand(command);
      expect(intent.actionName, equals('get_time'));
      expect(intent.isOfflineCapable, isTrue);

      final response = await router.resolveResponse(intent);
      expect(response, contains('The time is'));
    });
  });
}
