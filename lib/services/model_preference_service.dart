import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ModelPreferenceService {
  static const _key = 'mistral_model';
  static const defaultModel = 'mistral-small-latest';
  static const _storage = FlutterSecureStorage(
    webOptions: WebOptions(dbName: 'enfr', publicKey: _key),
  );

  static Future<String> loadModel() async =>
      await _storage.read(key: _key) ?? defaultModel;
  static Future<void> saveModel(String model) =>
      _storage.write(key: _key, value: model);
}
