import '../../../core/startup/startup_validator.dart';
import '../../../core/storage/secure_session_storage.dart' as core_session;
import 'datasources/auth_local_data_source.dart';

/// Startup's check that the persisted login is still usable. A session
/// saved without the login response's `MachineEnv.MachineNo` (every session
/// from before it was stored) is cleared, so the user has to log in again
/// and the next login stores it.
class AuthSessionValidity implements SessionValidity {
  final AuthLocalDataSource _local;
  final core_session.SessionStorage _coreSessionStorage;

  AuthSessionValidity({
    required AuthLocalDataSource local,
    required core_session.SessionStorage coreSessionStorage,
  }) : _local = local,
       _coreSessionStorage = coreSessionStorage;

  @override
  Future<bool> isSessionComplete() async {
    final session = await _local.read();
    if (session != null && session.isComplete) return true;
    await _local.clear();
    await _coreSessionStorage.clear();
    return false;
  }
}
