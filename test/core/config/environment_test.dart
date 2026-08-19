import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/config/environment.dart';

void main() {
  test('defaults to development when no ENV define is provided', () {
    expect(EnvironmentConfig.current.environment, AppEnvironment.development);
    expect(EnvironmentConfig.current, EnvironmentConfig.development);
  });

  test('every named environment defines all six service endpoints', () {
    for (final config in [
      EnvironmentConfig.development,
      EnvironmentConfig.uat,
      EnvironmentConfig.production,
    ]) {
      expect(config.saleEngineEndpoint, isNotEmpty);
      expect(config.webServiceEndpoint, isNotEmpty);
      expect(config.flightApi, isNotEmpty);
      expect(config.printHubEndpoint, isNotEmpty);
      expect(config.memberApi, isNotEmpty);
      expect(config.cashCardApi, isNotEmpty);
    }
  });

  test(
    'development mirrors uat endpoints (no separate dev backend exists)',
    () {
      expect(
        EnvironmentConfig.development.saleEngineEndpoint,
        EnvironmentConfig.uat.saleEngineEndpoint,
      );
    },
  );
}
