import 'dart:convert';

import 'package:enfr/models/journal_entry.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class JournalService {
  static const _key = 'journal_entries';
  static const _storage = FlutterSecureStorage(
    webOptions: WebOptions(dbName: 'enfr', publicKey: _key),
  );

  static Future<List<JournalEntry>> loadEntries() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveEntries(List<JournalEntry> entries) =>
      _storage.write(
        key: _key,
        value: jsonEncode(entries.map((e) => e.toJson()).toList()),
      );
}
