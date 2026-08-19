import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user_session_model.dart';

/// Persists the full session (user info, authorized actions) securely,
/// separately from `core/storage/secure_session_storage.dart`'s bare
/// session-key store — core only needs to know "is there a session" for
/// startup/router gating; the rich payload is this feature's concern.
abstract class AuthLocalDataSource {
  Future<UserSessionModel?> read();
  Future<void> save(UserSessionModel session);
  Future<void> clear();
}

class SecureAuthLocalDataSource implements AuthLocalDataSource {
  static const _sessionField = 'user_session';

  final FlutterSecureStorage _storage;

  SecureAuthLocalDataSource({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<UserSessionModel?> read() async {
    final raw = await _storage.read(key: _sessionField);
    if (raw == null) return null;
    return UserSessionModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(UserSessionModel session) async {
    await _storage.write(
      key: _sessionField,
      value: jsonEncode(session.toJson()),
    );
  }

  @override
  Future<void> clear() => _storage.delete(key: _sessionField);
}
