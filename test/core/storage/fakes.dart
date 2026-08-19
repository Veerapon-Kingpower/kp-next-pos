import 'package:kp_pos/core/config/device_settings.dart';
import 'package:kp_pos/core/storage/device_settings_storage.dart';
import 'package:kp_pos/core/storage/secure_session_storage.dart';

/// Shared in-memory test doubles for the core storage interfaces, reused
/// across every feature test that needs a working device-settings/session
/// gate without real platform storage.
class FakeDeviceSettingsStorage implements DeviceSettingsStorage {
  DeviceSettings _settings;
  FakeDeviceSettingsStorage([this._settings = const DeviceSettings()]);

  @override
  Future<DeviceSettings> read() async => _settings;
  @override
  Future<void> save(DeviceSettings settings) async => _settings = settings;
  @override
  Future<void> clear() async => _settings = const DeviceSettings();
}

class FakeSessionStorage implements SessionStorage {
  String? _sessionKey;
  FakeSessionStorage([this._sessionKey]);

  @override
  Future<String?> readSessionKey() async => _sessionKey;
  @override
  Future<void> saveSessionKey(String sessionKey) async =>
      _sessionKey = sessionKey;
  @override
  Future<void> clear() async => _sessionKey = null;
}
