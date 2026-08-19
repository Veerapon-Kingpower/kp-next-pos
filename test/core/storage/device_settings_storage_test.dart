import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/config/device_settings.dart';
import 'package:kp_pos/core/storage/device_settings_storage.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late SharedPreferencesDeviceSettingsStorage storage;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    storage = SharedPreferencesDeviceSettingsStorage();
  });

  test(
    'reads default (incomplete) settings when nothing has been saved',
    () async {
      final settings = await storage.read();
      expect(settings.isComplete, isFalse);
    },
  );

  test('persists and reads back saved settings', () async {
    const settings = DeviceSettings(
      branch: '03',
      saleEngineEndpoint: 'https://sale',
      webServiceEndpoint: 'https://register',
      flightApi: 'https://flight',
    );

    await storage.save(settings);
    final read = await storage.read();

    expect(read.branch, '03');
    expect(read.isComplete, isTrue);
  });

  test('clear removes saved settings', () async {
    const settings = DeviceSettings(
      saleEngineEndpoint: 'https://sale',
      webServiceEndpoint: 'https://register',
      flightApi: 'https://flight',
    );
    await storage.save(settings);

    await storage.clear();
    final read = await storage.read();

    expect(read.isComplete, isFalse);
  });
}
