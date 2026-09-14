import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiKeyService {
  static const _key = 'mistral_api_key';
  static const _storage = FlutterSecureStorage(
    webOptions: WebOptions(dbName: 'enfr', publicKey: _key),
  );

  static Future<String?> loadKey() => _storage.read(key: _key);
  static Future<void> saveKey(String key) => _storage.write(key: _key, value: key);
  static Future<void> clearKey() => _storage.delete(key: _key);
}
