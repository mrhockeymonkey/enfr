import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

const _kBaseUrl = 'https://api.elevenlabs.io/v1';

/// Multilingual model, so French text is pronounced as French.
const _kModelId = 'eleven_multilingual_v2';

class Voice {
  const Voice(this.id, this.name);

  final String id;
  final String name;
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
