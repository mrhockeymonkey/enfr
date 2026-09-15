import 'package:flutter/services.dart';

class PromptRepository {
  static bool _isInitialized = false;

  static late final String correctionPrompt;
  static late final String translatePrompt;
  static late final String translateToEnglishPrompt;
  static late final String explainPrompt;

  static Future<void> initAsync() async {
    if (_isInitialized) return;

    correctionPrompt =
        await rootBundle.loadString('assets/prompts/correction.md');
    translatePrompt =
        await rootBundle.loadString('assets/prompts/translate.md');
    translateToEnglishPrompt = await rootBundle
        .loadString('assets/prompts/translate_to_english.md');
    explainPrompt = await rootBundle.loadString('assets/prompts/explain.md');

    _isInitialized = true;
  }
}
