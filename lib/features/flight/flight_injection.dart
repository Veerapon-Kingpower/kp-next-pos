import '../../core/di/service_locator.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/device_settings_storage.dart';
import 'data/datasources/flight_remote_data_source.dart';
import 'data/repositories/flight_repository_impl.dart';
import 'domain/repositories/flight_repository.dart';
import 'domain/usecases/get_date_by_flight_usecase.dart';
import 'domain/usecases/get_flight_by_code_usecase.dart';
import 'domain/usecases/validate_flight_usecase.dart';

void setupFlightServiceLocator() {
  sl.registerLazySingleton<FlightRemoteDataSource>(
    () => FlightRemoteDataSource(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<FlightRepository>(
    () => FlightRepositoryImpl(
      remote: sl<FlightRemoteDataSource>(),
      deviceSettingsStorage: sl<DeviceSettingsStorage>(),
    ),
  );
  sl.registerFactory<GetFlightByCodeUseCase>(
    () => GetFlightByCodeUseCase(sl<FlightRepository>()),
  );
  sl.registerFactory<GetDateByFlightUseCase>(
    () => GetDateByFlightUseCase(sl<FlightRepository>()),
  );
  sl.registerFactory<ValidateFlightUseCase>(
    () => ValidateFlightUseCase(sl<FlightRepository>()),
  );
}
