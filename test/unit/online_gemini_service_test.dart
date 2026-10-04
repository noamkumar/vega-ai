import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vega_ai/core/errors/failures.dart';
import 'package:vega_ai/core/models/command_intent.dart';
import 'package:vega_ai/core/models/voice_command.dart';
import 'package:vega_ai/services/ai/ai_router.dart';
import 'package:vega_ai/services/ai/offline_ai_service.dart';
import 'package:vega_ai/services/ai/online_gemini_service.dart';
import 'package:vega_ai/services/connectivity/connectivity_service.dart';

/// Helper to mock HTTP requests for OnlineGeminiService
class MockHttpOverrides extends HttpOverrides {
  final int statusCode;
  final String responseBody;
  final bool shouldTimeout;
  final bool shouldThrowSocketException;
  Uri? lastRequestedUri;
  String? lastRequestBody;

  MockHttpOverrides({
    this.statusCode = 200,
    this.responseBody = '{}',
    this.shouldTimeout = false,
    this.shouldThrowSocketException = false,
  });

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient(this);
  }
}

class _MockHttpClient implements HttpClient {
  final MockHttpOverrides overrides;
  _MockHttpClient(this.overrides);

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    overrides.lastRequestedUri = url;
    if (overrides.shouldThrowSocketException) {
      throw const SocketException('Connection refused');
    }
    return _MockHttpClientRequest(overrides);
  }

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientRequest implements HttpClientRequest {
  final MockHttpOverrides overrides;
  final List<int> _bodyBytes = [];
  final HttpHeaders _headers = _MockHttpHeaders();

  _MockHttpClientRequest(this.overrides);

  @override
  HttpHeaders get headers => _headers;

  @override
  void write(Object? obj) {
    _bodyBytes.addAll(utf8.encode(obj.toString()));
  }

  @override
  Future<HttpClientResponse> close() async {
    overrides.lastRequestBody = utf8.decode(_bodyBytes);
    if (overrides.shouldTimeout) {
      throw TimeoutException('Request timed out');
    }
    return _MockHttpClientResponse(overrides.statusCode, overrides.responseBody);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  final int statusCode;
  final String body;

  _MockHttpClientResponse(this.statusCode, this.body);

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream.value(utf8.encode(body)).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpHeaders implements HttpHeaders {
  final Map<String, String> _map = {};

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _map[name] = value.toString();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('OnlineGeminiService Unit Tests', () {
    test('Throws AIFailure when API key is missing', () async {
      final service = OnlineGeminiService(apiKey: '');
      final command = VoiceCommand.fromUtterance('tell me a joke');

      expect(
        () => service.parseIntent(command),
        throwsA(
          isA<AIFailure>()
              .having((e) => e.code, 'code', 'MISSING_API_KEY')
              .having((e) => e.isOfflineModel, 'isOfflineModel', false),
        ),
      );
    });

    test('Parses structured JSON response for device action', () async {
      final geminiResponse = jsonEncode({
        "candidates": [
          {
            "content": {
              "parts": [
                {
                  "text": jsonEncode({
                    "thought": "User wants to turn on the torch",
                    "action": "toggle_torch",
                    "parameters": {"state": true},
                    "speechFeedback": "Flashlight activated, sir."
                  })
                }
              ]
            }
          }
        ]
      });

      final overrides = MockHttpOverrides(statusCode: 200, responseBody: geminiResponse);
      await HttpOverrides.runWithHttpOverrides(() async {
        final service = OnlineGeminiService(apiKey: 'AIzaSyFakeKey123', modelId: 'gemini-1.5-flash');
        final command = VoiceCommand.fromUtterance('Turn on the flashlight');

        final intent = await service.parseIntent(command);

        expect(intent.actionName, equals('toggle_torch'));
        expect(intent.category, equals(IntentCategory.deviceControl));
        expect(intent.parameters['state'], isTrue);
        expect(intent.parameters['_speechFeedback'], equals('Flashlight activated, sir.'));
        expect(overrides.lastRequestedUri?.queryParameters['key'], equals('AIzaSyFakeKey123'));
        expect(overrides.lastRequestedUri?.path, contains('gemini-1.5-flash'));
      }, overrides);
    });

    test('Cleans markdown code fences before parsing JSON', () async {
      final rawWithFences = '```json\n{"action": "open_camera", "parameters": {}, "speechFeedback": "Opening camera."}\n```';
      final cleaned = OnlineGeminiService.cleanJsonResponse(rawWithFences);
      expect(cleaned, equals('{"action": "open_camera", "parameters": {}, "speechFeedback": "Opening camera."}'));

      final geminiResponse = jsonEncode({
        "candidates": [
          {
            "content": {
              "parts": [
                {"text": rawWithFences}
              ]
            }
          }
        ]
      });

      final overrides = MockHttpOverrides(statusCode: 200, responseBody: geminiResponse);
      await HttpOverrides.runWithHttpOverrides(() async {
        final service = OnlineGeminiService(apiKey: 'AIzaSyFakeKey123');
        final intent = await service.parseIntent(VoiceCommand.fromUtterance('take a picture'));

        expect(intent.actionName, equals('open_camera'));
        expect(intent.category, equals(IntentCategory.deviceControl));
      }, overrides);
    });

    test('Handles HTTP 400/403 invalid API key error', () async {
      final overrides = MockHttpOverrides(
        statusCode: 403,
        responseBody: '{"error": {"message": "API key not valid"}}',
      );
      await HttpOverrides.runWithHttpOverrides(() async {
        final service = OnlineGeminiService(apiKey: 'invalid_key');
        expect(
          () => service.parseIntent(VoiceCommand.fromUtterance('hello')),
          throwsA(isA<AIFailure>().having((e) => e.code, 'code', 'INVALID_API_KEY')),
        );
      }, overrides);
    });

    test('Handles HTTP 429 rate limit exceeded error', () async {
      final overrides = MockHttpOverrides(
        statusCode: 429,
        responseBody: '{"error": {"message": "Quota exceeded"}}',
      );
      await HttpOverrides.runWithHttpOverrides(() async {
        final service = OnlineGeminiService(apiKey: 'valid_key');
        expect(
          () => service.parseIntent(VoiceCommand.fromUtterance('hello')),
          throwsA(isA<AIFailure>().having((e) => e.code, 'code', 'RATE_LIMIT_EXCEEDED')),
        );
      }, overrides);
    });

    test('Handles network timeout as NetworkFailure', () async {
      final overrides = MockHttpOverrides(shouldTimeout: true);
      await HttpOverrides.runWithHttpOverrides(() async {
        final service = OnlineGeminiService(apiKey: 'valid_key');
        expect(
          () => service.parseIntent(VoiceCommand.fromUtterance('hello')),
          throwsA(isA<NetworkFailure>()),
        );
      }, overrides);
    });

    test('Handles SocketException as NetworkFailure', () async {
      final overrides = MockHttpOverrides(shouldThrowSocketException: true);
      await HttpOverrides.runWithHttpOverrides(() async {
        final service = OnlineGeminiService(apiKey: 'valid_key');
        expect(
          () => service.parseIntent(VoiceCommand.fromUtterance('hello')),
          throwsA(isA<NetworkFailure>()),
        );
      }, overrides);
    });

    test('Model selection updates request endpoint model ID', () async {
      final geminiResponse = jsonEncode({
        "candidates": [
          {
            "content": {
              "parts": [
                {"text": '{"action": "conversational_ai", "speechFeedback": "Deep reasoning complete."}'}
              ]
            }
          }
        ]
      });

      final overrides = MockHttpOverrides(statusCode: 200, responseBody: geminiResponse);
      await HttpOverrides.runWithHttpOverrides(() async {
        final service = OnlineGeminiService(apiKey: 'AIzaSyFakeKey123', modelId: 'gemini-1.5-flash');
        expect(service.modelId, equals('gemini-1.5-flash'));

        service.updateModelId('gemini-1.5-pro');
        expect(service.modelId, equals('gemini-1.5-pro'));

        await service.parseIntent(VoiceCommand.fromUtterance('solve this complex math problem'));
        expect(overrides.lastRequestedUri?.path, contains('gemini-1.5-pro'));
      }, overrides);
    });

    test('testConnection returns success on 200 and failure on error', () async {
      // 1. Missing key
      final unconfiguredService = OnlineGeminiService(apiKey: '');
      final result1 = await unconfiguredService.testConnection();
      expect(result1['success'], isFalse);

      // 2. Valid 200
      final okOverrides = MockHttpOverrides(
        statusCode: 200,
        responseBody: '{"candidates": [{"content": {"parts": [{"text": "Pong"}]}}]}',
      );
      await HttpOverrides.runWithHttpOverrides(() async {
        final service = OnlineGeminiService(apiKey: 'valid_key');
        final result = await service.testConnection();
        expect(result['success'], isTrue);
        expect(result['message'], contains('Connected successfully'));
      }, okOverrides);

      // 3. 403 Forbidden
      final errOverrides = MockHttpOverrides(statusCode: 403);
      await HttpOverrides.runWithHttpOverrides(() async {
        final service = OnlineGeminiService(apiKey: 'bad_key');
        final result = await service.testConnection();
        expect(result['success'], isFalse);
        expect(result['message'], contains('rejected'));
      }, errOverrides);
    });
  });

  group('AIRouter Online/Offline Arbitration Tests', () {
    test('Device offline forces offline engine fallback even with valid Gemini key', () async {
      final offlineService = OfflineAIService();
      final onlineService = OnlineGeminiService(apiKey: 'valid_key');
      final connectivity = DefaultConnectivityService();
      connectivity.setConnected(false);

      final router = AIRouter(
        offlineService: offlineService,
        onlineService: onlineService,
        connectivityService: connectivity,
        preferOfflineFirst: false,
      );

      final intent = await router.routeCommand(VoiceCommand.fromUtterance('turn on torch'));
      expect(intent.isOfflineCapable, isTrue);
      expect(intent.actionName, equals('toggle_torch'));
    });

    test('When online, network failure in Gemini falls back to offline engine gracefully', () async {
      final offlineService = OfflineAIService();
      final overrides = MockHttpOverrides(shouldTimeout: true);

      await HttpOverrides.runWithHttpOverrides(() async {
        final onlineService = OnlineGeminiService(apiKey: 'valid_key');
        final connectivity = DefaultConnectivityService();
        connectivity.setConnected(true);

        final router = AIRouter(
          offlineService: offlineService,
          onlineService: onlineService,
          connectivityService: connectivity,
          preferOfflineFirst: false,
        );

        final intent = await router.routeCommand(VoiceCommand.fromUtterance('turn on the flashlight'));
        expect(intent.actionName, equals('toggle_torch'));
        expect(intent.isOfflineCapable, isTrue);
      }, overrides);
    });
  });
}
