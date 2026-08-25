import '../../core/di/service_locator.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/device_settings_storage.dart';
import 'data/datasources/settings_remote_data_source.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'domain/repositories/settings_repository.dart';
import 'domain/usecases/list_sub_branches_usecase.dart';
import 'domain/usecases/load_device_settings_usecase.dart';
import 'domain/usecases/save_device_settings_usecase.dart';
import 'presentation/settings_view_model.dart';

void setupSettingsServiceLocator() {
  sl.registerLazySingleton<SettingsRemoteDataSource>(
    () => SettingsRemoteDataSource(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(
      remote: sl<SettingsRemoteDataSource>(),
      deviceSettingsStorage: sl<DeviceSettingsStorage>(),
    ),
  );
  sl.registerFactory<LoadDeviceSettingsUseCase>(
    () => LoadDeviceSettingsUseCase(sl<SettingsRepository>()),
  );
  sl.registerFactory<SaveDeviceSettingsUseCase>(
    () => SaveDeviceSettingsUseCase(sl<SettingsRepository>()),
  );
  sl.registerFactory<ListSubBranchesUseCase>(
    () => ListSubBranchesUseCase(sl<SettingsRepository>()),
  );
  sl.registerFactory<SettingsViewModel>(
    () => SettingsViewModel(
      loadDeviceSettings: sl<LoadDeviceSettingsUseCase>(),
      saveDeviceSettings: sl<SaveDeviceSettingsUseCase>(),
      listSubBranches: sl<ListSubBranchesUseCase>(),
    ),
  );
}
