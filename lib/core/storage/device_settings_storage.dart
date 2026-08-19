import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/device_settings.dart';

/// Persists [DeviceSettings] (branch/module/endpoint/device config — not
/// secret) locally, mirroring the legacy app's `@ionic/storage`-backed
/// `SettingsProvider`.
abstract class DeviceSettingsStorage {
  Future<DeviceSettings> read();
  Future<void> save(DeviceSettings settings);
  Future<void> clear();
}

class SharedPreferencesDeviceSettingsStorage implements DeviceSettingsStorage {
  static const _key = 'device_settings';

  final SharedPreferencesAsync _preferences;

  SharedPreferencesDeviceSettingsStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  @override
  Future<DeviceSettings> read() async {
    final raw = await _preferences.getString(_key);
    if (raw == null) return const DeviceSettings();
    return DeviceSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(DeviceSettings settings) async {
    await _preferences.setString(_key, jsonEncode(settings.toJson()));
  }

  @override
  Future<void> clear() async {
    await _preferences.remove(_key);
  }
}
