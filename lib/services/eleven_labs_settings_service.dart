import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ElevenLabsSettingsService {
  static const _keyKey = 'elevenlabs_api_key';
  static const _voiceKey = 'elevenlabs_voice';

  /// ElevenLabs' stock "George" voice, available on every account.
  static const defaultVoice = 'JBFqnCBsd6RMkjVDRZzb';

  static const _keyStorage = FlutterSecureStorage(
    webOptions: WebOptions(dbName: 'enfr', publicKey: _keyKey),
  );
  static const _voiceStorage = FlutterSecureStorage(
    webOptions: WebOptions(dbName: 'enfr', publicKey: _voiceKey),
  );

  static Future<String?> loadKey() => _keyStorage.read(key: _keyKey);
  static Future<void> saveKey(String key) =>
      _keyStorage.write(key: _keyKey, value: key);
  static Future<void> clearKey() => _keyStorage.delete(key: _keyKey);

  static Future<String> loadVoice() async =>
      await _voiceStorage.read(key: _voiceKey) ?? defaultVoice;
  static Future<void> saveVoice(String voiceId) =>
      _voiceStorage.write(key: _voiceKey, value: voiceId);
}
