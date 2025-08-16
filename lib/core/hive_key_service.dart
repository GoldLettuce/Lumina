import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HiveKeyService {
  static const _keyName = 'hive_aes_key_v1';

  static final FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: const AndroidOptions(encryptedSharedPreferences: true),
    iOptions: const IOSOptions(
      // No setear 'accessibility' para compatibilidad amplia
      synchronizable: false,
    ),
    mOptions: const MacOsOptions(
      // No setear 'accessibility' para compatibilidad amplia
    ),
  );

  static Future<List<int>> getOrCreateKey() async {
    final existing = await _storage.read(key: _keyName);
    if (existing != null) return base64Url.decode(existing);
    final key = Hive.generateSecureKey(); // 32 bytes (AES-256)
    await _storage.write(key: _keyName, value: base64UrlEncode(key));
    return key;
  }
}
