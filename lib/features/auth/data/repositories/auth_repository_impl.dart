import '../../../../core/storage/device_settings_storage.dart';
import '../../../../core/storage/secure_session_storage.dart' as core_session;
import '../../domain/entities/user_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

/// The legacy client falls back to a hardcoded UUID when the device has no
/// `settings.uuid` yet (`auth-service.ts`) — preserved here rather than
/// sending an empty `machine_ip`.
const _fallbackMachineIp = '01afaa68-f583-9816-2868-591032116435';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final core_session.SessionStorage _coreSessionStorage;
  final DeviceSettingsStorage _deviceSettingsStorage;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    required core_session.SessionStorage coreSessionStorage,
    required DeviceSettingsStorage deviceSettingsStorage,
  }) : _remote = remote,
       _local = local,
       _coreSessionStorage = coreSessionStorage,
       _deviceSettingsStorage = deviceSettingsStorage;

  @override
  Future<UserSession> login({
    required String userCode,
    required String userPassword,
  }) async {
    final settings = await _deviceSettingsStorage.read();

    final session = await _remote.login(
      userCode: userCode,
      userPassword: userPassword,
      branchNo: settings.branch,
      moduleCode: settings.moduleKey,
      machineIp: settings.uuid.isEmpty ? _fallbackMachineIp : settings.uuid,
    );

    await _local.save(session);
    await _coreSessionStorage.saveSessionKey(session.sessionKey);
    return session;
  }

  @override
  Future<void> logout() async {
    final session = await _local.read();
    if (session != null) {
      // Best-effort — the legacy app clears the local session regardless
      // of whether the server call succeeds.
      try {
        await _remote.logout(session.sessionKey);
      } catch (_) {
        // Ignored: local logout must still proceed.
      }
    }
    await _local.clear();
    await _coreSessionStorage.clear();
  }

  @override
  Future<UserSession?> currentSession() => _local.read();
}
