import 'dart:convert';

import 'package:enfr/models/verb_quiz_settings.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class VerbQuizSettingsService {
  static const _key = 'verb_quiz_settings';
  static const _storage = FlutterSecureStorage(
    webOptions: WebOptions(dbName: 'enfr', publicKey: _key),
  );

  static Future<VerbQuizSettings> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return VerbQuizSettings.defaults;
    try {
      return VerbQuizSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return VerbQuizSettings.defaults;
    }
  }

  static Future<void> save(VerbQuizSettings settings) =>
      _storage.write(key: _key, value: jsonEncode(settings.toJson()));
}
