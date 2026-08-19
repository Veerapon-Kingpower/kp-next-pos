import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/config/device_settings.dart';

void main() {
  test('default settings are incomplete (empty endpoints)', () {
    expect(const DeviceSettings().isComplete, isFalse);
  });

  test(
    'isComplete requires saleEngineEndpoint, webServiceEndpoint, and flightApi (matches legacy gate)',
    () {
      const base = DeviceSettings(
        saleEngineEndpoint: 'https://a',
        webServiceEndpoint: 'https://b',
        flightApi: 'https://c',
      );
      expect(base.isComplete, isTrue);
      expect(base.copyWith(flightApi: '').isComplete, isFalse);
      expect(base.copyWith(webServiceEndpoint: '').isComplete, isFalse);
      expect(base.copyWith(saleEngineEndpoint: '').isComplete, isFalse);
    },
  );

  test('round-trips through JSON', () {
    const settings = DeviceSettings(
      moduleKey: 'MposKpi',
      branch: '03',
      subBranchCode: 'CPX-DT',
      machine: 1,
      saleEngineEndpoint: 'https://sale',
      webServiceEndpoint: 'https://register',
      flightApi: 'https://flight',
      isAirportMpos: true,
    );

    final restored = DeviceSettings.fromJson(settings.toJson());

    expect(restored.moduleKey, settings.moduleKey);
    expect(restored.branch, settings.branch);
    expect(restored.subBranchCode, settings.subBranchCode);
    expect(restored.machine, settings.machine);
    expect(restored.saleEngineEndpoint, settings.saleEngineEndpoint);
    expect(restored.webServiceEndpoint, settings.webServiceEndpoint);
    expect(restored.flightApi, settings.flightApi);
    expect(restored.isAirportMpos, settings.isAirportMpos);
  });
}
