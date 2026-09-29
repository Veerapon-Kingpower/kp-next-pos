import '../../core/di/service_locator.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/device_settings_storage.dart';
import '../../core/startup/startup_validator.dart';
import '../../core/storage/secure_session_storage.dart';
import 'data/auth_session_validity.dart';
import 'data/datasources/auth_local_data_source.dart';
import 'data/datasources/auth_remote_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/logout_usecase.dart';
import 'domain/usecases/restore_session_usecase.dart';
import 'presentation/login_view_model.dart';

void setupAuthServiceLocator() {
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => SecureAuthLocalDataSource(),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remote: sl<AuthRemoteDataSource>(),
      local: sl<AuthLocalDataSource>(),
      coreSessionStorage: sl<SessionStorage>(),
      deviceSettingsStorage: sl<DeviceSettingsStorage>(),
    ),
  );
  sl.registerLazySingleton<SessionValidity>(
    () => AuthSessionValidity(
      local: sl<AuthLocalDataSource>(),
      coreSessionStorage: sl<SessionStorage>(),
    ),
  );
  sl.registerFactory<LoginUseCase>(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerFactory<LogoutUseCase>(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerFactory<RestoreSessionUseCase>(
    () => RestoreSessionUseCase(sl<AuthRepository>()),
  );
  sl.registerFactory<LoginViewModel>(
    () => LoginViewModel(loginUseCase: sl<LoginUseCase>()),
  );
}
