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

/// Runs at app launch to decide where to route the user, mirroring the
/// legacy app's own startup checks (device settings completeness, then
/// `AuthServiceProvider.hasLoggedIn()`).
class StartupValidator {
  final DeviceSettingsStorage _deviceSettingsStorage;
  final SessionStorage _sessionStorage;

  StartupValidator({
    required DeviceSettingsStorage deviceSettingsStorage,
    required SessionStorage sessionStorage,
  }) : _deviceSettingsStorage = deviceSettingsStorage,
       _sessionStorage = sessionStorage;

  Future<StartupResult> validate() async {
    final settings = await _deviceSettingsStorage.read();
    if (!settings.isComplete) {
      return const StartupResult(StartupStatus.needsDeviceSetup);
    }

    final sessionKey = await _sessionStorage.readSessionKey();
    if (sessionKey == null || sessionKey.isEmpty) {
      return const StartupResult(StartupStatus.needsLogin);
    }

    return StartupResult(StartupStatus.ready, sessionKey: sessionKey);
  }
}
