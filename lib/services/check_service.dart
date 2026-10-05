import 'package:enfr/constants/prompts.dart';
import 'package:enfr/data/prompt_repository.dart';
import 'package:enfr/models/check_response.dart';
import 'package:enfr/services/api_key_service.dart';
import 'package:enfr/services/correction_service.dart';
import 'package:enfr/services/model_preference_service.dart';
import 'package:mistralai_dart/mistralai_dart.dart';

class CheckService {
  /// Asks the model to check [input] and returns its reply as it streams in.
  static Future<CheckReply> check(String input) async {
    final key = await ApiKeyService.loadKey();
    if (key == null || key.isEmpty) {
      throw const MissingApiKeyException();
    }
    final model = await ModelPreferenceService.loadModel();

    final prompt = PromptRepository.checkPrompt
        .replaceFirst(kTranslatePromptInputPlaceholder, input);

    return CheckReply.fromJsonChunks(_stream(key, model, prompt));
  }

  static Stream<String> _stream(String key, String model, String prompt) async* {
    final client = MistralClient.withApiKey(key);
    try {
      final stream = client.chat.createStream(
        request: ChatCompletionRequest(
          model: model,
          temperature: 0,
          messages: [ChatMessage.user(prompt)],
          responseFormat: ResponseFormatJsonSchema(
            name: 'french_feedback',
            schema: checkResponseSchema,
            strict: true,
          ),
        ),
      );
      await for (final chunk in stream) {
        final text = chunk.text;
        if (text != null) yield text;
      }
    } finally {
      client.close();
    }
  }
}
