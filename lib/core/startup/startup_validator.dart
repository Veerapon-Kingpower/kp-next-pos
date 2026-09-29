import '../config/device_settings.dart';
import '../storage/device_settings_storage.dart';
import '../storage/secure_session_storage.dart';

enum StartupStatus {
  /// Device settings are incomplete — route to first-time device setup
  /// before anything else, matching the legacy Settings-page gate.
  needsDeviceSetup,

  /// Device is configured but no valid session was persisted — route to
  /// login.
  needsLogin,

  /// Device is configured and a session was restored — route to the app
  /// shell directly.
  ready,
}

class StartupResult {
  final StartupStatus status;
  final String? sessionKey;

  const StartupResult(this.status, {this.sessionKey});
}

/// Whether the persisted session holds everything the app needs — owned by
/// the auth feature, which clears an incomplete one (e.g. a session saved
/// before the login's `MachineEnv.MachineNo` was stored) so the user logs
/// in again.
abstract class SessionValidity {
  Future<bool> isSessionComplete();
}

/// Runs at app launch to decide where to route the user, mirroring the
/// legacy app's own startup checks (device settings completeness, then
/// `AuthServiceProvider.hasLoggedIn()`).
class StartupValidator {
  final DeviceSettingsStorage _deviceSettingsStorage;
  final SessionStorage _sessionStorage;
  final SessionValidity? _sessionValidity;

  StartupValidator({
    required DeviceSettingsStorage deviceSettingsStorage,
    required SessionStorage sessionStorage,
    SessionValidity? sessionValidity,
  }) : _deviceSettingsStorage = deviceSettingsStorage,
       _sessionStorage = sessionStorage,
       _sessionValidity = sessionValidity;

  /// Current device settings from local storage — no network call.
  Future<DeviceSettings> readDeviceSettings() => _deviceSettingsStorage.read();

  Future<StartupResult> validate() async {
    final settings = await _deviceSettingsStorage.read();
    if (!settings.isComplete) {
      return const StartupResult(StartupStatus.needsDeviceSetup);
    }

    final sessionKey = await _sessionStorage.readSessionKey();
    if (sessionKey == null || sessionKey.isEmpty) {
      return const StartupResult(StartupStatus.needsLogin);
    }
    final validity = _sessionValidity;
    if (validity != null && !await validity.isSessionComplete()) {
      return const StartupResult(StartupStatus.needsLogin);
    }

    return StartupResult(StartupStatus.ready, sessionKey: sessionKey);
  }
}
