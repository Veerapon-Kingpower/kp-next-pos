import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the login session key securely (see design.md's "secure local
/// storage" decision). The legacy app stored `session_key` in
/// `@ionic/storage`, which is not encrypted at rest — this is a deliberate
/// hardening, not a like-for-like port.
abstract class SessionStorage {
  Future<String?> readSessionKey();
  Future<void> saveSessionKey(String sessionKey);
  Future<void> clear();
}

class SecureSessionStorage implements SessionStorage {
  static const _sessionKeyField = 'session_key';

  final FlutterSecureStorage _storage;

  SecureSessionStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> readSessionKey() => _storage.read(key: _sessionKeyField);

  @override
  Future<void> saveSessionKey(String sessionKey) =>
      _storage.write(key: _sessionKeyField, value: sessionKey);

  @override
  Future<void> clear() => _storage.delete(key: _sessionKeyField);
}
