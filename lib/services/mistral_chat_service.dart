import 'dart:convert';

import 'package:http/http.dart' as http;

const _kChatUrl = 'https://api.mistral.ai/v1/chat/completions';

class MistralChatException implements Exception {
  MistralChatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// One chat message sent to Mistral.
class MistralMessage {
  const MistralMessage.system(this.content) : role = 'system';
  const MistralMessage.user(this.content) : role = 'user';

  final String role;
  final String content;

  Map<String, String> toJson() => {'role': role, 'content': content};
}

/// Thin client for Mistral's chat completions endpoint.
///
/// Replaces `mistralai_client_dart` for chat, whose generated models assume
/// `content` is always a string. Newer models (e.g. what
/// `mistral-large-latest` points to) can send it as a list of typed parts
/// (`text`, `thinking`, ...), which made the old client throw a type error.
class MistralChatService {
  MistralChatService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  /// Streams the reply as text fragments, in order.
  Stream<String> stream({
    required String apiKey,
    required String model,
    required List<MistralMessage> messages,
    double temperature = 0,
  }) async* {
    final request = http.Request('POST', Uri.parse(_kChatUrl))
      ..headers.addAll(_headers(apiKey, accept: 'text/event-stream'))
      ..body = jsonEncode(_body(model, messages, temperature, stream: true));
    final response = await _client.send(request);
    if (response.statusCode != 200) {
      throw _error(response.statusCode,
          (await http.Response.fromStream(response)).body);
    }

    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final line in lines) {
      if (!line.startsWith('data:')) continue;
      final data = line.substring(5).trim();
      if (data.isEmpty) continue;
      if (data == '[DONE]') break;
      final text = deltaText(jsonDecode(data));
      if (text.isNotEmpty) yield text;
    }
  }

  /// Returns the whole reply once it is complete.
  Future<String> complete({
    required String apiKey,
    required String model,
    required List<MistralMessage> messages,
    double temperature = 0,
  }) async {
    final response = await _client.post(
      Uri.parse(_kChatUrl),
      headers: _headers(apiKey, accept: 'application/json'),
      body: jsonEncode(_body(model, messages, temperature, stream: false)),
    );
    if (response.statusCode != 200) {
      throw _error(response.statusCode, response.body);
    }
    return messageText(jsonDecode(utf8.decode(response.bodyBytes)));
  }

  Map<String, String> _headers(String apiKey, {required String accept}) => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'Accept': accept,
      };

  Map<String, Object> _body(
    String model,
    List<MistralMessage> messages,
    double temperature, {
    required bool stream,
  }) =>
      {
        'model': model,
        'temperature': temperature,
        'stream': stream,
        'messages': [for (final m in messages) m.toJson()],
      };

  /// Prefers the API's own error message over the bare status code.
  MistralChatException _error(int status, String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map) {
        final message = json['message'] ?? json['detail'];
        if (message is String && message.isNotEmpty) {
          return MistralChatException(message);
        }
      }
    } catch (_) {
      // Not JSON; fall through to the status code.
    }
    return MistralChatException('Mistral request failed ($status)');
  }
}

/// Text of the first choice's `delta` in a streamed chunk.
String deltaText(Object? chunk) => _choiceText(chunk, 'delta');

/// Text of the first choice's `message` in a complete response.
String messageText(Object? response) => _choiceText(response, 'message');

String _choiceText(Object? json, String field) {
  if (json is! Map) return '';
  final choices = json['choices'];
  if (choices is! List || choices.isEmpty) return '';
  final choice = choices.first;
  if (choice is! Map) return '';
  final message = choice[field];
  if (message is! Map) return '';
  return contentText(message['content']);
}

/// Flattens a message `content` into plain text.
///
/// Mistral sends either a string or a list of typed parts. Only `text` parts
/// are kept; `thinking` (reasoning) and any other part types are dropped.
String contentText(Object? content) {
  if (content is String) return content;
  if (content is! List) return '';
  final buf = StringBuffer();
  for (final part in content) {
    if (part is String) {
      buf.write(part);
    } else if (part is Map && part['type'] == 'text') {
      final text = part['text'];
      if (text is String) buf.write(text);
    }
  }
  return buf.toString();
}
