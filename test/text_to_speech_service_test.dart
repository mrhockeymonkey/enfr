import 'dart:convert';
import 'dart:typed_data';

import 'package:enfr/services/text_to_speech_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('synthesize', () {
    test('posts the text and returns the audio bytes', () async {
      late http.Request sent;
      final service = TextToSpeechService(
        client: MockClient((request) async {
          sent = request;
          return http.Response.bytes([1, 2, 3], 200);
        }),
      );

      final clip = await service.synthesize(
          text: 'Bonjour', apiKey: 'secret', voiceId: 'voice123');

      expect(clip, Uint8List.fromList([1, 2, 3]));
      expect(sent.method, 'POST');
      expect(sent.url.toString(),
          'https://api.elevenlabs.io/v1/text-to-speech/voice123?output_format=mp3_44100_128');
      expect(sent.headers['xi-api-key'], 'secret');
      expect(jsonDecode(sent.body), {
        'text': 'Bonjour',
        'model_id': 'eleven_multilingual_v2',
        'language_code': 'fr',
      });
    });

    test('throws with the API message on error', () async {
      final service = TextToSpeechService(
        client: MockClient((_) async => http.Response(
            jsonEncode({
              'detail': {
                'status': 'invalid_api_key',
                'message': 'Invalid API key'
              }
            }),
            401)),
      );

      expect(
        service.synthesize(text: 'Bonjour', apiKey: 'bad', voiceId: 'v'),
        throwsA(isA<TextToSpeechException>()
            .having((e) => e.message, 'message', 'Invalid API key')),
      );
    });

    test('falls back to the status code for a non-JSON error', () async {
      final service = TextToSpeechService(
        client: MockClient((_) async => http.Response('oops', 500)),
      );

      expect(
        service.synthesize(text: 'Bonjour', apiKey: 'k', voiceId: 'v'),
        throwsA(isA<TextToSpeechException>().having(
            (e) => e.message, 'message', 'ElevenLabs request failed (500)')),
      );
    });
  });

  test('listVoices parses the voices list', () async {
    late http.Request sent;
    final service = TextToSpeechService(
      client: MockClient((request) async {
        sent = request;
        return http.Response(
            jsonEncode({
              'voices': [
                {'voice_id': 'a', 'name': 'Alice', 'category': 'premade'},
                {'voice_id': 'b', 'name': 'Bob'},
              ]
            }),
            200);
      }),
    );

    final voices = await service.listVoices('secret');

    expect(sent.url.toString(), 'https://api.elevenlabs.io/v1/voices');
    expect(sent.headers['xi-api-key'], 'secret');
    expect([for (final v in voices) (v.id, v.name)],
        [('a', 'Alice'), ('b', 'Bob')]);
  });
}
