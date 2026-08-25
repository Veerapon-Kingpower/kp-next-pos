import '../../core/di/service_locator.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/device_settings_storage.dart';
import 'data/datasources/nationality_remote_data_source.dart';
import 'data/repositories/mock_nationality_repository.dart';
import 'data/repositories/nationality_repository_impl.dart';
import 'domain/repositories/nationality_repository.dart';
import 'domain/usecases/list_nationalities_usecase.dart';

/// Demo/dev switch: serves canned data from [MockNationalityRepository]
/// instead of the real `Register/GetNationality` backend, so the Register
/// form's Nationality field can be exercised without a reachable environment
/// configured. Flip to `false` (and drop the mock repository) once a real
/// backend is wired up for this environment.
const kUseMockNationalityData = true;

void setupNationalityServiceLocator() {
  sl.registerLazySingleton<NationalityRemoteDataSource>(
    () => NationalityRemoteDataSource(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<NationalityRepository>(
    () => kUseMockNationalityData
        ? MockNationalityRepository()
        : NationalityRepositoryImpl(
            remote: sl<NationalityRemoteDataSource>(),
            deviceSettingsStorage: sl<DeviceSettingsStorage>(),
          ),
  );
  sl.registerFactory<ListNationalitiesUseCase>(
    () => ListNationalitiesUseCase(sl<NationalityRepository>()),
  );
}
