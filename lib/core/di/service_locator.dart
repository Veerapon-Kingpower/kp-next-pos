import 'package:get_it/get_it.dart';

import '../logging/app_logger.dart';
import '../network/api_client.dart';
import '../startup/startup_validator.dart';
import '../storage/device_settings_storage.dart';
import '../storage/secure_session_storage.dart';

/// Service locator boundary shared across features. Core dependencies are
/// registered here at startup; each feature registers its own
/// domain/data/presentation dependencies in its own `*_injection.dart` as
/// that feature is implemented, calling into this same [sl] instance.
final GetIt sl = GetIt.instance;

void setupCoreServiceLocator() {
  sl.registerLazySingleton<AppLogger>(() => const DeveloperLogAppLogger());
  sl.registerLazySingleton<ApiClient>(() => DioApiClient());
  sl.registerLazySingleton<DeviceSettingsStorage>(
    () => SharedPreferencesDeviceSettingsStorage(),
  );
  sl.registerLazySingleton<SessionStorage>(() => SecureSessionStorage());
  sl.registerLazySingleton<StartupValidator>(
    () => StartupValidator(deviceSettingsStorage: sl(), sessionStorage: sl()),
  );
}
