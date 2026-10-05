import 'package:enfr/constants/prompts.dart';
import 'package:enfr/data/prompt_repository.dart';
import 'package:enfr/models/correction.dart';
import 'package:enfr/services/api_key_service.dart';
import 'package:enfr/services/correction_parser.dart';
import 'package:enfr/services/model_preference_service.dart';
import 'package:mistralai_dart/mistralai_dart.dart';

class MissingApiKeyException implements Exception {
  const MissingApiKeyException();
}

class CorrectionService {
  static Future<List<Correction>> checkEntry(
    String content, {
    List<Correction> previous = const [],
  }) async {
    final key = await ApiKeyService.loadKey();
    if (key == null || key.isEmpty) {
      throw const MissingApiKeyException();
    }
    final model = await ModelPreferenceService.loadModel();

    final prompt = PromptRepository.correctionPrompt
        .replaceFirst(kCorrectionPromptEntryPlaceholder, content)
        .replaceFirst(
          kCorrectionPromptPreviousPlaceholder,
          _renderPrevious(previous),
        );

    final client = MistralClient.withApiKey(key);
    try {
      final response = await client.chat.create(
        request: ChatCompletionRequest(
          model: model,
          temperature: 0,
          messages: [ChatMessage.user(prompt)],
        ),
      );
      final raw = response.text;
      if (raw == null) return const [];
      return parseCorrections(raw);
    } finally {
      client.close();
    }
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
