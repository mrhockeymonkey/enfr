import 'package:enfr/constants/voices.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ElevenLabsSettingsService {
  static const _keyKey = 'elevenlabs_api_key';
  static const _voiceKey = 'elevenlabs_voice';

  static final defaultVoice = kVoices.first.id;

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

  /// The saved voice, or the default if none is saved or the saved one is
  /// no longer in [kVoices].
  static Future<String> loadVoice() async {
    final saved = await _voiceStorage.read(key: _voiceKey);
    return kVoices.any((v) => v.id == saved) ? saved! : defaultVoice;
  }

  static Future<void> saveVoice(String voiceId) =>
      _voiceStorage.write(key: _voiceKey, value: voiceId);
}
