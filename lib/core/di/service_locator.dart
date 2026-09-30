import 'package:cookie_jar/cookie_jar.dart';
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

/// [cookieDirectory] persists the server session cookies across restarts, so
/// a restored login keeps its Sale Engine session; in memory when null.
void setupCoreServiceLocator({String? cookieDirectory}) {
  sl.registerLazySingleton<AppLogger>(() => const DeveloperLogAppLogger());
  sl.registerLazySingleton<ApiClient>(
    () => DioApiClient(
      cookieJar: cookieDirectory == null
          ? CookieJar()
          : PersistCookieJar(
              // `ASP.NET_SessionId` is a session cookie (no expiry).
              persistSession: true,
              storage: FileStorage(cookieDirectory),
            ),
    ),
  );
  sl.registerLazySingleton<DeviceSettingsStorage>(
    () => SharedPreferencesDeviceSettingsStorage(),
  );
  sl.registerLazySingleton<SessionStorage>(() => SecureSessionStorage());
  // Built on first use, after the features have registered — so the auth
  // feature's [SessionValidity], when present, is picked up.
  sl.registerLazySingleton<StartupValidator>(
    () => StartupValidator(
      deviceSettingsStorage: sl(),
      sessionStorage: sl(),
      sessionValidity: sl.isRegistered<SessionValidity>()
          ? sl<SessionValidity>()
          : null,
    ),
  );
}
