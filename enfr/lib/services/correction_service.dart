import 'package:enfr/constants/prompts.dart';
import 'package:enfr/models/correction.dart';
import 'package:enfr/services/api_key_service.dart';
import 'package:enfr/services/correction_parser.dart';
import 'package:mistralai_client_dart/mistralai_client_dart.dart';

class MissingApiKeyException implements Exception {
  const MissingApiKeyException();
}

class CorrectionService {
  static const String _model = 'mistral-small-latest';

  static Future<List<Correction>> checkEntry(
    String content, {
    List<Correction> previous = const [],
  }) async {
    final key = await ApiKeyService.loadKey();
    if (key == null || key.isEmpty) {
      throw const MissingApiKeyException();
    }

    final prompt = kCorrectionPrompt
        .replaceFirst(kCorrectionPromptEntryPlaceholder, content)
        .replaceFirst(
          kCorrectionPromptPreviousPlaceholder,
          _renderPrevious(previous),
        );

    final client = MistralAIClient(apiKey: key);
    final response = await client.chatComplete(
      request: ChatCompletionRequest(
        model: _model,
        temperature: 0.2,
        messages: [
          UserMessage(content: UserMessageContent.string(prompt)),
        ],
      ),
    );

    final choices = response.choices;
    if (choices == null || choices.isEmpty) return const [];
    final messageContent = choices.first.message.content;
    if (messageContent == null) return const [];

    final raw = messageContent.maybeWhen(
      string: (s) => s,
      orElse: () => '',
    );

    return parseCorrections(raw);
  }

  static String _renderPrevious(List<Correction> previous) {
    if (previous.isEmpty) return 'None';
    final buf = StringBuffer();
    for (final c in previous) {
      buf
        ..write('- ')
        ..write(c.status.name)
        ..write(': <text>')
        ..write(c.originalText)
        ..write('</text> -> <correction>')
        ..write(c.suggestedText)
        ..writeln('</correction>');
    }
    return buf.toString().trimRight();
  }
}
