import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

const _kBaseUrl = 'https://api.elevenlabs.io/v1';

/// Multilingual model, so French text is pronounced as French.
const _kModelId = 'eleven_multilingual_v2';

class Voice {
  const Voice(this.id, this.name, {this.publicOwnerId, this.accent});

  final String id;
  final String name;

  /// Set for a Voice Library voice that isn't in the account yet; it has to
  /// be added (see [TextToSpeechService.addSharedVoice]) before use.
  final String? publicOwnerId;

  /// The library's accent tag, e.g. for showing alongside the name.
  final String? accent;

  bool get isShared => publicOwnerId != null;
}

class TextToSpeechException implements Exception {
  TextToSpeechException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thin client for the ElevenLabs text-to-speech API.
class TextToSpeechService {
  TextToSpeechService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  /// Speaks [text] in French with [voiceId], returning the MP3 bytes.
  Future<Uint8List> synthesize({
    required String text,
    required String apiKey,
    required String voiceId,
  }) async {
    final response = await _client.post(
      Uri.parse('$_kBaseUrl/text-to-speech/$voiceId')
          .replace(queryParameters: {'output_format': 'mp3_44100_128'}),
      headers: {
        'xi-api-key': apiKey,
        'Content-Type': 'application/json',
        'Accept': 'audio/mpeg',
      },
      body: jsonEncode({
        'text': text,
        'model_id': _kModelId,
        'language_code': 'fr',
      }),
    );
    if (response.statusCode != 200) throw _error(response);
    return response.bodyBytes;
  }

  /// The voices available to the account behind [apiKey].
  Future<List<Voice>> listVoices(String apiKey) async {
    final response = await _client.get(
      Uri.parse('$_kBaseUrl/voices'),
      headers: {'xi-api-key': apiKey},
    );
    if (response.statusCode != 200) throw _error(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return [
      for (final v in json['voices'] as List<dynamic>)
        Voice(v['voice_id'] as String, v['name'] as String),
    ];
  }

  /// French Canadian (Québec) voices from the ElevenLabs Voice Library.
  Future<List<Voice>> listQuebecVoices(String apiKey) async {
    final response = await _client.get(
      Uri.parse('$_kBaseUrl/shared-voices').replace(queryParameters: {
        'language': 'fr',
        'locale': 'fr-CA',
        'page_size': '100',
      }),
      headers: {'xi-api-key': apiKey},
    );
    if (response.statusCode != 200) throw _error(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return [
      for (final v in json['voices'] as List<dynamic>)
        Voice(
          v['voice_id'] as String,
          v['name'] as String,
          publicOwnerId: v['public_owner_id'] as String,
          accent: v['accent'] as String?,
        ),
    ];
  }

  /// Adds a Voice Library voice to the account so text-to-speech can use it,
  /// returning the voice id to use from now on.
  Future<String> addSharedVoice(String apiKey, Voice voice) async {
    final response = await _client.post(
      Uri.parse('$_kBaseUrl/voices/add/${voice.publicOwnerId}/${voice.id}'),
      headers: {'xi-api-key': apiKey, 'Content-Type': 'application/json'},
      body: jsonEncode({'new_name': voice.name}),
    );
    if (response.statusCode != 200) throw _error(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['voice_id'] as String;
  }

  /// Builds an exception from an error response, preferring the API's own
  /// message (`{"detail": {"message": ...}}`) over the bare status code.
  TextToSpeechException _error(http.Response response) {
    try {
      final detail =
          (jsonDecode(response.body) as Map<String, dynamic>)['detail'];
      final message = detail is Map ? detail['message'] : detail;
      if (message is String && message.isNotEmpty) {
        return TextToSpeechException(message);
      }
    } catch (_) {
      // Not JSON; fall through to the status code.
    }
    return TextToSpeechException(
        'ElevenLabs request failed (${response.statusCode})');
  }
}
