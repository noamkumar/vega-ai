import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:vega_ai/core/errors/failures.dart';
import 'package:vega_ai/core/models/command_intent.dart';
import 'package:vega_ai/core/models/voice_command.dart';
import 'package:vega_ai/core/utils/logger.dart';
import 'package:vega_ai/services/ai/ai_service.dart';

/// Online AI service connecting to Google's Gemini API for advanced reasoning,
/// complex natural language conversation, and structured action calling.
class OnlineGeminiService implements AIService {
  static const _logger = VegaLogger('OnlineGeminiService');

  /// Curated list of Google Gemini models optimized for voice assistants.
  static const List<String> supportedModels = [
    'gemini-1.5-flash',
    'gemini-1.5-pro',
    'gemini-2.0-flash',
  ];

  String? _apiKey;
  String _modelId;
  final HttpClient _httpClient;

  OnlineGeminiService({
    String? apiKey,
    String modelId = 'gemini-1.5-flash',
    HttpClient? httpClient,
  })  : _apiKey = (apiKey != null && apiKey.isNotEmpty)
            ? apiKey
            : const String.fromEnvironment('GEMINI_API_KEY', defaultValue: ''),
        _modelId = modelId,
        _httpClient = httpClient ?? HttpClient();

  @override
  String get engineName => 'Gemini-$_modelId-Cloud';

  @override
  bool get isOffline => false;

  bool get hasValidApiKey => _apiKey != null && _apiKey!.trim().isNotEmpty;

  void updateApiKey(String key) {
    _apiKey = key.trim();
  }

  void updateModelId(String model) {
    _modelId = model.trim();
  }

  String get modelId => _modelId;

