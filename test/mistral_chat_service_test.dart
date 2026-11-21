import 'dart:convert';

import 'package:enfr/services/mistral_chat_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _sse(List<Object> chunks) =>
    '${chunks.map((c) => 'data: ${jsonEncode(c)}\n\n').join()}data: [DONE]\n\n';

Map<String, Object> _chunk(Object? content) => {
      'id': 'x',
      'model': 'm',
      'choices': [
        {
          'index': 0,
          'delta': {'role': 'assistant', 'content': content},
        }
      ],
    };

void main() {
  group('contentText', () {
    test('passes strings through', () {
      expect(contentText('Bonjour'), 'Bonjour');
    });

    test('joins text parts and drops thinking parts', () {
      expect(
        contentText([
          {
            'type': 'thinking',
            'thinking': [
              {'type': 'text', 'text': 'hmm'}
            ],
          },
          {'type': 'text', 'text': 'Bon'},
          {'type': 'text', 'text': 'jour'},
        ]),
        'Bonjour',
      );
    });

    test('treats null and unknown shapes as empty', () {
      expect(contentText(null), '');
      expect(contentText(42), '');
    });
  });

  group('stream', () {
    test('yields text from both string and list deltas', () async {
      late http.BaseRequest sent;
      final service = MistralChatService(
        client: MockClient.streaming((request, body) async {
          sent = request;
          return http.StreamedResponse(
            Stream.value(utf8.encode(_sse([
              _chunk(''),
              _chunk('Hel'),
              _chunk([
                {'type': 'thinking', 'thinking': []},
                {'type': 'text', 'text': 'lo'},
              ]),
              _chunk(null),
            ]))),
            200,
          );
        }),
      );

      final parts = await service.stream(
        apiKey: 'secret',
        model: 'mistral-large-latest',
        messages: const [MistralMessage.user('hi')],
      ).toList();

      expect(parts, ['Hel', 'lo']);
      expect(sent.headers['Authorization'], 'Bearer secret');
    });

    test('throws with the API message on error', () async {
      final service = MistralChatService(
        client: MockClient(
            (_) async => http.Response(jsonEncode({'message': 'Unauthorized'}), 401)),
      );

      expect(
        service.stream(
            apiKey: 'bad',
            model: 'm',
            messages: const [MistralMessage.user('hi')]).toList(),
        throwsA(isA<MistralChatException>()
            .having((e) => e.message, 'message', 'Unauthorized')),
      );
    });
  });

  group('complete', () {
    test('sends the request and returns list-shaped content as text', () async {
      late http.Request sent;
      final service = MistralChatService(
        client: MockClient((request) async {
          sent = request;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'index': 0,
                  'message': {
                    'role': 'assistant',
                    'content': [
                      {'type': 'text', 'text': 'Ça va'}
                    ],
                  },
                  'finish_reason': 'stop',
                }
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final reply = await service.complete(
        apiKey: 'secret',
        model: 'mistral-large-latest',
        messages: const [
          MistralMessage.system('sys'),
          MistralMessage.user('hi'),
        ],
      );

      expect(reply, 'Ça va');
      expect(sent.url.toString(), 'https://api.mistral.ai/v1/chat/completions');
      expect(jsonDecode(sent.body), {
        'model': 'mistral-large-latest',
        'temperature': 0,
        'stream': false,
        'messages': [
          {'role': 'system', 'content': 'sys'},
          {'role': 'user', 'content': 'hi'},
        ],
      });
    });
  });
}
