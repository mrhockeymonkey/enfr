import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiKeyService {
  static const _key = 'mistral_api_key';

  // Dev-only fallback, compiled in via `--dart-define-from-file=dev_keys.json`.
  // Empty in CI/production builds, which never pass the flag.
  static const _devKey = String.fromEnvironment('MISTRAL_API_KEY');
  static const _storage = FlutterSecureStorage(
    webOptions: WebOptions(dbName: 'enfr', publicKey: _key),
  );

  static Future<String?> loadKey() async {
    final stored = await _storage.read(key: _key);
    if (stored != null && stored.isNotEmpty) return stored;
    return _devKey.isEmpty ? null : _devKey;
  }

  static Future<void> saveKey(String key) => _storage.write(key: _key, value: key);
  static Future<void> clearKey() => _storage.delete(key: _key);
}