  /// Strips markdown code fences (e.g. ```json ... ```) from LLM output.
  static String cleanJsonResponse(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      final firstNewline = text.indexOf('\n');
      if (firstNewline != -1) {
        text = text.substring(firstNewline + 1);
      }
      if (text.endsWith('```')) {
        text = text.substring(0, text.length - 3);
      }
    }
    return text.trim();
  }

  /// Verifies connectivity and credentials with Google Gemini servers.
  Future<Map<String, dynamic>> testConnection() async {
    if (!hasValidApiKey) {
      return {
        'success': false,
        'message': 'Gemini API key is not configured. Please enter a valid key.',
      };
    }

    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_modelId:generateContent?key=$_apiKey',
      );

      final requestBody = {
        "contents": [
          {
            "role": "user",
            "parts": [
              {"text": "Ping"}
            ]
          }
        ],
        "generationConfig": {
          "maxOutputTokens": 5,
        }
      };

      final request = await _httpClient.postUrl(uri).timeout(const Duration(seconds: 10));
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.write(jsonEncode(requestBody));

      final response = await request.close().timeout(const Duration(seconds: 10));
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Connected successfully to Google Gemini ($_modelId).',
          'model': _modelId,
        };
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Gemini API key rejected (HTTP ${response.statusCode}). Please verify your key.',
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 429) {
        return {
          'success': false,
          'message': 'Rate limit / quota exceeded (HTTP 429). Please check your Google AI Studio quota.',
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'message': 'Gemini returned HTTP ${response.statusCode}: $responseBody',
          'statusCode': response.statusCode,
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Connection timed out while reaching Gemini servers.',
      };
    } on SocketException catch (e) {
      return {
        'success': false,
        'message': 'Network socket error: $e. Check your internet connection.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection test failed: $e',
      };
    }
  }

  @override
  Future<CommandIntent> parseIntent(VoiceCommand command) async {
    if (!hasValidApiKey) {
      _logger.warning('Gemini API key is not configured');
      throw const AIFailure(
        'Gemini API key is missing. Please configure it in Settings.',
        code: 'MISSING_API_KEY',
        isOfflineModel: false,
      );
    }

    final query = command.transcript.trim();
    _logger.info('Sending command to Gemini for cloud reasoning: "$query"');

    final systemInstruction = '''
You are VEGA, an advanced JARVIS-inspired Android voice assistant.
Evaluate the user's voice command and respond strictly in valid JSON format.

Recognized actions:
- toggle_torch: parameters {"state": true/false}
- get_battery_level: parameters {}
- launch_app: parameters {"appName": "Spotify" / "YouTube" / "Chrome" / "WhatsApp" / etc., "packageName": "optional"}
- open_camera: parameters {}
- open_settings: parameters {"type": "wifi" / "bluetooth" / "sound" / "display" / "general"}
- set_volume: parameters {"mode": "increase" / "decrease" / "mute" / "unmute", "level": optional int 0-15}
- get_volume: parameters {}
- play_music: parameters {"query": "song/artist name", "app": "spotify" / "youtube" / "default"}
- control_media: parameters {"action": "play" / "pause" / "next" / "previous"}
- set_timer: parameters {"seconds": int, "message": "string"}
- set_alarm: parameters {"hour": int, "minute": int, "message": "string"}
- conversational_ai: for questions, calculations, explanations, and casual conversation.

Output JSON format (no markdown blocks, pure JSON):
{
  "thought": "brief reasoning",
  "action": "action_id",
  "parameters": {},
  "speechFeedback": "short, elegant JARVIS-inspired spoken response"
}
''';

    final requestBody = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": query}
          ]
        }
      ],
      "systemInstruction": {
        "parts": [
          {"text": systemInstruction}
        ]
      },
      "generationConfig": {
        "temperature": 0.2,
        "maxOutputTokens": 300,
        "responseMimeType": "application/json"
      }
    };

    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_modelId:generateContent?key=$_apiKey',
      );

      final request = await _httpClient.postUrl(uri).timeout(const Duration(seconds: 12));
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.write(jsonEncode(requestBody));

      final response = await request.close().timeout(const Duration(seconds: 12));
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>?;
        final candidate = (candidates != null && candidates.isNotEmpty)
            ? candidates.first as Map<String, dynamic>?
            : null;
        final parts = candidate?['content']?['parts'] as List<dynamic>?;
        final part = (parts != null && parts.isNotEmpty)
            ? parts.first as Map<String, dynamic>?
            : null;
        final rawText = part?['text'] as String?;

        if (rawText != null && rawText.isNotEmpty) {
          try {
            final cleaned = cleanJsonResponse(rawText);
            final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
            final action = parsed['action'] as String? ?? 'conversational_ai';
            final params = parsed['parameters'] as Map<String, dynamic>? ?? {};
            final feedback = parsed['speechFeedback'] as String? ?? 'Understood, sir.';

            // Store pre-generated speech in parameters for instant generateResponse
            params['_speechFeedback'] = feedback;
            params['query'] = query;

            IntentCategory category;
            switch (action) {
              case 'toggle_torch':
              case 'open_camera':
              case 'set_volume':
              case 'control_media':
              case 'play_music':
              case 'set_timer':
              case 'set_alarm':
                category = IntentCategory.deviceControl;
                break;
              case 'launch_app':
                category = IntentCategory.appLaunch;
                break;
              case 'get_battery_level':
              case 'get_volume':
              case 'open_settings':
                category = IntentCategory.offlineQuery;
                break;
              default:
                category = IntentCategory.conversationalAI;
            }

            return CommandIntent(
              id: 'gemini_${DateTime.now().millisecondsSinceEpoch}',
              category: category,
              actionName: action,
              parameters: params,
              confidence: 0.98,
              isOfflineCapable: false,
            );
          } catch (e) {
            _logger.warning('Failed to parse Gemini structured JSON: $rawText ($e)');
          }
        }

        // Fallback plain conversational intent
        return CommandIntent(
          id: 'gemini_fallback_${DateTime.now().millisecondsSinceEpoch}',
          category: IntentCategory.conversationalAI,
          actionName: 'conversational_ai',
          parameters: {
            '_speechFeedback': 'I have processed your request, sir.',
            'query': query,
          },
          confidence: 0.90,
          isOfflineCapable: false,
        );
      } else if (response.statusCode == 429) {
        _logger.warning('Gemini API rate limit exceeded (HTTP 429)');
        throw const AIFailure(
          'Gemini rate limit exceeded. Please wait a moment or use offline mode.',
          code: 'RATE_LIMIT_EXCEEDED',
          isOfflineModel: false,
        );
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        _logger.warning('Gemini authentication failed (HTTP ${response.statusCode})');
        throw AIFailure(
          'Gemini API key is invalid or unauthorized (HTTP ${response.statusCode}).',
          code: 'INVALID_API_KEY',
          isOfflineModel: false,
        );
      } else {
        _logger.error('Gemini API HTTP error ${response.statusCode}: $responseBody');
        throw AIFailure(
          'Gemini service returned HTTP ${response.statusCode}.',
          code: 'SERVER_ERROR',
          isOfflineModel: false,
        );
      }
    } on TimeoutException catch (e) {
      _logger.warning('Timeout connecting to Gemini: $e');
      throw const NetworkFailure(
        'Gemini request timed out. Please check your internet connection.',
      );
    } on SocketException catch (e) {
      _logger.warning('Network socket failure connecting to Gemini: $e');
      throw const NetworkFailure(
        'Unable to reach Gemini servers. Please check your internet connection.',
      );
    } on HandshakeException catch (e) {
      _logger.warning('TLS handshake failure: $e');
      throw const NetworkFailure(
        'Secure connection to Gemini failed. Network security verification error.',
      );
    } catch (e) {
      if (e is Failure) rethrow;
      _logger.error('Unexpected error calling Gemini API: $e');
      throw AIFailure(
        'Cloud reasoning error: $e',
        code: 'UNKNOWN_ERROR',
        isOfflineModel: false,
      );
    }
  }

  @override
  Future<String> generateResponse(CommandIntent intent, {String? conversationContext}) async {
    // If we already synthesized speech during structured intent extraction, use it instantly!
    final cached = intent.parameters['_speechFeedback'] as String?;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    if (!hasValidApiKey) {
      return 'Online AI requires a Gemini API key. Configure it in Settings or switch to Offline mode.';
    }

    final query = intent.parameters['query']?.toString() ??
        intent.parameters['originalTranscript']?.toString() ??
        'status report';

    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_modelId:generateContent?key=$_apiKey',
      );

      final requestBody = {
        "contents": [
          {
            "role": "user",
            "parts": [
              {"text": query}
            ]
          }
        ],
        "systemInstruction": {
          "parts": [
            {
              "text":
                  "You are VEGA, an elegant JARVIS-inspired voice assistant. Respond concisely in 1-2 spoken sentences."
            }
          ]
        },
        "generationConfig": {
          "temperature": 0.4,
          "maxOutputTokens": 100,
        }
      };

      final request = await _httpClient.postUrl(uri).timeout(const Duration(seconds: 8));
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.write(jsonEncode(requestBody));

      final response = await request.close().timeout(const Duration(seconds: 8));
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>?;
        final candidate = (candidates != null && candidates.isNotEmpty)
            ? candidates.first as Map<String, dynamic>?
            : null;
        final parts = candidate?['content']?['parts'] as List<dynamic>?;
        final part = (parts != null && parts.isNotEmpty)
            ? parts.first as Map<String, dynamic>?
            : null;
        final text = part?['text'] as String?;
        if (text != null && text.trim().isNotEmpty) {
          return text.trim();
        }
      }
    } catch (e) {
      _logger.warning('Failed to generate open conversational response from Gemini: $e');
    }

    return 'According to Gemini Intelligence, I have processed "$query". All systems operational.';
  }

  @override
  Future<void> dispose() async {
    _httpClient.close(force: true);
    _logger.info('Gemini service disposed');
  }
}

