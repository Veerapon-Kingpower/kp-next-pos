import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/di/service_locator.dart';
import 'package:kp_pos/core/logging/app_logger.dart';
import 'package:kp_pos/core/network/api_client.dart';

void main() {
  tearDown(() async {
    if (sl.isRegistered<AppLogger>() || sl.isRegistered<ApiClient>()) {
      await sl.reset();
    }
  });

  test('registers core dependencies as resolvable singletons', () {
    setupCoreServiceLocator();

    expect(sl<AppLogger>(), isA<AppLogger>());
    expect(sl<ApiClient>(), isA<ApiClient>());
    expect(sl<AppLogger>(), same(sl<AppLogger>()));
  });
}
