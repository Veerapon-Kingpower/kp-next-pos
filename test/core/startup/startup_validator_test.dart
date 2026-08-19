import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/config/device_settings.dart';
import 'package:kp_pos/core/startup/startup_validator.dart';
import 'package:kp_pos/core/storage/device_settings_storage.dart';
import 'package:kp_pos/core/storage/secure_session_storage.dart';

class _FakeDeviceSettingsStorage implements DeviceSettingsStorage {
  DeviceSettings _settings;

  _FakeDeviceSettingsStorage(this._settings);

  @override
  Future<DeviceSettings> read() async => _settings;

  @override
  Future<void> save(DeviceSettings settings) async => _settings = settings;

  @override
  Future<void> clear() async => _settings = const DeviceSettings();
}

class _FakeSessionStorage implements SessionStorage {
  String? _sessionKey;

  _FakeSessionStorage([this._sessionKey]);

  @override
  Future<String?> readSessionKey() async => _sessionKey;

  @override
  Future<void> saveSessionKey(String sessionKey) async =>
      _sessionKey = sessionKey;

  @override
  Future<void> clear() async => _sessionKey = null;
}

const _completeSettings = DeviceSettings(
  saleEngineEndpoint: 'https://sale',
  webServiceEndpoint: 'https://register',
  flightApi: 'https://flight',
);

void main() {
  test('routes to device setup when settings are incomplete', () async {
    final validator = StartupValidator(
      deviceSettingsStorage: _FakeDeviceSettingsStorage(const DeviceSettings()),
      sessionStorage: _FakeSessionStorage(),
    );

    final result = await validator.validate();

    expect(result.status, StartupStatus.needsDeviceSetup);
  });

  test(
    'routes to login when settings are complete but no session is stored',
    () async {
      final validator = StartupValidator(
        deviceSettingsStorage: _FakeDeviceSettingsStorage(_completeSettings),
        sessionStorage: _FakeSessionStorage(),
      );

      final result = await validator.validate();

      expect(result.status, StartupStatus.needsLogin);
    },
  );

  test(
    'routes straight to ready when settings are complete and a session exists',
    () async {
      final validator = StartupValidator(
        deviceSettingsStorage: _FakeDeviceSettingsStorage(_completeSettings),
        sessionStorage: _FakeSessionStorage('abc123'),
      );

      final result = await validator.validate();

      expect(result.status, StartupStatus.ready);
      expect(result.sessionKey, 'abc123');
    },
  );
}
